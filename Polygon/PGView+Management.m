//
//  View+Management.m
//  Polygon
//
//  Created by Christian Hansen on 21/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGView+Management.h"

@implementation PGView (Management)

+ (PGView *)createWith:(GLKVector3)location orientation:(GLKQuaternion)orientation screenShot:(UIImage *)image;
{
    PGView *newView = [PGView createEntity];
    newView.xLocation = [NSNumber numberWithFloat:location.x];
    newView.yLocation = [NSNumber numberWithFloat:location.y];
    newView.zLocation = [NSNumber numberWithFloat:location.z];
    
    newView.xRotation = [NSNumber numberWithFloat:orientation.x];
    newView.yRotation = [NSNumber numberWithFloat:orientation.y];
    newView.zRotation = [NSNumber numberWithFloat:orientation.z];
    newView.wAngle    = [NSNumber numberWithFloat:orientation.w];
    
    newView.image = image;

    return newView;
}


- (PGView *)copyEntity
{
    PGView *viewCopy = [PGView createInContext:[NSManagedObjectContext contextForCurrentThread]];
    for (NSAttributeDescription *attribute in self.entity.properties)
    {
        id value = [self valueForKey:attribute.name];
        if (value) [viewCopy setValue:value forKey:attribute.name];
    }
    return viewCopy;
}

+ (void)deleteView:(PGView *)viewToDelete completion:(void (^)(NSError *error))completion
{
    NSManagedObjectContext *context = viewToDelete.managedObjectContext;
    NSError *permanentIDError;
    [context obtainPermanentIDsForObjects:@[viewToDelete] error:&permanentIDError];
    if (permanentIDError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(permanentIDError);
        });
        return;
    }
    NSManagedObjectID *objectID = viewToDelete.objectID;
    
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        NSError *error;
        PGView *localView = (PGView *)[localContext existingObjectWithID:objectID error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(error);
            });
            return;
        }
        [localView deleteInContext:localContext];
    } completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(nil);
        });
    }];
}


#pragma mark - Image getters/setters
- (void)setImage:(UIImage *)image
{
    [self willChangeValueForKey:@"image"];
    NSData *data = UIImagePNGRepresentation(image);
    [self setPrimitiveValue:data forKey:@"image"];
    [self didChangeValueForKey:@"image"];
}

- (UIImage*)image
{
    [self willAccessValueForKey:@"image"];
    UIImage *image = [UIImage imageWithData:[self primitiveValueForKey:@"image"]];
    [self didAccessValueForKey:@"image"];
    return image;
}


- (NSString *)dateAddedAsLocalizedString
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMM dd, YYYY, HH:mm"];
    return [format stringFromDate:[self dateModified]];
}

@end
