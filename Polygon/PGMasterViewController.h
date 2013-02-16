//
//  PGMasterViewController.h
//  Polygon
//
//  Created by Christian Hansen on 28/01/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MSNavigationPaneViewController.h"

typedef NS_ENUM(NSUInteger, PGPaneViewControllerType) {
    PGPaneViewControllerTypeModels,
    PGPaneViewControllerTypeDropbox,
    PGPaneViewControllerTypeStore
};

@interface PGMasterViewController : UITableViewController

@property (nonatomic, assign) PGPaneViewControllerType paneViewControllerType;
@property (nonatomic, weak) MSNavigationPaneViewController *navigationPaneViewController;

- (void)transitionToViewController:(PGPaneViewControllerType)paneViewControllerType;

@end
