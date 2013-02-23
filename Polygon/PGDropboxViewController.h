//
//  DropboxViewController.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@class PGModel, PGDropboxViewController;

typedef NS_ENUM(NSInteger, PGDropboxViewControllerType)
{
    PGDropboxViewControllerTypeDownload,
    PGDropboxViewControllerTypeUpload
};

@protocol PGDropboxUploadDelegate <NSObject>

- (BOOL)dropboxViewController:(PGDropboxViewController *)dropboxViewController shouldCompressModel:(PGModel *)model;

@end


@interface PGDropboxViewController : UITableViewController 

@property (nonatomic, strong) NSString *subPath;
@property (nonatomic) PGDropboxViewControllerType dropboxViewControllerType;
@property (nonatomic, strong) PGModel *uploadModel;
@property (nonatomic, weak) id<PGDropboxUploadDelegate> delegate;

@end
