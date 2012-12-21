//
//  Constants.h
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HOME_DIR [[[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject path] stringByDeletingLastPathComponent]

#define HOME_URL [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject URLByDeletingLastPathComponent]

#define DOCUMENTS_DIR [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject path]
#define TEMP_DIR [[[[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"tmp"]

static NSString * const DropboxBaseURL = @"/";

static NSString * const DropboxLinkedNotification = @"DropboxLinkedNotification";
static NSString * const DropboxFileDownloadedNotification = @"DropboxFileDownloadedNotification";
static NSString * const DropboxFailedDownloadNotification = @"DropboxFailedDownloadNotification";

#pragma mark - Source Identifiers
extern NSString * const SourceEmail;
extern NSString * const SourceDropbox;



#pragma mark - From Old Polygon Constants

// Notifications
extern NSString * const DropboxLinkStateChangedNotification;
extern NSString * const FileOpenFromEmailNotification;

extern NSString * const DropboxNewFileDownLoaded;
extern NSString * const DropboxZipFileDownLoaded;
extern NSString * const DropboxUploadFolderSelected;

extern NSString * const DropboxNewFileUpLoaded;
extern NSString * const DropboxUpLoadedError;

extern NSString * const PolygonAnsysModelLimitPassed;

extern NSString * const PolygonModelTypeNotPurchased;

//extern NSString * const kReachabilityChangedNotification;


// User Defaults
extern NSString * const BundledModels;
extern NSString * const UserDefaults_PerspectiveView;
extern NSString * const POLYGON_PURCHASED_PRODUCTS;


// constants
extern NSString * const AnsysFileFormats;
extern NSString * const NastranFileFormats;
extern NSString * const LSPrePostFileFormats;
extern NSString * const ParsableFormats;

// ROI list
extern NSString * const ROIs;
extern NSString * const PolygonROIs;


#define BIG_MODEL_LIMIT 5000


typedef enum {
    kLowMem,
    kMediumMem,
    kFullMem
} MemoryReadingFormat;


typedef enum {
    ModelTypeUnknown,
    ModelTypeAnsys,
    ModelTypeNastran,
    ModelTypeLSPrePost,
    ModelTypeOBJ,
    ModelTypeDAE
} ModelType;

