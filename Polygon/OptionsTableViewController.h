//
//  OptionsTableViewController.h
//  FEViewer2
//
//  Created by Christian Hansen on 07/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OptionsTableViewControllerDelegate <NSObject>

- (void)perspectiveOrthoWasChanged:(UISegmentedControl *)sender;

@end

@interface OptionsTableViewController : UITableViewController
- (IBAction)viewModeAction:(id)sender;

@property (weak, nonatomic) IBOutlet UISegmentedControl *perspectiveOrthoSegmentedControl;
@property (weak, nonatomic) id<OptionsTableViewControllerDelegate> delegate;

@end
