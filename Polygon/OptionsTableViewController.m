//
//  OptionsTableViewController.m
//  FEViewer2
//
//  Created by Christian Hansen on 07/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "OptionsTableViewController.h"
#import "Constants.h"

@interface OptionsTableViewController ()

@end

@implementation OptionsTableViewController
@synthesize perspectiveOrthoSegmentedControl = _perspectiveOrthoSegmentedControl;
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
    [self configureInitialState];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [self setPerspectiveOrthoSegmentedControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)configureInitialState
{
    BOOL isOrthographic = [[NSUserDefaults standardUserDefaults] boolForKey:@"UserDefaults_PerspectiveView"];
    self.perspectiveOrthoSegmentedControl.selectedSegmentIndex = isOrthographic;
}

- (IBAction)viewModeAction:(UISegmentedControl *)sender 
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:sender.selectedSegmentIndex] forKey:@"UserDefaults_PerspectiveView"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate perspectiveOrthoWasChanged:sender];
}
@end
