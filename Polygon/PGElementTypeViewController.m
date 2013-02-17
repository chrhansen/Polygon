//
//  PGElementTypeViewController.m
//  Polygon
//
//  Created by Christian Hansen on 17/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "PGElementTypeViewController.h"

@interface PGElementTypeViewController ()

@end

@implementation PGElementTypeViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)solidAction:(id)sender
{
    [self.delegate solidTypeWasChanged:sender];
}

- (IBAction)shellAction:(id)sender
{
    [self.delegate shellTypeWasChanged:sender];
}

- (IBAction)beamAction:(id)sender
{
    [self.delegate beamTypeWasChanged:sender];
}

- (IBAction)edgeAction:(id)sender
{
    [self.delegate edgesWasChanged:sender];
}

@end
