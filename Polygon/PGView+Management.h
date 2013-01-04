//
//  View+Management.h
//  Polygon
//
//  Created by Christian Hansen on 21/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGView.h"

@interface PGView (Management)

+ (PGView *)createWithLocationX:(CGFloat)xLocation
                      locationY:(CGFloat)yLocation
                      locationZ:(CGFloat)zLocation
                    quaternionX:(CGFloat)xComponent
                    quaternionY:(CGFloat)yComponent
                    quaternionZ:(CGFloat)zComponent
                    quaternionW:(CGFloat)wAngle
                     screenShot:(UIImage *)image;

- (PGView *)copyEntity;

+ (void)deleteView:(PGView *)viewToDelete completion:(void (^)(NSError *error))completion;

@property (nonatomic, weak, readonly) NSString *dateAddedAsLocalizedString;

@end
