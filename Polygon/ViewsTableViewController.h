//
//  ViewsTableViewController.h
//  Polygon
//
//  Created by Christian Hansen on 6/27/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ROIDetailTableViewController.h"

@class ViewsTableViewController, PGModel;

@protocol ViewsTableViewControllerDelegate <NSObject>

- (NSString *)directoryForROIList:(ViewsTableViewController *)sender;
- (ROI3D *)currentROI:(ViewsTableViewController *)sender;
- (UIImage *)currentSnapshot:(ViewsTableViewController *)sender;

- (void)didSelectROI:(ROI3D *)aRoi;

@end

@interface ViewsTableViewController : UITableViewController <ROIDetailTableViewControllerDelegate>

- (IBAction)addROI:(UIBarButtonItem *)sender;

@property (nonatomic, weak) id<ViewsTableViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *roisFilePath;
@property (nonatomic, strong) NSMutableArray *rois;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButtonItem;
@property (nonatomic, strong) PGModel *model;

@end
