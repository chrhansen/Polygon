//
//  Model3DViewController.h
//  Polygon
//
//  Created by Christian Hansen on 16/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ModelViewController.h"

@class PGModel;

@interface PG3DModelViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButton;
@property (nonatomic, strong) PGModel *model;
@property (nonatomic, weak) id<ModelViewControllerDelegate> modelViewDelegate;

@end
