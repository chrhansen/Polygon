//
//  PGLocalFilesImporter.m
//  Polygon
//
//  Created by Christian Hansen on 24/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "PGFirstLaunchTasks.h"
#import "PGModel+Management.h"
#import "PGDownloadManager.h"

@implementation PGFirstLaunchTasks

+ (void)performFirstLaunchTasksWithCompletion:(void (^)(NSError *error))completion
{
    // Import models in users Documents directory
    NSArray *localModels = [self findModelsInDirectory:DOCUMENTS_DIR];
    for (NSString *filePath in localModels) {
        [[PGDownloadManager sharedInstance] importModelFileFromPath:filePath];
    }

    // Import models from main bundle
    [self copyBundleDirectoryToTempDirectory:PGBundledModels];
    NSArray *bundleModels = [self findModelsInDirectory:[TEMP_DIR stringByAppendingPathComponent:PGBundledModels]];
    for (NSString *filePath in bundleModels) {
        PGModel *model = [[PGDownloadManager sharedInstance] importModelFileFromPath:filePath];
        [self moveSubitemsAtDirectory:filePath.stringByDeletingLastPathComponent toModelDirectory:model];
    }
        
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) completion(nil);
    });
}


+ (void)moveSubitemsAtDirectory:(NSString *)directoryPath toModelDirectory:(PGModel *)model
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *subItems = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
    for (NSString *subItemPath in subItems) {
        if (![subItemPath isEqualToString:model.modelName]) {
            NSError *error;
            [fileManager moveItemAtPath:[directoryPath stringByAppendingPathComponent:subItemPath] toPath:[model.enclosingFolder stringByAppendingPathComponent:subItemPath] error:&error];
            if (error) NSLog(@"Error moving subitem: %@", error.localizedDescription);
        }
    }
}

+ (NSArray *)findModelsInDirectory:(NSString *)directoryToSearch
{
    NSMutableArray *localPaths = [NSMutableArray array];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:directoryToSearch];
    
    NSString *file;
    while (file = [dirEnum nextObject])
    {
        if ([PGModel modelTypeForFileName:file.lastPathComponent] != ModelTypeUnknown)
        {
            NSString *filePath = [directoryToSearch stringByAppendingPathComponent:file];
            BOOL isDir;
            
            if ([fileManager fileExistsAtPath:filePath isDirectory:&isDir] && !isDir)
            {
                [localPaths addObject:filePath];
            }
        }
    }
    return localPaths;
}


+ (void)copyBundleDirectoryToTempDirectory:(NSString *)bundleDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *resourceDirectory = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:bundleDirectory];
    [fileManager copyItemAtPath:resourceDirectory toPath:[TEMP_DIR stringByAppendingPathComponent:bundleDirectory] error:&error];
}

@end
