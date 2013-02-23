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

#define ZIPHELPER_ERROR_DOMAIN @"it.calcul8.polygon.ziphelper"

@implementation ZipHelper


#define BUFFER_SIZE 256
#define CALLBACK_BYTE_INTERVAL 25000

+ (void)unzipFile:(NSString *)fileName inZipFile:(NSString *)zipFilePath intoDirectory:(NSString *)destDir delegate:(id<ZipHelperDelegate>)delegate completion:(void (^)(NSError *error))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        if (![[zipFilePath lowercaseString] hasSuffix:@"zip"]){
            error = [NSError errorWithDomain:ZIPHELPER_ERROR_DOMAIN code:-100 userInfo:@{@"userInfo": NSLocalizedString(@"File does not have zip-extension", nil)}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error);
            });
            return;
        }
        NSString *destFilePath = [destDir stringByAppendingPathComponent:fileName];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:destFilePath]) {
            [fileManager createFileAtPath:destFilePath contents:nil attributes:nil];
        }
        
        NSFileHandle *destFileHandle = [NSFileHandle fileHandleForWritingAtPath:destFilePath];
        
        ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:zipFilePath mode:ZipFileModeUnzip];
        [unzipFile locateFileInZip:fileName];
        ZipReadStream *read= [unzipFile readCurrentFileInZip];
        NSUInteger fileSize = [unzipFile getCurrentFileInZipInfo].length;
        NSUInteger allBytesRead = 0;
        
        NSMutableData *buffer= [[NSMutableData alloc] initWithLength:BUFFER_SIZE];
        NSUInteger bytesRead = 0;
        do {
            [buffer setLength:BUFFER_SIZE];
            bytesRead = [read readDataWithBuffer:buffer];
            
            allBytesRead += bytesRead;
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([delegate respondsToSelector:@selector(zipProgress:forFile:)]) {
                    [delegate zipProgress:(CGFloat)allBytesRead/fileSize forFile:fileName];
                }
            });
            if (bytesRead > 0) {
                [buffer setLength:bytesRead];
                [destFileHandle writeData:buffer];
            } else
                break;
            
        } while (YES);

        [destFileHandle closeFile];
        [unzipFile close];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    });
}


+ (NSArray *)listFilesInZipFile:(NSString *)filePath
{
    ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:filePath mode:ZipFileModeUnzip];
    NSArray *infos     = [unzipFile listFileInZipInfos];
    [unzipFile close];
    return infos;
}


+ (void)zipFile:(NSString *)filePath
  intoDirectory:(NSString *)destinationDirectory
       delegate:(id<ZipHelperDelegate>)delegate
     completion:(void (^)(NSError *error, NSString *destinationPath))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        if (![fileManager fileExistsAtPath:filePath]) {
            error = [NSError errorWithDomain:ZIPHELPER_ERROR_DOMAIN code:-100 userInfo:@{@"error": NSLocalizedString(@"No file at path", nil)}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error, nil);
            });
            return;
        }
        NSString *zipDestPath       = [filePath.stringByDeletingPathExtension stringByAppendingString:@".zip"];
        NSUInteger fileSize         = [[fileManager attributesOfItemAtPath:filePath error:&error][NSFileSize] integerValue];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(error, nil);
            });
            return;
        }
        NSString *fileName          = [filePath lastPathComponent];
        ZipFile *zipFile            = [[ZipFile alloc] initWithFileName:zipDestPath mode:ZipFileModeCreate];
        ZipWriteStream *writeStream = [zipFile writeFileInZipWithName:fileName compressionLevel:ZipCompressionLevelDefault];
        
        NSInputStream *myStream = [NSInputStream inputStreamWithFileAtPath:filePath];
        [myStream open];
        uint8_t buffer[BUFFER_SIZE];
        
        NSUInteger allBytesRead = 0;
        NSUInteger bytesSinceLastCallback = 0;
        NSUInteger bytesRead = 0;
        while ([myStream hasBytesAvailable]) {
            bytesRead = [myStream read:buffer maxLength:sizeof(buffer)];
            allBytesRead += bytesRead;
            bytesSinceLastCallback += bytesRead;
            if (bytesSinceLastCallback > CALLBACK_BYTE_INTERVAL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate zipProgress:(CGFloat)allBytesRead/fileSize forFile:fileName];
                });
                bytesSinceLastCallback = 0;
            }
            NSData *myData = [NSData dataWithBytes:buffer length:bytesRead];
            [writeStream writeData:myData];
        }
        [writeStream finishedWriting];
        [zipFile close];
        [myStream close];
        
        if (![fileManager fileExistsAtPath:destinationDirectory]) {
            [fileManager createDirectoryAtPath:destinationDirectory withIntermediateDirectories:NO attributes:nil error:&error];
        }
        NSString *destinationPath = [destinationDirectory stringByAppendingPathComponent:zipDestPath.lastPathComponent];
        [fileManager moveItemAtPath:zipDestPath toPath:destinationPath error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error, destinationPath);
        });
    });
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
