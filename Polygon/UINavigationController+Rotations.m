//
//  UINavigationController+Rotations.m
//  Polygon
//
//  Created by Christian Hansen on 28/05/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "UINavigationController+Rotations.h"

@implementation UINavigationController (Rotations)

-(BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [self.topViewController preferredInterfaceOrientationForPresentation];
}

@end
