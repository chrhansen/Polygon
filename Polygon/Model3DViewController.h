//
//  Model3DViewController.h
//  Polygon
//
//  Created by Christian Hansen on 16/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ModelViewController.h"

@class FEModel;

@interface Model3DViewController : UIViewController

- (IBAction)doneTapped:(UIBarButtonItem *)sender;

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButton;
@property (nonatomic, strong) FEModel *feModel;

@end
