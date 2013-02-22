//
//  DownloadManager.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

@class PGDownloadManager, PGModel;

@protocol DownloadManagerDelegate <NSObject>

@optional
- (void)downloadManager:(PGDownloadManager *)downloadManager didLoadDirectoryContents:(NSArray *)contents;
- (void)downloadManager:(PGDownloadManager *)downloadManager failedLoadingDirectoryContents:(NSError *)error;
- (void)downloadManager:(PGDownloadManager *)downloadManager didLoadThumbnail:(DBMetadata *)metadata;
@end

@protocol DownloadManagerProgressDelegate <NSObject>
@optional
- (void)downloadManager:(PGDownloadManager *)downloadManager loadProgress:(CGFloat)progress forModel:(PGModel *)model;
- (void)downloadManager:(PGDownloadManager *)downloadManager finishedDownloadingModel:(PGModel *)model;
- (void)downloadManager:(PGDownloadManager *)downloadManager failedDownloadingModel:(PGModel *)model;
@end

@interface PGDownloadManager : NSObject <DBRestClientDelegate>

+ (PGDownloadManager *)sharedInstance;

- (PGModel *)downloadFile:(DBMetadata *)fileMetadata;
- (PGModel *)downloadFilesAndDirectories:(NSArray *)metadatas rootFile:(DBMetadata *)rootMetadata;
- (void)importModelFileFromPath:(NSString *)filePath;

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, weak) id<DownloadManagerDelegate> delegate;
@property (nonatomic, weak) id<DownloadManagerProgressDelegate> progressDelegate;

@end
