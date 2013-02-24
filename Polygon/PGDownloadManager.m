//
//  DownloadManager.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "PGDownloadManager.h"
#import "PGModel+Management.h"
#import "NSString+UUID.h"
#import "NSData+MD5Hash.h"
#import "ZipHelper.h"

@interface PGDownloadManager ()

@property (nonatomic, strong) NSMutableDictionary *currentDownloads;
@property (nonatomic, strong) NSMutableDictionary *sharableLinks;
@property (nonatomic, strong) NSMutableDictionary *waitingSubItems;
@property (nonatomic, strong) NSMutableDictionary *errorDownloads;

@end

@implementation PGDownloadManager

+ (PGDownloadManager *)sharedInstance
{
    static PGDownloadManager *_downloadManager = nil;
	if (_downloadManager == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _downloadManager = [PGDownloadManager.alloc init];
            [_downloadManager _addObservings];
        });
	}
    return _downloadManager;
}


- (DBRestClient *)restClient
{
    if (!_restClient) {
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

- (NSMutableDictionary *)sharableLinks
{
    if (_sharableLinks == nil) {
        _sharableLinks = [NSMutableDictionary dictionary];
    }
    return _sharableLinks;
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


- (void)_addObservings
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(importEmailAttachment:) name:FileOpenFromEmailNotification object:nil];
}


- (BOOL)isCompressedFile:(NSString *)filePath
{
    NSString *extension = [filePath.lastPathComponent.pathExtension lowercaseString];
    if ([extension isEqualToString:@"zip"]
        || [extension isEqualToString:@"rar"]) {
        return YES;
    }
    return NO;
}


- (void)importEmailAttachment:(NSNotification *)notification
{
    NSString *filePath = [notification.userInfo[@"fileURL"] path];
    if ([PGModel modelTypeForFileName:filePath.lastPathComponent] != ModelTypeUnknown) {
        [self importModelFileFromPath:filePath];
    } else if ([self isCompressedFile:filePath]) {
        [self handleZIPFileImport:filePath];
    } else {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error) NSLog(@"Error deleting unknown file: %@", error.localizedDescription);
    }
}


- (void)handleZIPFileImport:(NSString *)filePath
{
    NSArray *fileList = [ZipHelper listFilesInZipFile:filePath];
    if (fileList.count == 1) {
        // TODO: directly unzip that file and try import
        [[NSNotificationCenter defaultCenter] postNotificationName:CompressedFileContainsMultipleItemsNotification object:nil userInfo:@{@"fileList": fileList, @"filePath": filePath}];
    } else {
        // Present dialog to pick files to unzip
        [[NSNotificationCenter defaultCenter] postNotificationName:CompressedFileContainsMultipleItemsNotification object:nil userInfo:@{@"fileList": fileList, @"filePath": filePath}];
    }
    
}

- (PGModel *)importModelFileFromPath:(NSString *)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *directoryPath = [DOCUMENTS_DIR stringByAppendingPathComponent:[NSString getUUID]];
    [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:NO attributes:nil error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        return nil;
    }
    NSString *destinationPath = [directoryPath stringByAppendingPathComponent:filePath.lastPathComponent];
    if ([fileManager moveItemAtPath:filePath toPath:destinationPath error:&error]) {
        [self addSkipBackupAttributeToItemAtFilePath:destinationPath];
    }
    NSString *md5Hash = [NSData md5HashForFile:destinationPath];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:destinationPath error:&error];
    NSArray *components = destinationPath.pathComponents;
    NSString *relativePath = [[components[components.count - 3] stringByAppendingPathComponent:components[components.count - 2]] stringByAppendingPathComponent:components.lastObject];
    NSDictionary *objectDetails = @{@"modelName": relativePath.lastPathComponent,
                                    @"md5"      : md5Hash,
                                    @"modelSize": fileAttributes[NSFileSize],
                                    @"filePath" : relativePath,
                                    @"dateAdded": [NSNumber numberWithUnsignedLongLong:(unsigned long long)[NSDate.date timeIntervalSince1970]]};
    return [[PGModel MR_importFromArray:@[objectDetails]] lastObject];
}

- (PGModel *)downloadFile:(DBMetadata *)metadata
{
    PGModel *model = [PGModel findFirstByAttribute:@"pGModelID" withValue:metadata.rev];
    if (model.isDownloaded) {
        self.sharableLinks[metadata.path] = model;
        [self.restClient loadSharableLinkForFile:metadata.path shortUrl:YES];
        return model;
    }
    NSError *error;
    NSString *directoryPath = [@"tmp" stringByAppendingPathComponent:[NSString getUUID]];
    [NSFileManager.defaultManager createDirectoryAtPath:[HOME_DIR stringByAppendingPathComponent:directoryPath] withIntermediateDirectories:NO attributes:nil error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
        return nil;
    }
    NSString *relativePath = [directoryPath stringByAppendingPathComponent:metadata.filename];
    NSDictionary *objectDetails = @{
    @"metadata" : metadata,
    @"filePath" : relativePath,
    @"dateAdded": [NSNumber numberWithUnsignedLongLong:(unsigned long long)[NSDate.date timeIntervalSince1970]]};
    PGModel *newModel = [[PGModel MR_importFromArray:@[objectDetails]] lastObject];
    self.sharableLinks[metadata.path] = newModel;
    [self.restClient loadSharableLinkForFile:metadata.path shortUrl:YES];
    if (!newModel.isDownloaded) {
        NSString *destinationPath = [HOME_DIR stringByAppendingPathComponent:relativePath];
        NSAssert(newModel, @"Failed importing model based on dictionary");
        self.currentDownloads[destinationPath] = newModel;
        [self.restClient loadFile:metadata.path intoPath:destinationPath];
    }
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
    for (DBMetadata* child in metadatas) {
        if (child.isDirectory) {
            NSError *error;
            [NSFileManager.defaultManager createDirectoryAtPath:[model.enclosingFolder stringByAppendingPathComponent:child.filename] withIntermediateDirectories:NO attributes:nil error:&error];
            [self.waitingSubItems setValue:[model.enclosingFolder stringByAppendingPathComponent:child.filename] forKey:child.path];
            [self.restClient loadMetadata:child.path];
        } else {
            [self.restClient loadFile:child.path intoPath:[model.enclosingFolder stringByAppendingPathComponent:child.filename]];
        }
    }  
}


