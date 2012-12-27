//
//  DownloadManager.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "DownloadManager.h"
#import "PGModel+Management.h"
#import "NSString+UUID.h"

@interface DownloadManager ()

@property (nonatomic, strong) NSMutableDictionary *currentDownloads;
@property (nonatomic, strong) NSMutableDictionary *waitingSubItems;
@property (nonatomic, strong) NSMutableDictionary *errorDownloads;

@end

@implementation DownloadManager

+ (DownloadManager *)sharedInstance
{
    static DownloadManager *_downloadManager = nil;
	if (_downloadManager == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _downloadManager = [DownloadManager.alloc init];
        });
	}
    return _downloadManager;
}


- (DBRestClient *)restClient
{
    if (!_restClient)
    {
        _restClient = [DBRestClient.alloc initWithSession:DBSession.sharedSession];
        _restClient.delegate = self;
    }
    return _restClient;
}


- (NSMutableDictionary *)currentDownloads
{
    if (_currentDownloads == nil) {
        _currentDownloads = [NSMutableDictionary dictionary];
    }
    return _currentDownloads;
}

- (NSMutableDictionary *)waitingSubItems
{
    if (_waitingSubItems == nil) {
        _waitingSubItems = [NSMutableDictionary dictionary];
    }
    return _waitingSubItems;
}

- (NSMutableDictionary *)errorDownloads
{
    if (_errorDownloads == nil) {
        _errorDownloads = [NSMutableDictionary dictionary];
    }
    return _errorDownloads;
}


- (PGModel *)downloadFile:(DBMetadata *)metadata
{
    NSString *uniqueID = [NSString getUUID];
    NSError *error;
    NSString *directoryPath = [@"tmp" stringByAppendingPathComponent:uniqueID];
    [NSFileManager.defaultManager createDirectoryAtPath:[HOME_DIR stringByAppendingPathComponent:directoryPath]
                            withIntermediateDirectories:NO attributes:nil error:&error];
    if (error)
    {
        NSLog(@"Error: %@", error.localizedDescription);
        return nil;
    }
    NSString *relativePath = [directoryPath stringByAppendingPathComponent:metadata.filename];
    NSDictionary *objectDetails = @{
    @"metadata" : metadata,
    @"filePath" : relativePath,
    @"dateAdded": [NSNumber numberWithUnsignedLongLong:(unsigned long long)[NSDate.date timeIntervalSince1970]]};
    PGModel *newModel = [PGModel MR_importFromObject:objectDetails];
    NSString *destinationPath = [HOME_DIR stringByAppendingPathComponent:relativePath];
    NSAssert(newModel, @"Failed importing model based on dictionary");
    [self.currentDownloads setValue:newModel forKey:destinationPath];
    [self.restClient loadFile:metadata.path intoPath:destinationPath];
    
    return newModel;
}

- (PGModel *)downloadFilesAndDirectories:(NSArray *)metadatas rootFile:(DBMetadata *)rootMetadata
{
    PGModel *model = [self downloadFile:rootMetadata];
    if (!model) return nil;
    NSMutableArray *mutableMetadata = metadatas.mutableCopy;
    [mutableMetadata removeObject:rootMetadata];
    NSString *uniqueFolderName = model.enclosingFolder.lastPathComponent;
    [self.waitingSubItems setValue:mutableMetadata forKey:uniqueFolderName];

    return model;
}


- (void)downloadFilesAndDirectories:(NSArray *)metadatas forModel:(PGModel *)model
{
    for (DBMetadata* child in metadatas)
    {
        if (child.isDirectory)
        {
            NSError *error;
            [NSFileManager.defaultManager createDirectoryAtPath:[model.enclosingFolder stringByAppendingPathComponent:child.filename] withIntermediateDirectories:NO attributes:nil error:&error];
            [self.waitingSubItems setValue:[model.enclosingFolder stringByAppendingPathComponent:child.filename] forKey:child.path];
            [self.restClient loadMetadata:child.path];
        }
        else
        {
            [self.restClient loadFile:child.path intoPath:[model.enclosingFolder stringByAppendingPathComponent:child.filename]];
        }
    }  
}


- (void)downloadDirectoryAndSubDirectories:(DBMetadata *)directoryMetadata toDirectory:(NSString *)localDirectory
{
    for (DBMetadata* child in directoryMetadata.contents)
    {
        if (child.isDirectory)
        {
            NSError *error;
            [NSFileManager.defaultManager createDirectoryAtPath:[localDirectory stringByAppendingPathComponent:child.filename] withIntermediateDirectories:NO attributes:nil error:&error];
            [self.waitingSubItems setValue:[localDirectory stringByAppendingPathComponent:child.filename] forKey:child.path];
            [self.restClient loadMetadata:child.path];
        }
        else
        {
            [self.restClient loadFile:child.path intoPath:[localDirectory stringByAppendingPathComponent:child.filename]];
        }
    }
}

