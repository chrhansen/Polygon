//
//  PGTransparencyViewController.m
//  Polygon
//
//  Created by Christian Hansen on 18/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "PGTransparencyViewController.h"

@interface PGTransparencyViewController ()

@end

@implementation PGTransparencyViewController


- (IBAction)transparencyChanged:(UISlider *)sender
{
    if ([self.delegate respondsToSelector:@selector(transparencyChanged:)]){
        [self.delegate transparencyChanged:sender];
    }
}


@end
