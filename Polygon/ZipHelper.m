//
//  ZipHelper.m
//  FEViewer2
//
//  Created by Christian Hansen on 5/23/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ZipHelper.h"
#import "FileInZipInfo.h"
#import "ZipReadStream.h"
#import "ZipWriteStream.h"
@implementation ZipHelper
@synthesize delegate = _delegate;

#define BUFFER_SIZE 256

+ (BOOL)extractFileAtPath:(NSString *)filePath
{
    BOOL succes = NO;
    
    if ([[filePath lowercaseString] hasSuffix:@"zip"]) 
    {
        ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:filePath mode:ZipFileModeUnzip];
        NSFileHandle *file= [NSFileHandle fileHandleForWritingAtPath:filePath];
        NSMutableData *buffer= [[NSMutableData alloc] initWithLength:BUFFER_SIZE];
        ZipReadStream *read= [unzipFile readCurrentFileInZip];
        
        // Read-then-write buffered loop
        do {
            
            // Reset buffer length
            [buffer setLength:BUFFER_SIZE];
            
            // Expand next chunk of bytes
            int bytesRead= [read readDataWithBuffer:buffer];
            if (bytesRead > 0) {
                
                // Write what we have read
                [buffer setLength:bytesRead];
                [file writeData:buffer];
                
            } else
                break;
            
        } while (YES);
        
        // Clean up
        [file closeFile];
        [read finishedReading];
    }
    return succes;
}

+ (BOOL)unzipFile:(NSString *)fileName inZipFile:(NSString *)zipFilePath toDestDirectory:(NSString *)destDir withDelegate:(id<ZipHelperDelegate>)delegate
{    
    if (![[zipFilePath lowercaseString] hasSuffix:@"zip"]) 
    {
        return NO;
    }
    
    ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:zipFilePath mode:ZipFileModeUnzip];
    [unzipFile locateFileInZip:fileName];

    
    NSString *destFilePath = [destDir stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[destDir stringByAppendingPathComponent:fileName]]) {
        [[NSFileManager defaultManager] createFileAtPath:destFilePath contents:nil attributes:nil];
    }
    else 
    {
        destFilePath = [destFilePath stringByAppendingFormat:@"_%@", [[NSDate date] description]];
        [[NSFileManager defaultManager] createDirectoryAtPath:destFilePath withIntermediateDirectories:NO attributes:nil error:nil];
    }

    
    NSFileHandle *destFileHandle = [NSFileHandle fileHandleForWritingAtPath:destFilePath];
    NSLog(@"destPath: %@", [destDir stringByAppendingPathComponent:fileName]);
    NSMutableData *buffer= [[NSMutableData alloc] initWithLength:BUFFER_SIZE];
    ZipReadStream *read= [unzipFile readCurrentFileInZip];
    
    NSUInteger fileSize = [unzipFile getCurrentFileInZipInfo].length;
    NSUInteger allBytesRead = 0;
    
    // Read-then-write buffered loop
    do {
        
        // Reset buffer length
        [buffer setLength:BUFFER_SIZE];
        
        // Expand next chunk of bytes
        NSUInteger bytesRead = [read readDataWithBuffer:buffer];
        
        allBytesRead += bytesRead;
        [delegate zipProgress:(CGFloat)allBytesRead/fileSize forFile:fileName];
        
        
        if (bytesRead > 0) {
            // Write what we have read
            [buffer setLength:bytesRead];
            [destFileHandle writeData:buffer];
            
        } else
            break;
        
    } while (YES);
    
    // Clean up
    //destFileHandle 
    [destFileHandle closeFile];
    //[read finishedReading];
    NSLog(@"closing unzip");
    [unzipFile close];
    
    return YES;
}


+ (NSArray *)listFilesInZipFile:(NSString *)filePath
{
    ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:filePath mode:ZipFileModeUnzip];
    NSArray *infos= [unzipFile listFileInZipInfos];
    
    NSMutableArray *zipFileContent = [NSMutableArray array];
    
    for (FileInZipInfo *info in infos) 
    {
        //NSLog(@"info: %@\n", info.name);
        [zipFileContent addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   info.name, @"filename", 
                                   [NSNumber numberWithInteger:info.size], @"zipsize", 
                                   [NSNumber numberWithInteger:info.length], @"unzippedsize", nil]];
    }
    [unzipFile close];
    return zipFileContent;
}


+ (NSString *)zipFileAtPath:(NSString *)filePath withDelegate:(id<ZipHelperDelegate>)delegate
{
    NSString *zipDestPath = [filePath stringByAppendingString:@".zip"];
    NSUInteger fileSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize] integerValue];
    NSString *fileName = [filePath lastPathComponent];
    ZipFile *zipFile= [[ZipFile alloc] initWithFileName:zipDestPath mode:ZipFileModeCreate];
    ZipWriteStream *writeStream= [zipFile writeFileInZipWithName:[filePath lastPathComponent] compressionLevel:ZipCompressionLevelDefault];
    
    NSInputStream *myStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    [myStream open];
    uint8_t buffer[BUFFER_SIZE];

    NSUInteger allBytesRead = 0;

    while ([myStream hasBytesAvailable]) 
    {
        NSUInteger bytesRead = [myStream read:buffer maxLength:sizeof(buffer)];
        
        allBytesRead += bytesRead;
        [delegate zipProgress:(CGFloat)allBytesRead/fileSize forFile:fileName];
        
        NSData *myData = [NSData dataWithBytes:buffer length:bytesRead];
        [writeStream writeData:myData];
    }
    [writeStream finishedWriting];
    [zipFile close];
    [myStream close];
    return zipDestPath;
}



@end
