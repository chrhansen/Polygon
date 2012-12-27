//
//  ModelViewController.h
//  Polygon
//
//  Created by Christian Hansen on 16/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class PGModel;

@protocol ModelViewControllerDelegate <NSObject>

- (void)modelViewController:(id)sender didTapDone:(UIImage *)screenshot model:(PGModel *)model;

@end

@protocol ModelViewControllerProtocol <NSObject>

- (IBAction)doneTapped:(UIBarButtonItem *)sender;
- (IBAction)viewsTapped:(UIBarButtonItem *)sender;

- (IBAction)tool1Tapped:(id)sender;
- (IBAction)tool2Tapped:(id)sender;
- (IBAction)tool3Tapped:(id)sender;
- (IBAction)tool4Tapped:(id)sender;
- (IBAction)tool5Tapped:(id)sender;

@end
