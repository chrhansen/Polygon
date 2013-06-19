//
//  Constants.m
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "Constants.h"

// notifications

NSString *const DropboxLinkStateChangedNotification = @"DropboxLinkStateChangedNotification";
NSString *const DropboxNewFileDownLoaded = @"DropboxNewFileDownLoaded";
NSString *const DropboxZipFileDownLoaded = @"DropboxZipFileDownLoaded";
NSString *const DropboxNewFileUpLoaded = @"DropboxNewFileUpLoaded";
NSString *const DropboxUpLoadedError = @"DropboxUpLoadedError";
NSString *const DropboxUploadFolderSelected = @"DropboxUploadFolderSelected";
NSString *const DownloadManagerError = @"DownloadManagerError";

NSString *const FileOpenFromEmailNotification = @"FileOpenFromEmailNotification";
NSString *const CompressedFileContainsMultipleItemsNotification = @"CompressedFileContainsMultipleItemsNotification";


NSString *const PolygonAnsysModelLimitPassed = @"PolygonAnsysModelLimitPassed";

#pragma mark - Source Identifiers
NSString *const SourceEmail = @"SourceEmail";
NSString *const SourceDropbox = @"http://www.dropbox.com";



// user default constants
// First Launch
NSString * const PGFirstLaunch = @"PGFirstLaunch";

NSString *const yyy = @"yyy";
NSString *const PGBundledModels = @"PGBundledModels";
NSString *const UserDefaults_PerspectiveView = @"UserDefaults_PerspectiveView";
NSString *const POLYGON_PURCHASED_PRODUCTS = @"POLYGON_PURCHASED_PRODUCTS";


// constants
NSString *const AnsysFileFormats = @"AnsysFileFormats";
NSString *const NastranFileFormats = @"NastranFileFormats";
NSString *const LSPrePostFileFormats = @"LSPrePostFileFormats";
NSString *const ParsableFormats = @"ParsableFormats";


// ROI list
NSString *const ROIs = @"ROIs";
NSString *const PolygonROIs = @"PolygonROIs";


// In-App purchases
NSString * const InAppIdentifierUnlimitedModels = @"it.calcul8.polygon.unlimitedmodels";
NSString * const InAppIdentifierOBJModels       = @"it.calcul8.polygon.objmodels";
NSString * const InAppIdentifierAnsys           = @"it.calcul8.polygon.ansys";
NSString * const InAppIdentifierDAEModels       = @"it.calcul8.polygon.daemodels";

NSString * const InAppNotPurchasedNotification  = @"InAppNotPurchasedNotification";


NSString * const BUNDLED_MD5_ID_1 = @"3175843bcff1e3ae90a21725c089807c"; // Barrel OBJ model
NSString * const BUNDLED_MD5_ID_2 = @"41af218364950bca5d66740f6355732c"; // Partial beam Ansys model
