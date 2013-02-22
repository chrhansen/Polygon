//
//  PGUploadManager.h
//  Polygon
//
//  Created by Christian Hansen on 22/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

@class PGUploadManager, PGModel;

@protocol UploadManagerProgressDelegate <NSObject>
@optional
- (void)uploadManager:(PGUploadManager *)uploadManager uploadProgress:(CGFloat)progress forModel:(PGModel *)model;
- (void)uploadManager:(PGUploadManager *)uploadManager finishedUploadingModel:(PGModel *)model;
- (void)uploadManager:(PGUploadManager *)uploadManager failedUploadingModel:(PGModel *)model;
@end

@interface PGUploadManager : NSObject <DBRestClientDelegate>

+ (PGUploadManager *)sharedInstance;

- (void)createDropboxFolder:(NSString *)folderName atPath:(NSString *)dropboxPath completion:(void (^)(NSError *error))completion;
- (void)uploadModel:(PGModel *)model toPath:(NSString *)dropboxPath progressDelegate:(id<UploadManagerProgressDelegate>)progressDelegate completion:(void (^)(NSError *error))completion;

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, weak) id<UploadManagerProgressDelegate> progressDelegate;


@end