- (void)downloadDirectoryAndSubDirectories:(DBMetadata *)directoryMetadata toDirectory:(NSString *)localDirectory
{
    for (DBMetadata* child in directoryMetadata.contents) {
        if (child.isDirectory) {
            NSError *error;
            [NSFileManager.defaultManager createDirectoryAtPath:[localDirectory stringByAppendingPathComponent:child.filename] withIntermediateDirectories:NO attributes:nil error:&error];
            [self.waitingSubItems setValue:[localDirectory stringByAppendingPathComponent:child.filename] forKey:child.path];
            [self.restClient loadMetadata:child.path];
        } else {
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
    if (metadata.isDirectory) {
        if ([self.delegate respondsToSelector:@selector(downloadManager:didLoadDirectoryContents:)]) {
            [self.delegate downloadManager:self didLoadDirectoryContents:metadata.contents];
        }
    }
}


- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(downloadManager:failedLoadingDirectoryContents:)]) {
        [self.delegate downloadManager:self failedLoadingDirectoryContents:error];
    }
}


#pragma mark Download callbacks
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath contentType:(NSString*)contentType metadata:(DBMetadata*)metadata
{
    PGModel *modelDownloaded = self.currentDownloads[destPath];
    if (modelDownloaded) {
        [self.currentDownloads removeObjectForKey:destPath];
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSString *newRelativePath = [self moveToDocumentsAndAvoidBackup:destPath];
            NSDictionary *objectDetails = @{@"metadata" : metadata, @"filePath" : newRelativePath};
            [PGModel importFromArray:@[objectDetails] inContext:localContext];
        } completion:^(BOOL success, NSError *error) {
            NSAssert([NSThread isMainThread], @"Import callback on main thread");
            [NSNotificationCenter.defaultCenter postNotificationName:DropboxFileDownloadedNotification object:nil userInfo:@{@"metadata" : metadata}];
            if ([self.progressDelegate respondsToSelector:@selector(downloadManager:finishedDownloadingModel:)]) {
                [self.progressDelegate downloadManager:self finishedDownloadingModel:modelDownloaded];
            }
            NSArray *subItemsToDownload = self.waitingSubItems[modelDownloaded.enclosingFolder.lastPathComponent];
            if (subItemsToDownload) [self downloadFilesAndDirectories:subItemsToDownload forModel:modelDownloaded];
        }];
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
        if (!self.errorDownloads[sourcePath]) {
            // try an extra time to download the file
            [self.errorDownloads setValue:destinationPath forKey:sourcePath];
            [self.restClient loadFile:sourcePath intoPath:destinationPath];
        } else {
            // one additional attempt has been done already
            [self.errorDownloads removeObjectForKey:sourcePath];
        }
    }
    else if ([self.progressDelegate respondsToSelector:@selector(downloadManager:failedDownloadingModel:)]) {
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

#pragma mark Thumbnails
- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath metadata:(DBMetadata*)metadata
{
    if ([self.delegate respondsToSelector:@selector(downloadManager:didLoadThumbnail:)]) {
        [self.delegate downloadManager:self didLoadThumbnail:metadata];
    }
}


#pragma mark Sharable Links
- (void)restClient:(DBRestClient *)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path
{
    PGModel *model = self.sharableLinks[path];
    model.globalURL = link;
    [self.sharableLinks removeObjectForKey:path];
}

- (void)restClient:(DBRestClient *)restClient loadSharableLinkFailedWithError:(NSError *)error
{
    NSLog(@"Error loading sharable link: %@", [error localizedDescription]);
}

- (NSString *)moveToDocumentsAndAvoidBackup:(NSString *)filePath
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSError *error;
    NSString *relativePath = @"Documents";
    if ([fileManager fileExistsAtPath:filePath]) {
        NSArray *components = filePath.pathComponents;
        if (components.count > 1) relativePath = [@"Documents" stringByAppendingPathComponent:components[components.count - 2]];
        NSString *enclosingDirectory = filePath.stringByDeletingLastPathComponent;
        
        if ([fileManager moveItemAtPath:enclosingDirectory toPath:[HOME_DIR stringByAppendingPathComponent:relativePath] error:&error]) {
            [self addSkipBackupAttributeToItemAtFilePath:[HOME_DIR stringByAppendingPathComponent:relativePath]];
        } else {
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
