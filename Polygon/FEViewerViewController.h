//
//  FEViewerViewController.h
//  FEViewer2
//
//  Created by Christian Hansen on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModelViewController.h"
#import "Structs.h"


@interface FEViewerViewController : GLKViewController <ModelViewControllerProtocol>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButton;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (nonatomic, strong) PGModel *model;
@property (nonatomic, weak) id<ModelViewControllerDelegate> modelViewDelegate;

@end
