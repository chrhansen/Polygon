//
//  View+Management.m
//  Polygon
//
//  Created by Christian Hansen on 21/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGView+Management.h"

@implementation PGView (Management)

+ (PGView *)createWithLocationX:(CGFloat)xLocation
                      locationY:(CGFloat)yLocation
                      locationZ:(CGFloat)zLocation
                    quaternionX:(CGFloat)xComponent
                    quaternionY:(CGFloat)yComponent
                    quaternionZ:(CGFloat)zComponent
                    quaternionW:(CGFloat)wAngle
                     screenShot:(UIImage *)image
                      inContext:(NSManagedObjectContext *)context
{
    PGView *newView = [PGView createInContext:context];
    newView.xLocation = [NSNumber numberWithFloat:xLocation];
    newView.yLocation = [NSNumber numberWithFloat:yLocation];
    newView.zLocation = [NSNumber numberWithFloat:zLocation];
    
    newView.xRotation = [NSNumber numberWithFloat:xComponent];
    newView.yRotation = [NSNumber numberWithFloat:yComponent];
    newView.zRotation = [NSNumber numberWithFloat:zComponent];
    newView.wAngle    = [NSNumber numberWithFloat:wAngle];
    
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
    if (!viewToDelete) {
        return;
    }
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
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        NSError *error;
        PGView *localView = (PGView *)[localContext existingObjectWithID:objectID error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(error);
            });
            return;
        }
        [localView deleteInContext:localContext];
    } completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(error);
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
