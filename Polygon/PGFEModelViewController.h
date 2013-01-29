//
//  FEViewerViewController.h
//  FEViewer2
//
//  Created by Christian Hansen on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGModelViewController.h"
#import "Structs.h"


@interface PGFEModelViewController : GLKViewController <PGModelViewControllerProtocol>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButton;
@property (weak, nonatomic) IBOutlet UIView *toolView;
@property (nonatomic, strong) PGModel *model;
@property (nonatomic, weak) id<PGModelViewControllerDelegate> modelViewDelegate;

@end
