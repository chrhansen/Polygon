//
//  NodePicker.m
//  FEViewer2
//
//  Created by Christian Hansen on 04/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "NodePicker.h"

@implementation NodePicker

+ (NSUInteger)nodeForCoordinate:(GLKVector3)nodePosition inArray:(GLKVector3 *)positionsArray
{
    NSUInteger nodeNumber = 0;
    
    NSLog(@"ProjectedPos: %@, Node: %i,  position: %@", NSStringFromGLKVector3(nodePosition), 500, NSStringFromGLKVector3(positionsArray[500]));
    
    return nodeNumber;
}
@end
