//
//  FEModel.h
//  Polygon
//
//  Created by Christian Hansen on 16/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface FEModel : NSManagedObject

@property (nonatomic, retain) NSNumber * dateAdded;
@property (nonatomic, retain) NSString * fEModelID;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSString * globalURL;
@property (nonatomic, retain) UIImage * modelImage;
@property (nonatomic, retain) NSString * modelName;
@property (nonatomic, retain) NSNumber * modelSize;

@end
