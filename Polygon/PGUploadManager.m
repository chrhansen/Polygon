//
//  PGUploadManager.m
//  Polygon
//
//  Created by Christian Hansen on 22/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "PGUploadManager.h"
#import "PGModel+Management.h"

typedef void(^DropboxFolderCreated)(NSError *error);
typedef void(^DropboxFileUploaded)(NSError *error);

@interface PGUploadManager ()

@property (nonatomic, copy) DropboxFolderCreated dropboxFolderCreatedBlock;
@property (nonatomic, copy) DropboxFolderCreated dropboxFileUploadedBlock;
@property (nonatomic, strong) NSMutableDictionary *currentUploads;

@end

#define UPLOAD_ERROR_DOMAIN @"it.calcul8.polygon.uploadmanager"

@implementation PGUploadManager

+ (PGUploadManager *)sharedInstance
{
    static PGUploadManager *_uploadManager = nil;
	if (_uploadManager == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _uploadManager = [PGUploadManager.alloc init];
//            [_uploadManager _addObservings];
        });
	}
    return _uploadManager;
}

- (DBRestClient *)restClient
{
    if (!_restClient) {
        _restClient = [DBRestClient.alloc initWithSession:DBSession.sharedSession];
        _restClient.delegate = self;
    }
    return _restClient;
}

- (NSMutableDictionary *)currentUploads
{
    if (_currentUploads == nil) {
        _currentUploads = [NSMutableDictionary dictionary];
    }
    return _currentUploads;
}


- (void)createDropboxFolder:(NSString *)folderName atPath:(NSString *)dropboxPath completion:(void (^)(NSError *error))completion
{
    [self setDropboxFolderCreatedBlock:^(NSError *error) {
        completion(error);
    }];
    [self.restClient createFolder:[dropboxPath stringByAppendingPathComponent:folderName]];
}

- (void)uploadModel:(PGModel *)model toPath:(NSString *)dropboxPath progressDelegate:(id<UploadManagerProgressDelegate>)progressDelegate completion:(void (^)(NSError *error))completion;
{
    NSError *error;
    if (!model)       error = [NSError errorWithDomain:UPLOAD_ERROR_DOMAIN code:-100 userInfo:@{@"error": NSLocalizedString(@"No model selected for upload", nil)}];
    if (!dropboxPath) error = [NSError errorWithDomain:UPLOAD_ERROR_DOMAIN code:-100 userInfo:@{@"error": NSLocalizedString(@"No filepath selected for upload", nil)}];
    
    if (error) {
        completion(error);
        return;
    }
    [self setDropboxFileUploadedBlock:^(NSError *error) {
        completion(error);
    }];
    self.progressDelegate = progressDelegate;
    self.currentUploads[model.fullModelFilePath] = model;
    [self.restClient uploadFile:model.modelName toPath:dropboxPath withParentRev:nil fromPath:model.fullModelFilePath];
}


#pragma mark - DBRestClientDelegate
#pragma mark Create Folder
- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
    if (self.dropboxFolderCreatedBlock) {
        self.dropboxFolderCreatedBlock(nil);
    }
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
    if (self.dropboxFolderCreatedBlock) {
        self.dropboxFolderCreatedBlock(error);
    }
}

#pragma mark Upload File
- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath
{
    if ([self.progressDelegate respondsToSelector:@selector(uploadManager:uploadProgress:forModel:)]) {
        PGModel *model = self.currentUploads[destPath];
        [self.progressDelegate uploadManager:self uploadProgress:progress forModel:model];
    }
}


- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata
{
    PGModel *model = self.currentUploads[srcPath];
    [self.currentUploads removeObjectForKey:srcPath];
    if ([self.progressDelegate respondsToSelector:@selector(uploadManager:finishedUploadingModel:)]) {
        [self.progressDelegate uploadManager:self finishedUploadingModel:model];
    }
    if (self.dropboxFileUploadedBlock) {
        self.dropboxFileUploadedBlock(nil);
    }
}


- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
    NSString *sourcePath = [error userInfo][@"sourcePath"];
    PGModel *model = self.currentUploads[sourcePath];
    [self.currentUploads removeObjectForKey:sourcePath];
    if ([self.progressDelegate respondsToSelector:@selector(uploadManager:failedUploadingModel:)]) {
        [self.progressDelegate uploadManager:self failedUploadingModel:model];
    }
    if (self.dropboxFileUploadedBlock) {
        self.dropboxFileUploadedBlock(error);
    }
}
@end
