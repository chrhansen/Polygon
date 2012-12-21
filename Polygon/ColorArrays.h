//
//  ColorArrays.h
//  FEViewer2
//
//  Created by Christian Hansen on 5/3/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface ColorArrays : NSObject

+ (GLKVector4 *)materialColorsWithTransparency:(float)transparency;

@end
