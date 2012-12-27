//
//  Model3DViewController.m
//  Polygon
//
//  Created by Christian Hansen on 16/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "Model3DViewController.h"
#import "PGModel+Management.h"
#import <NinevehGL/NinevehGL.h>
#import "ViewsTableViewController.h"
#import "TSPopoverController.h"

@interface Model3DViewController () <NGLViewDelegate, NGLMeshDelegate>

@property (nonatomic, strong) NGLMesh *mesh;
@property (nonatomic, strong) NGLCamera *camera;

@end

@implementation Model3DViewController

- (void) loadView
{
	// Following the UIKit specifications, this method should not call the super.
	
	// Creates the NGLView manually, with the screen's size and sets the delegate.
	NGLView *nglView = [[NGLView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	nglView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	nglView.delegate = self;
	
	// Sets the NGLView as the root view of this View Controller hierarchy.
	self.view = nglView;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.multipleTouchEnabled = YES;
	
	//*************************
	//	NinevehGL Stuff
	//*************************
	// Setting up some global adjusts.
	nglGlobalColor((NGLvec4){123.0f/256.0f, 170.0f/256.0f, 239.0f/256.0f, 1.0f});
	nglGlobalLightEffects(NGLLightEffectsOFF);
	
	// Importing the Island mesh.
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
							  @"1.0", kNGLMeshKeyNormalize,
                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize,
							  nil];
	
	_mesh = [[NGLMesh alloc] initWithFile:self.model.fullModelFilePath settings:settings delegate:self];
	
	// Initializing the camera and placing it into a good initial position.
	_camera = [[NGLCamera alloc] initWithMeshes:_mesh, nil];
	_camera.z = 2.0;
	//_camera.rotateX = 8;
}


- (void) drawView
{
	//*************************
	//	NinevehGL Stuff
	//*************************
	// Getting the scalar movement from the controls.
//	NGLvec2 trans = _left.movement;
//	NGLvec2 pan = _right.movement;
	
	// Updating the camera rotations.
//	_camera.rotateX += pan.x;
//	_camera.rotateY -= pan.y;
	
	// Updating the camera movement.
//	[_camera translateRelativeToX:0 toY:-0.001 toZ:-0.001];
	[_mesh rotateRelativeToX:0.3 toY:0.3 toZ:0];
	
	[_camera drawCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)viewsTapped:(UIBarButtonItem *)barButton
{
    CGPoint popoverLocation = CGPointMake(30, 22);
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"viewsTableViewControllerNavigationController"];
    navigationController.view.frame = CGRectMake(0,0, 280, 350);

    ViewsTableViewController *viewsTableViewController = (ViewsTableViewController *)navigationController.topViewController;
    viewsTableViewController.model = self.model;
    TSPopoverController *popoverController = [[TSPopoverController alloc] initWithContentViewController:navigationController];
//    if (!self.navigationController.navigationBar.hidden) popoverLocation.y += self.navigationController.navigationBar.bounds.size.height;
    popoverLocation.y += [UIApplication sharedApplication].statusBarFrame.size.height;
    popoverController.arrowPosition = TSPopoverArrowPositionVertical;
    [popoverController showPopoverWithRect:CGRectMake(popoverLocation.x, popoverLocation.y, 1, 1)];
}

- (IBAction)doneTapped:(UIBarButtonItem *)sender
{
    [(NGLView *)self.view setDelegate:nil];
    [self.modelViewDelegate modelViewController:self didTapDone:[self currentViewAsModelScreenshot] model:self.model];
}


- (UIImage *)currentViewAsModelScreenshot
{
    return [(NGLView *)self.view drawToImage];
}

@end
