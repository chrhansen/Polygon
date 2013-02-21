//
//  NSData+MD5Hash.m
//  Polygon
//
//  Created by Christian Hansen on 19/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "NSData+MD5Hash.h"
#import "FileMD5Hash.h"

@implementation NSData (MD5Hash)

+ (NSString *)md5HashForFile:(NSString *)filePath
{
    NSString *md5Hash;
    CFStringRef executableFileMD5Hash = FileMD5HashCreateWithPath((CFStringRef)CFBridgingRetain(filePath), FileHashDefaultChunkSizeForReadingData);
    if (executableFileMD5Hash) {
        md5Hash = ((NSString *)CFBridgingRelease(executableFileMD5Hash));
        //        CFRelease(executableFileMD5Hash);
    }
    return md5Hash;
}


@end
