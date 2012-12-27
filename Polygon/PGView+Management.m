//
//  View+Management.m
//  Polygon
//
//  Created by Christian Hansen on 21/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGView+Management.h"
#import <GLKit/GLKit.h>

@implementation PGView (Management)

+ (PGView *)createWith:(GLKVector3)location andOrientation:(GLKQuaternion)orientation
{
    PGView *newView = [PGView createEntity];
    newView.xLocation = [NSNumber numberWithFloat:location.x];
    newView.yLocation = [NSNumber numberWithFloat:location.y];
    newView.zLocation = [NSNumber numberWithFloat:location.z];
    
    newView.xRotation = [NSNumber numberWithFloat:orientation.x];
    newView.yRotation = [NSNumber numberWithFloat:orientation.y];
    newView.zRotation = [NSNumber numberWithFloat:orientation.z];
//    newView.angle = [NSNumber numberWithFloat:orientation.w];
    return nil;
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
