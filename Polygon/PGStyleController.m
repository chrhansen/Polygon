//
//  FGStyleController.m
//  Flow2Go
//
//  Created by Christian Hansen on 08/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "PGStyleController.h"

@implementation PGStyleController

+ (void)applyAppearance
{
    [self styleNavigationBar];
    [self styleToolBar];
}


+ (void)styleNavigationBar
{
    UIColor *customGray = [UIColor colorWithRed:219.0f/255.0f green:219.0f/255.0f  blue:219.0f/255.0f  alpha:1.0f];
    [[UINavigationBar appearance] setTintColor:customGray];
    UIImage *image = [UIImage imageNamed:@"shadowimage"];
    [[UINavigationBar appearance] setShadowImage:image];
}

+ (void)styleToolBar
{
    UIColor *customGray = [UIColor colorWithRed:219.0f/255.0f green:219.0f/255.0f  blue:219.0f/255.0f  alpha:1.0f];
    [[UIToolbar appearance] setTintColor:customGray];
}

@end
