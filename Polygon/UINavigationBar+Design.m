//
//  UINavigationBar+Design.m
//  Polygon
//
//  Created by Christian Hansen on 28/01/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "UINavigationBar+Design.h"

@implementation UINavigationBar (Design)

-(void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    [self configureShadow];
    [self applyDefaultColor];
}


- (void)configureShadow
{
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.8f;
    self.layer.shadowRadius = 9.0f;
    self.layer.shadowOffset = CGSizeMake(0,0);
    CGRect shadowPath = CGRectMake(self.layer.bounds.origin.x - 10, 0, self.layer.bounds.size.width + 20, self.layer.bounds.size.height+2);
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowPath].CGPath;
    self.layer.shouldRasterize = YES;
}


- (void)applyDefaultColor
{
    UIColor *customGray = [UIColor colorWithRed:219.0f/255.0f green:219.0f/255.0f  blue:219.0f/255.0f  alpha:1.0f];
    [[UINavigationBar appearance] setTintColor:customGray];
}

@end
