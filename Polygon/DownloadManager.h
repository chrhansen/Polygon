//
//  DownloadManager.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

@class DownloadManager, PGModel;

@protocol DownloadManagerDelegate <NSObject>

@optional
- (void)downloadManager:(DownloadManager *)sender didLoadDirectoryContents:(NSArray *)contents;
- (void)downloadManager:(DownloadManager *)sender failedLoadingDirectoryContents:(NSError *)error;
@end

@protocol DownloadManagerProgressDelegate <NSObject>
@optional
- (void)downloadManager:(DownloadManager *)sender loadProgress:(CGFloat)progress forModel:(PGModel *)model;
- (void)downloadManager:(DownloadManager *)sender finishedDownloadingModel:(PGModel *)model;
- (void)downloadManager:(DownloadManager *)sender failedDownloadingModel:(PGModel *)model;
@end

@interface DownloadManager : NSObject <DBRestClientDelegate>

+ (DownloadManager *)sharedInstance;

- (PGModel *)downloadFile:(DBMetadata *)fileMetadata;
- (PGModel *)downloadFilesAndDirectories:(NSArray *)metadatas rootFile:(DBMetadata *)rootMetadata;

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, weak) id<DownloadManagerDelegate> delegate;
@property (nonatomic, weak) id<DownloadManagerProgressDelegate> progressDelegate;

@end
