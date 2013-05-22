//
//  PGModel+Management.m
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGModel+Management.h"
#import <DropboxSDK/DBMetadata.h>

@implementation PGModel (Management)

- (NSString *)fullModelFilePath
{
    return [HOME_DIR stringByAppendingPathComponent:self.filePath];
}

- (NSString *)enclosingFolder
{
    return self.fullModelFilePath.stringByDeletingLastPathComponent;
}

- (BOOL)isDownloaded
{
    NSArray *pathComponents = [self.filePath pathComponents];
    return (pathComponents.count > 0 && [pathComponents[0] isEqualToString:@"Documents"]);
}

#pragma mark - Image getters/setters
- (void)setModelImage:(UIImage *)image
{
    [self willChangeValueForKey:@"modelImage"];
    NSData *data = UIImagePNGRepresentation(image);
    [self setPrimitiveValue:data forKey:@"modelImage"];
    [self didChangeValueForKey:@"modelImage"];
}

- (UIImage*)modelImage
{
    [self willAccessValueForKey:@"modelImage"];
    UIImage *image = [UIImage imageWithData:[self primitiveValueForKey:@"modelImage"]];
    [self didAccessValueForKey:@"modelImage"];
    return image;
}

- (ModelType)modelType
{
    return [self.class modelTypeForFileName:self.modelName];
}

+ (ModelType)modelTypeForFileName:(NSString *)fileNameWithExtension
{
    NSString *extension = fileNameWithExtension.pathExtension.lowercaseString;
    if ([extension isEqualToString:@"cdb"]
        || [extension isEqualToString:@"ans"]
        || [extension isEqualToString:@"inp"]) {
        return ModelTypeAnsys;
    }
    else if ([extension isEqualToString:@"bdf"]) {
        return ModelTypeNastran;
    } else if ([extension isEqualToString:@"k"]) {
        return ModelTypeNastran;
    } else if ([extension isEqualToString:@"obj"]) {
        return ModelTypeOBJ;
    } else if ([extension isEqualToString:@"dae"]) {
        return ModelTypeDAE;
    }
    return ModelTypeUnknown;
}

+ (BOOL)canHaveSubItems:(NSString *)fileNameWithExtension
{
    switch ([self modelTypeForFileName:fileNameWithExtension]) {
        case ModelTypeAnsys:
        case ModelTypeNastran:
        case ModelTypeLSPrePost:
            return NO;
            break;
            
        case ModelTypeOBJ:
        case ModelTypeDAE:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
    return YES;
}


- (NSDictionary *)subitems
{
    NSString *origFilePath = self.fullModelFilePath;
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:self.enclosingFolder];
    NSMutableDictionary *items = [NSMutableDictionary new];
    NSString *file;
    while (file = [dirEnum nextObject]) {
        NSString *filePath = [self.enclosingFolder stringByAppendingPathComponent:file];
        if ([filePath isEqualToString:origFilePath]) {
            continue;
        }
        NSError *error;
        NSDictionary *fileInfo = [fileManager attributesOfItemAtPath:filePath error:&error];
        if (!error && fileInfo[NSFileType] == NSFileTypeRegular) {
            [items setValue:fileInfo forKey:filePath];
        }
    }
    return items;
}


- (NSDate *)dateAddedAsDate
{
    return [NSDate dateWithTimeIntervalSince1970:(double)self.dateAdded.unsignedLongLongValue];
}


- (NSString *)dateAddedAsLocalizedString
{
    NSDate *date = [self dateAddedAsDate];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMM dd, YYYY, HH:mm"];
    return [format stringFromDate:date];
}


- (BOOL)importModelSize:(id)data
{
    unsigned long long size = 0;
    if ([data isKindOfClass:[DBMetadata class]]) {
        size = [(DBMetadata *)data totalBytes];
    } else if ([data isKindOfClass:[NSNumber class]]) {
        size = [(NSNumber *)data unsignedLongLongValue];
    }
    self.modelSize = [NSNumber numberWithUnsignedLongLong:size];
    return YES;
}


#pragma mark - Deleting models
+ (void)deleteModels:(NSArray *)modelsToDelete completion:(void (^)(NSError *error))completion
{
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
    NSError *permanentIDError;
    [context obtainPermanentIDsForObjects:modelsToDelete error:&permanentIDError];
    if (permanentIDError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(permanentIDError);
        });
        return;
    }
    NSMutableArray *objectIDs = [NSMutableArray array];
    for (NSManagedObject *anObject in modelsToDelete){
        [objectIDs addObject:anObject.objectID];
    }
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSManagedObjectID *anID in objectIDs)
        {
            NSError *error;
            PGModel *aModel = (PGModel *)[localContext existingObjectWithID:anID error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(error);
                });
                return;
            }
            error = [PGModel deleteModel:aModel];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion(error);
                });
                return;
            }
        }
    }  completion:^(BOOL success, NSError *error) {
        NSAssert([NSThread isMainThread], @"Callback in delete is NOT on Main Thread");
        if (completion) completion(error);
    }];
}


+ (NSError *)deleteModel:(PGModel *)aModel
{
    NSError *error;
    [NSFileManager.defaultManager removeItemAtPath:aModel.enclosingFolder error:&error];
    [aModel deleteInContext:aModel.managedObjectContext];
    
    return error;
}

@end
