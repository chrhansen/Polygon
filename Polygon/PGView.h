//
//  PGView.h
//  Polygon
//
//  Created by Christian Hansen on 27/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PGModel;

@interface PGView : NSManagedObject

@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * wAngle;
@property (nonatomic, retain) NSNumber * xLocation;
@property (nonatomic, retain) NSNumber * xRotation;
@property (nonatomic, retain) NSNumber * yLocation;
@property (nonatomic, retain) NSNumber * yRotation;
@property (nonatomic, retain) NSNumber * zLocation;
@property (nonatomic, retain) NSNumber * zRotation;
@property (nonatomic, retain) PGModel *viewOf;

@end
