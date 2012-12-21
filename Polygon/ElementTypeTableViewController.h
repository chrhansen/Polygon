//
//  ElementTypeTableViewController.h
//  FEViewer2
//
//  Created by Christian Hansen on 23/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ElementTypeTableViewControllerDelegate <NSObject>

- (void)solidTypeWasChanged:(UISwitch *)sender;
- (void)shellTypeWasChanged:(UISwitch *)sender;
- (void)beamTypeWasChanged:(UISwitch *)sender;
- (void)edgesWasChanged:(UISwitch *)sender;
- (void)nodeWasChanged:(UISwitch *)sender;

@end

@interface ElementTypeTableViewController : UITableViewController

//- (IBAction)viewModeAction:(id)sender;
- (IBAction)solidAction:(id)sender;
- (IBAction)shellAction:(id)sender;
- (IBAction)beamAction:(id)sender;
- (IBAction)edgeAction:(id)sender;
- (IBAction)nodeAction:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *solidElements;
@property (weak, nonatomic) IBOutlet UISwitch *shellElements;
@property (weak, nonatomic) IBOutlet UISwitch *beamElements;
@property (weak, nonatomic) IBOutlet UISwitch *nodes;
@property (weak, nonatomic) IBOutlet UISwitch *edges;


@property (weak, nonatomic) id<ElementTypeTableViewControllerDelegate> delegate;

@end
