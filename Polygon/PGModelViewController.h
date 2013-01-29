//
//  ModelViewController.h
//  Polygon
//
//  Created by Christian Hansen on 16/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PGModel, PGView;

@protocol PGModelViewControllerDelegate <NSObject>

- (void)modelViewController:(id)sender didTapDone:(UIImage *)screenshot model:(PGModel *)model;

@end

@protocol PGModelViewControllerProtocol <NSObject>

- (IBAction)doneTapped:(UIBarButtonItem *)sender;
- (IBAction)viewsTapped:(UIBarButtonItem *)sender;

- (IBAction)tool1Tapped:(id)sender;
- (IBAction)tool2Tapped:(id)sender;
- (IBAction)tool3Tapped:(id)sender;
- (IBAction)tool4Tapped:(id)sender;
- (IBAction)tool5Tapped:(id)sender;

@end
