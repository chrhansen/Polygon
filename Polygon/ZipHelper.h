//
//  ZipHelper.h
//  FEViewer2
//
//  Created by Christian Hansen on 5/23/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZipFile.h"
#import "FileInZipInfo.h"

@protocol ZipHelperDelegate <NSObject>
@optional
- (void)zipProgress:(float)progress forFile:(NSString *)fileName;
@end

@interface ZipHelper : NSObject

+ (void)unzipFile:(NSString *)fileName
        inZipFile:(NSString *)zipFilePath
    intoDirectory:(NSString *)destDir
         delegate:(id<ZipHelperDelegate>)delegate
       completion:(void (^)(NSError *error))completion;

+ (NSArray *)listFilesInZipFile:(NSString *)filePath;

+ (NSString *)zipFileAtPath:(NSString *)filePath withDelegate:(id<ZipHelperDelegate>)delegate;

@end
