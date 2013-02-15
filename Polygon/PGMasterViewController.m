//
//  PGMasterViewController.m
//  Polygon
//
//  Created by Christian Hansen on 28/01/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "PGMasterViewController.h"

@interface PGMasterViewController ()

@property (nonatomic, strong) NSDictionary *paneViewControllerTitles;
@property (nonatomic, strong) NSDictionary *paneViewControllerIdentifiers;

@end

@implementation PGMasterViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.paneViewControllerType = NSUIntegerMax;
        self.paneViewControllerTitles = @{
        @(PGPaneViewControllerTypeModels) : @"Models",
        @(PGPaneViewControllerTypeDropbox) : @"Dropbox",
        @(PGPaneViewControllerTypeStore) : @"Store",
        @(PGPaneViewControllerTypeOther2) : @"Other 2"
        };
        self.paneViewControllerIdentifiers = @{
        @(PGPaneViewControllerTypeModels) : @"modelsCollectionViewController",
        @(PGPaneViewControllerTypeDropbox) : @"dropboxViewController",
        @(PGPaneViewControllerTypeStore) : @"storeViewController",
        @(PGPaneViewControllerTypeOther2) : @"otherViewController",
        };
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationPaneViewController setAppearanceType:MSNavigationPaneAppearanceTypeParallax];
    self.tableView.scrollsToTop = NO;
    [self.navigationController.navigationBar setHidden:NO];
}


#pragma mark - MSMasterViewController

- (PGPaneViewControllerType)paneViewControllerTypeForIndexPath:(NSIndexPath *)indexPath
{
    PGPaneViewControllerType paneViewControllerType = nil;
    if (indexPath.section == 0) {
        paneViewControllerType = indexPath.row;
    } else {
        NSLog(@"ERROR: didn't request section 0 in PGMasterViewController");
    }
    return paneViewControllerType;
}

- (void)transitionToViewController:(PGPaneViewControllerType)paneViewControllerType
{
    if (paneViewControllerType == self.paneViewControllerType) {
        [self.navigationPaneViewController setPaneState:MSNavigationPaneStateClosed animated:YES];
        return;
    }
    
    BOOL animateTransition = self.navigationPaneViewController.paneViewController != nil;
    
    UIViewController *paneViewController = [self.navigationPaneViewController.storyboard instantiateViewControllerWithIdentifier:self.paneViewControllerIdentifiers[@(paneViewControllerType)]];
    
    paneViewController.navigationItem.title = self.paneViewControllerTitles[@(paneViewControllerType)];
    paneViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"PGBarButtonIconNavigationPane"] style:UIBarButtonItemStyleBordered target:self action:@selector(navigationPaneBarButtonItemTapped:)];
    UINavigationController *paneNavigationViewController = [[UINavigationController alloc] initWithRootViewController:paneViewController];
    
    [self.navigationPaneViewController setPaneViewController:paneNavigationViewController animated:animateTransition completion:nil];
    
    self.paneViewControllerType = paneViewControllerType;
}

- (void)navigationPaneBarButtonItemTapped:(id)sender;
{
    [self.navigationPaneViewController setPaneState:MSNavigationPaneStateOpen animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"masterViewControllerCellReuseIdentifier"];
    PGPaneViewControllerType paneViewControllerType = [self paneViewControllerTypeForIndexPath:indexPath];
    cell.textLabel.text = self.paneViewControllerTitles[@(paneViewControllerType)];
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PGPaneViewControllerType paneViewControllerType = [self paneViewControllerTypeForIndexPath:indexPath];
    [self transitionToViewController:paneViewControllerType];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
