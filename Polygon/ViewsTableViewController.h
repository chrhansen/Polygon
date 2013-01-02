//
//  ViewsTableViewController.h
//  Polygon
//
//  Created by Christian Hansen on 6/27/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PGViewDetailTableViewController.h"

@class ViewsTableViewController, PGModel, PGView;

@protocol ViewsTableViewControllerDelegate <NSObject>

- (PGView *)viewsTableViewController:(ViewsTableViewController *)viewsTableViewController currentViewForModel:(PGModel *)model;
- (void)viewsTableViewController:(ViewsTableViewController *)viewsTableViewController didSelectView:(PGView *)savedView;

@end

@interface ViewsTableViewController : UITableViewController <PGViewDetailTableViewControllerDelegate>

@property (nonatomic, weak) id<ViewsTableViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *roisFilePath;
@property (nonatomic, strong) NSMutableArray *rois;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButtonItem;
@property (nonatomic, strong) PGModel *model;

@end
