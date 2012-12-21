//
//  ROI3D.m
//  Polygon
//
//  Created by Christian Hansen on 6/27/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ROI3D.h"

@implementation ROI3D
@synthesize title = _title;
@synthesize description = _description;
@synthesize location = _location;
@synthesize orientation = _orientation;
@synthesize snapshot = _snapshot;
@synthesize snapshotFileName = _snapshotFileName;

+ (ROI3D *)createROIAt:(GLKVector3)location andOrientation:(GLKQuaternion)orientation
{
    ROI3D *newROI = [[super alloc] init];
    if (newROI) 
    {
        newROI.location = location;
        newROI.orientation = orientation;
        return newROI;
    }
    return nil;
}

+ (ROI3D *)createFromDictionary:(NSDictionary *)dictionary
{
    ROI3D *newROI = [[super alloc] init];
    if (newROI) 
    {
        CGFloat xLoc = [[dictionary objectForKey:@"x_location"] floatValue];
        CGFloat yLoc = [[dictionary objectForKey:@"y_location"] floatValue];
        CGFloat zLoc = [[dictionary objectForKey:@"z_location"] floatValue];
                
        CGFloat xQuat = [[dictionary objectForKey:@"x_quaternion"] floatValue];
        CGFloat yQuat = [[dictionary objectForKey:@"y_quaternion"] floatValue];
        CGFloat zQuat = [[dictionary objectForKey:@"z_quaternion"] floatValue];
        CGFloat angleQuat = [[dictionary objectForKey:@"angle_quaternion"] floatValue];
        
        newROI.location = GLKVector3Make(xLoc, yLoc, zLoc);
        newROI.orientation = GLKQuaternionMakeWithVector3(GLKVector3Make(xQuat, yQuat, zQuat), angleQuat);
        
        newROI.title = [dictionary objectForKey:@"title"];
        newROI.description = [dictionary objectForKey:@"description"];

        //newROI.snapshot = [dictionary objectForKey:@"snapshot"];
        newROI.snapshotFileName = [dictionary objectForKey:@"snapshotFileName"];

        return newROI;
    }
    return nil;
}


+ (NSDictionary *)dictionaryRepresenation:(ROI3D *)aROI
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (dictionary) 
    {
        NSNumber *xLoc = [NSNumber numberWithFloat:aROI.location.x];
        NSNumber *yLoc = [NSNumber numberWithFloat:aROI.location.y];
        NSNumber *zLoc = [NSNumber numberWithFloat:aROI.location.z];
        
        NSNumber *xQuat = [NSNumber numberWithFloat:aROI.orientation.v.x];
        NSNumber *yQuat = [NSNumber numberWithFloat:aROI.orientation.v.y];
        NSNumber *zQuat = [NSNumber numberWithFloat:aROI.orientation.v.z];
        NSNumber *angleQuat = [NSNumber numberWithFloat:aROI.orientation.w];
        
        [dictionary setObject:xLoc forKey:@"x_location"];
        [dictionary setObject:yLoc forKey:@"y_location"];
        [dictionary setObject:zLoc forKey:@"z_location"];
        
        [dictionary setObject:xQuat forKey:@"x_quaternion"];
        [dictionary setObject:yQuat forKey:@"y_quaternion"];
        [dictionary setObject:zQuat forKey:@"z_quaternion"];
        [dictionary setObject:angleQuat forKey:@"angle_quaternion"];
        
        //[dictionary setObject:aROI.snapshot forKey:@"snapshot"];
        [dictionary setObject:aROI.snapshotFileName forKey:@"snapshotFileName"];
        
        if (aROI.title) {
            [dictionary setObject:aROI.title forKey:@"title"];
        }
        
        if (aROI.description) {
            [dictionary setObject:aROI.description forKey:@"description"];
        }
        
        return dictionary;
    }
    return nil;
}

@end
