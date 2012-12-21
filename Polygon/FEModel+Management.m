//
//  FEModel+Management.m
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "FEModel+Management.h"

@implementation FEModel (Management)

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
    return (self.dateAdded.unsignedLongLongValue > 0);
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
        || [extension isEqualToString:@"inp"])
    {
        return ModelTypeAnsys;
    }
    else if ([extension isEqualToString:@"bdf"])
    {
        return ModelTypeNastran;
    }
    else if ([extension isEqualToString:@"obj"])
    {
        return ModelTypeOBJ;
    }
    else if ([extension isEqualToString:@"dae"])
    {
        return ModelTypeDAE;
    }
    return ModelTypeUnknown;
}

#pragma mark - Custom import methods
- (BOOL)importModelSize:(id)data
{
    self.globalURL = [SourceDropbox stringByAppendingPathComponent:data];
    return YES;
}


- (BOOL)importGlobalURL:(unsigned long long)data
{
    self.modelSize = [NSNumber numberWithUnsignedLongLong:data];
    return YES;
}


#pragma mark - Deleting models


+ (void)deleteModels:(NSArray *)modelsToDelete completion:(void (^)(NSError *error))completion;
{
    NSMutableArray *objectIDs = [NSMutableArray array];
    for (NSManagedObject *anObject in modelsToDelete)
    {
        [objectIDs addObject:anObject.objectID];
    }
    
    
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSManagedObjectID *anID in objectIDs)
        {
            NSError *error;
            FEModel *aModel = (FEModel *)[localContext existingObjectWithID:anID error:&error];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
                return;
            }
            error = [FEModel deleteModel:aModel];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(error);
                });
                return;
            }
        }
    } completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    }];
}


+ (NSError *)deleteModel:(FEModel *)aModel
{
    NSError *error;
    [NSFileManager.defaultManager removeItemAtPath:aModel.enclosingFolder error:&error];
    [aModel deleteInContext:aModel.managedObjectContext];
    
    return error;
}

@end
