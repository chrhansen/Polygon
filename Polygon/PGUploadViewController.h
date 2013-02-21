//
//  SelectActionTableViewController.h
//  FEViewer2
//
//  Created by Christian Hansen on 16/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PGModel;

@interface PGUploadViewController : UITableViewController

@property (nonatomic, strong) PGModel *model;
@property (weak, nonatomic) IBOutlet UISwitch *zipSwitch;

@end
