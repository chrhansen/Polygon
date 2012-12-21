//
//  SpaceBall.h
//  Polygon
//
//  Created by Christian Hansen on 02/06/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "Structs.h"

@interface SpaceBall : NSObject

+ (SpaceBall *)spaceBallWithRadius:(float)radius atLocation:(GLKVector3)location;

- (void)setRadius:(float)radius;
- (void)setColor:(GLKVector4)color;

@property (nonatomic) Vertex *vertices;
@property (nonatomic, readonly) NSUInteger numOfVertices;
@property (nonatomic) GLKVector3 location;
@property (nonatomic) BOOL hasChanged;


@end
