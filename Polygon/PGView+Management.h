//
//  View+Management.h
//  Polygon
//
//  Created by Christian Hansen on 21/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGView.h"
#import <GLKit/GLKit.h>

@interface PGView (Management)

+ (PGView *)createWith:(GLKVector3)location orientation:(GLKQuaternion)orientation screenShot:(UIImage *)image;
- (PGView *)copyEntity;

+ (void)deleteView:(PGView *)viewToDelete completion:(void (^)(NSError *error))completion;


@property (nonatomic, weak, readonly) NSString *dateAddedAsLocalizedString;

@end
