//
//  ROI3D.h
//  Polygon
//
//  Created by Christian Hansen on 6/27/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface ROI3D : NSObject

+ (ROI3D *)createROIAt:(GLKVector3)location andOrientation:(GLKQuaternion)orientation;

+ (ROI3D *)createFromDictionary:(NSDictionary *)dictionary;

+ (NSDictionary *)dictionaryRepresenation:(ROI3D *)aROI;


@property (nonatomic) GLKVector3 location;
@property (nonatomic) GLKQuaternion orientation;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) UIImage *snapshot;
@property (nonatomic, strong) NSString *snapshotFileName;
@end
