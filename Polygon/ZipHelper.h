//
//  ZipHelper.h
//  FEViewer2
//
//  Created by Christian Hansen on 5/23/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZipFile.h"

@protocol ZipHelperDelegate <NSObject>

- (void)zipProgress:(float)progress forFile:(NSString *)fileName;

@end

@interface ZipHelper : NSObject

+ (BOOL)extractFileAtPath:(NSString *)filePath;

+ (BOOL)unzipFile:(NSString *)fileName inZipFile:(NSString *)zipFilePath toDestDirectory:(NSString *)destDir withDelegate:(id<ZipHelperDelegate>)delegate;

+ (NSArray *)listFilesInZipFile:(NSString *)filePath;

+ (NSString *)zipFileAtPath:(NSString *)filePath withDelegate:(id<ZipHelperDelegate>)delegate;

@property (nonatomic, weak) id<ZipHelperDelegate> delegate;

@end