#pragma mark - Dropbox Delegate methods
#pragma mark Load directory contents

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    if (self.waitingSubItems[metadata.path]) {
        [self downloadDirectoryAndSubDirectories:metadata toDirectory:self.waitingSubItems[metadata.path]];
        return;
    }
    
    if (metadata.isDirectory)
    {
        if ([self.delegate respondsToSelector:@selector(downloadManager:didLoadDirectoryContents:)])
        {
            [self.delegate downloadManager:self didLoadDirectoryContents:metadata.contents];
        }
    }
}


- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(downloadManager:failedLoadingDirectoryContents:)])
    {
        [self.delegate downloadManager:self failedLoadingDirectoryContents:error];
    }
}


#pragma mark Download callbacks
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata
{
    PGModel *modelDownloaded = self.currentDownloads[destPath];
    if (modelDownloaded)
    {
    [self.currentDownloads removeObjectForKey:destPath];
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        NSString *newRelativePath = [self moveToDocumentsAndAvoidBackup:destPath];
        NSDictionary *objectDetails = @{
        @"metadata" : metadata,
        @"filePath" : newRelativePath};
        [PGModel importFromObject:objectDetails inContext:localContext];
    } completion:^{
        [NSNotificationCenter.defaultCenter postNotificationName:DropboxFileDownloadedNotification object:nil userInfo:@{@"metadata" : metadata}];
        if ([self.progressDelegate respondsToSelector:@selector(downloadManager:finishedDownloadingModel:)]) {
            [self.progressDelegate downloadManager:self finishedDownloadingModel:modelDownloaded];
        }
        NSArray *subItemsToDownload = self.waitingSubItems[modelDownloaded.enclosingFolder.lastPathComponent];
        if (subItemsToDownload) {
            [self downloadFilesAndDirectories:subItemsToDownload forModel:modelDownloaded];
        }
    }];
    }
    else
    {
        //NSLog(@"Subitem downloaded to: %@", destPath);
    }
}


- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    //TODO: find the failed download file and remove from [self.currentDownloads removeObjectForKey:destPath];
    NSString *destinationPath = error.userInfo[@"destinationPath"];
    NSString *sourcePath = error.userInfo[@"path"];
    if (destinationPath
        && sourcePath)
    {
        if (!self.errorDownloads[sourcePath])
        {
            // try an extra time to download the file
            [self.errorDownloads setValue:destinationPath forKey:sourcePath];
            [self.restClient loadFile:sourcePath intoPath:destinationPath];
        }
        else
        {
            // one additional attempt has been done already
            [self.errorDownloads removeObjectForKey:sourcePath];
        }
    }
    else if ([self.progressDelegate respondsToSelector:@selector(downloadManager:failedDownloadingModel:)])
    {
        [self.progressDelegate downloadManager:self failedDownloadingModel:nil];
        [NSNotificationCenter.defaultCenter postNotificationName:DropboxFailedDownloadNotification object:nil userInfo:@{@"error" : error}];
    }
}


- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    NSAssert([NSThread isMainThread], @"Download progress not called on Main Thread");
    if ([self.progressDelegate respondsToSelector:@selector(downloadManager:loadProgress:forModel:)])
        [self.progressDelegate downloadManager:self loadProgress:progress forModel:self.currentDownloads[destPath]];
}


- (NSString *)moveToDocumentsAndAvoidBackup:(NSString *)filePath
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSError *error;
    NSString *relativePath = @"Documents";
    if ([fileManager fileExistsAtPath:filePath])
    {
        NSArray *components = filePath.pathComponents;
        if (components.count > 1) relativePath = [@"Documents" stringByAppendingPathComponent:components[components.count - 2]];
        NSString *enclosingDirectory = filePath.stringByDeletingLastPathComponent;
        
        if ([fileManager moveItemAtPath:enclosingDirectory toPath:[HOME_DIR stringByAppendingPathComponent:relativePath] error:&error])
        {
            [self addSkipBackupAttributeToItemAtFilePath:[HOME_DIR stringByAppendingPathComponent:relativePath]];
        }
        else
        {
            NSLog(@"Error moving file to doc-dir: %@, error %@", filePath, error);
        }
    }
    return [relativePath stringByAppendingPathComponent:filePath.lastPathComponent];
}

#pragma mark - Skip Back-Up Attribute
- (BOOL)addSkipBackupAttributeToItemAtFilePath:(NSString *)filePath
{
    NSURL *URL = [NSURL fileURLWithPath:filePath];
    assert([NSFileManager.defaultManager fileExistsAtPath:URL.path]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES] forKey: NSURLIsExcludedFromBackupKey error:&error];
     if(!success) NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);

    return success;
}

@end
