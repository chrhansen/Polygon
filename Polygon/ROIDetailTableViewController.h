//
//  ROIDetalTableViewController.h
//  Polygon
//
//  Created by Christian Hansen on 28/06/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ROI3D.h"

@class ROIViewController;

@protocol ROIDetailTableViewControllerDelegate <NSObject>

- (void)didSaveROI:(ROI3D *)aROI sender:(id)sender;
- (void)didEditROI:(ROI3D *)updatedROI sender:(id)sender;

@end

@interface ROIDetailTableViewController : UITableViewController

@property (nonatomic, strong) ROI3D *roi;
@property (weak, nonatomic) IBOutlet UITextView *titleTextView;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) id<ROIDetailTableViewControllerDelegate> delegate;
@property (nonatomic) BOOL showKeyboard;
@property (weak, nonatomic) IBOutlet UINavigationBar *addROINavigationBar;

@end
