//
//  FEViewerViewController.h
//  FEViewer2
//
//  Created by Christian Hansen on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModelViewController.h"
#import "Structs.h"


@interface FEViewerViewController : ModelViewController


- (IBAction)doneTapped:(UIBarButtonItem *)sender;
- (IBAction)viewsTapped:(UIBarButtonItem *)sender;


- (IBAction)tool1Tapped:(id)sender;
- (IBAction)tool2Tapped:(id)sender;
- (IBAction)tool3Tapped:(id)sender;
- (IBAction)tool4Tapped:(id)sender;
- (IBAction)tool5Tapped:(id)sender;
 
@property (weak, nonatomic) IBOutlet UIView *toolView;

@end
