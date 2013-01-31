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
        @(PGPaneViewControllerTypeOther1) : @"Other 1",
        @(PGPaneViewControllerTypeOther2) : @"Other 2"
        };
        self.paneViewControllerIdentifiers = @{
        @(PGPaneViewControllerTypeModels) : @"modelsCollectionViewController",
        @(PGPaneViewControllerTypeDropbox) : @"dropboxViewController",
        @(PGPaneViewControllerTypeOther1) : @"otherViewController",
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PGPaneViewControllerType paneViewControllerType = [self paneViewControllerTypeForIndexPath:indexPath];
    [self transitionToViewController:paneViewControllerType];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
