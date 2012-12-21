//
//  NodePicker.h
//  FEViewer2
//
//  Created by Christian Hansen on 04/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface NodePicker : NSObject

+ (NSUInteger)nodeForCoordinate:(GLKVector3)nodePosition inArray:(GLKVector3 *)positionsArray;

@end
