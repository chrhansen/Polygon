//
//  ROIDetalTableViewController.h
//  Polygon
//
//  Created by Christian Hansen on 28/06/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ROIViewController, PGView, PGViewDetailTableViewController;

@protocol PGViewDetailTableViewControllerDelegate <NSObject>

- (void)viewDetailTableViewController:(PGViewDetailTableViewController *)viewDetailTableViewController didSaveView:(PGView *)savedView;

@end

@interface PGViewDetailTableViewController : UITableViewController

@property (nonatomic, strong) PGView *savedView;

@property (weak, nonatomic) IBOutlet UITextView *titleTextView;
@property (weak, nonatomic) IBOutlet UIImageView *screenshotImageView;
@property (nonatomic) BOOL isEditingExistingViewViewController;
@property (weak, nonatomic) id<PGViewDetailTableViewControllerDelegate> delegate;

@end
