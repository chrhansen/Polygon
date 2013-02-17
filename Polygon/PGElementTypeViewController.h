//
//  PGElementTypeViewController.h
//  Polygon
//
//  Created by Christian Hansen on 17/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PGElementTypeDelegate <NSObject>

- (void)solidTypeWasChanged:(UISwitch *)sender;
- (void)shellTypeWasChanged:(UISwitch *)sender;
- (void)beamTypeWasChanged:(UISwitch *)sender;
- (void)edgesWasChanged:(UISwitch *)sender;

@end

@interface PGElementTypeViewController : UIViewController

//- (IBAction)viewModeAction:(id)sender;
- (IBAction)solidAction:(id)sender;
- (IBAction)shellAction:(id)sender;
- (IBAction)beamAction:(id)sender;
- (IBAction)edgeAction:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *solidElements;
@property (weak, nonatomic) IBOutlet UISwitch *shellElements;
@property (weak, nonatomic) IBOutlet UISwitch *beamElements;
@property (weak, nonatomic) IBOutlet UISwitch *edges;


@property (weak, nonatomic) id<PGElementTypeDelegate> delegate;

@end
