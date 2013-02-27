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

#define CACHE_DIR [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)  objectAtIndex:0]

static NSString * const DropboxBaseURL = @"/";


extern NSString * const DropboxLinkStateChangedNotification;

extern NSString * const FileOpenFromEmailNotification;

static NSString * const DropboxFileDownloadedNotification = @"DropboxFileDownloadedNotification";
static NSString * const DropboxFailedDownloadNotification = @"DropboxFailedDownloadNotification";

#pragma mark - Apptentive
#define kApptentiveAPIKey @"5c0c408bf806cb13863ee36e8f30b5942975df717908673a9e28f01633eb6ab6"
#define ItunesConnectAppID @"530960635"

#pragma mark - Source Identifiers
extern NSString * const SourceEmail;
extern NSString * const SourceDropbox;

// First Launch
extern NSString * const PGFirstLaunch;


#pragma mark - From Old Polygon Constants

// Notifications
extern NSString * const DropboxLinkStateChangedNotification;
extern NSString * const FileOpenFromEmailNotification;
extern NSString * const CompressedFileContainsMultipleItemsNotification;

extern NSString * const DropboxNewFileDownLoaded;
extern NSString * const DropboxZipFileDownLoaded;
extern NSString * const DropboxUploadFolderSelected;

extern NSString * const DropboxNewFileUpLoaded;
extern NSString * const DropboxUpLoadedError;

//extern NSString * const kReachabilityChangedNotification;


// User Defaults
extern NSString * const PGBundledModels;
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

#define IS_IPAD (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)

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


// In-App purchases
extern NSString * const InAppIdentifierUnlimitedModels;
extern NSString * const InAppIdentifierOBJModels;
extern NSString * const InAppIdentifierAnsys; 
extern NSString * const InAppIdentifierDAEModels;

extern NSString * const InAppNotPurchasedNotification;

extern NSString * const BUNDLED_MD5_ID_1;

