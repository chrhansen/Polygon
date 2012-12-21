//
//  ColorTableViewController.h
//  Polygon
//
//  Created by Christian Hansen on 5/30/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ColorTableViewControllerDelegate <NSObject>

@optional
- (void)transparencyChanged:(UISlider *)sender; // values between 0.0 and 1.0
- (void)colorTypeChanged:(UISegmentedControl *)sender;

@end

@interface ColorTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISlider *transparencySlider;
@property (weak, nonatomic) IBOutlet UISegmentedControl *colorTypeSegment;
@property (weak, nonatomic) id<ColorTableViewControllerDelegate> delegate;
@end
