//
//  ColorTableViewController.m
//  Polygon
//
//  Created by Christian Hansen on 5/30/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ColorTableViewController.h"

@interface ColorTableViewController ()

@end

@implementation ColorTableViewController
@synthesize transparencySlider = _transparencySlider;
@synthesize colorTypeSegment = _colorTypeSegment;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [self setColorTypeSegment:nil];
    [self setTransparencySlider:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)transparencyChanged:(UISlider *)sender 
{
    if ([self.delegate respondsToSelector:@selector(transparencyChanged:)]) 
    {
        [self.delegate transparencyChanged:sender];
    }
}

- (IBAction)colorTypeChanged:(UISegmentedControl *)sender 
{
    if ([self.delegate respondsToSelector:@selector(colorTypeChanged:)]) 
    {
        [self.delegate colorTypeChanged:sender];
    }
}

@end
