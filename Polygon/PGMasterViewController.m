//
//  PGMasterViewController.m
//  Polygon
//
//  Created by Christian Hansen on 28/01/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import "PGMasterViewController.h"
#import "ATConnect.h"
#import "ATSurveys.h"

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
        self.paneViewControllerTitles      = @{@(PGPaneViewControllerTypeModels)   : @"Models",
                                               @(PGPaneViewControllerTypeDropbox)  : @"Dropbox",
                                               @(PGPaneViewControllerTypeStore)    : @"Store"};
        self.paneViewControllerIdentifiers = @{@(PGPaneViewControllerTypeModels)   : @"modelsCollectionViewController",
                                               @(PGPaneViewControllerTypeDropbox)  : @"dropboxViewController",
                                               @(PGPaneViewControllerTypeStore)    : @"storeViewController"};
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationPaneViewController setAppearanceType:MSNavigationPaneAppearanceTypeParallax];
    self.tableView.scrollsToTop = NO;
    [self.navigationController.navigationBar setHidden:NO];
    [self _observeApptentiveSurveys];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Apptentive
- (void)_observeApptentiveSurveys
{    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(surveyBecameAvailable:)
                                                 name:ATSurveyNewSurveyAvailableNotification object:nil];
    [ATSurveys checkForAvailableSurveys];
}

- (void)surveyBecameAvailable:(NSNotification *)notification {
    // Present survey here as appropriate.
    // For example, automatically show the survey:
    [ATSurveys presentSurveyControllerFromViewController:self];
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


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PGPaneViewControllerType paneViewControllerType = [self paneViewControllerTypeForIndexPath:indexPath];
    if (paneViewControllerType == PGPaneViewControllerTypeFeedback) {
        ATConnect *connection = [ATConnect sharedConnection];
        [connection presentFeedbackControllerFromViewController:self];
    } else {
        [self transitionToViewController:paneViewControllerType];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
