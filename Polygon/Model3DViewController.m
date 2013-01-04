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
#import "PGView+Management.h"

@interface Model3DViewController () <NGLViewDelegate, NGLMeshDelegate, ViewsTableViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NGLMesh *mesh;
@property (nonatomic, strong) NGLCamera *camera;
@property (nonatomic) CGPoint panTranslation;
@property (nonatomic) CGPoint xyRotation;
@property (nonatomic) CGFloat zRotation;
@property (nonatomic) CGFloat lastPinch;
@property (nonatomic) CGFloat pinchScale;

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
	[self _addGestureRecognizers];
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


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Views"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        [(ViewsTableViewController *)navigationController.topViewController setModel:self.model];
        [(ViewsTableViewController *)navigationController.topViewController setDelegate:self];
    }
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

#pragma mark - Views Table View Controller Delegate
- (PGView *)viewsTableViewController:(ViewsTableViewController *)viewsTableViewController currentViewForModel:(PGModel *)model
{
    NGLvec3 *position = _camera.position;
    NGLvec3 *rotation = _camera.rotation;

    PGView *currentView = [PGView createWithLocationX:position->x locationY:position->y locationZ:position->z
                                          quaternionX:rotation->x quaternionY:rotation->y quaternionZ:rotation->z
                                          quaternionW:-1.0f screenShot:[self currentViewAsModelScreenshot]];
    return currentView;
}


- (void)viewsTableViewController:(ViewsTableViewController *)viewsTableViewController didSelectView:(PGView *)savedView
{
    
}


#pragma mark -
#pragma mark - Gesture recognizers
- (void)_addGestureRecognizers
{
    UIPanGestureRecognizer *panMoveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panMoveGesture.minimumNumberOfTouches = 1;
    panMoveGesture.maximumNumberOfTouches = 2;
    [self.view  addGestureRecognizer:panMoveGesture];
    [panMoveGesture setDelegate:self];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view  addGestureRecognizer:pinchGesture];
    [pinchGesture setDelegate:self];
    
    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationGesture:)];
    [self.view  addGestureRecognizer:rotationGesture];
    [rotationGesture setDelegate:self];
    
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    [singleTapGesture setDelegate:self];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapGesture];
    [doubleTapGesture setDelegate:self];
    
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
}

# pragma mark - Gesture actions
- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
    if ((panGesture.state == UIGestureRecognizerStateChanged ||
         panGesture.state == UIGestureRecognizerStateEnded)) {
        if(panGesture.numberOfTouches == 2)
        {
            _panTranslation = [panGesture translationInView:self.view] ;
            [panGesture setTranslation:CGPointZero inView:self.view];
        }
        else if(panGesture.numberOfTouches == 1)
        {
            [self addVelocitySample:[panGesture translationInView:self.view]];
            [panGesture setTranslation:CGPointZero inView:self.view];
        }
    }
}

#define PREVIOUSWEIGHT 0.75f

- (void)addVelocitySample:(CGPoint)velocitySample
{
    _xyRotation.x *= PREVIOUSWEIGHT;
    _xyRotation.y *= PREVIOUSWEIGHT;
    _xyRotation.x += (1 - PREVIOUSWEIGHT) * velocitySample.x;
    _xyRotation.y += (1 - PREVIOUSWEIGHT) * velocitySample.y;
}

-(void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGesture
{
    switch (pinchGesture.state)
    {
        case UIGestureRecognizerStateBegan:
            _lastPinch = 1.0;
            _pinchScale = 1.0;
            break;
            
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self addPinchVelocitySample:pinchGesture.scale];
            break;
            
        default:
            break;
    }
}

- (void)addPinchVelocitySample:(CGFloat)pinchVelocitySample
{
    _pinchScale *= PREVIOUSWEIGHT;
    _pinchScale += (1.0f - PREVIOUSWEIGHT) * pinchVelocitySample;
}

#define RADIANS_TO_DEGREES 57.2957805


-(void)handleRotationGesture:(UIRotationGestureRecognizer *)rotationGesture
{
    switch (rotationGesture.state)
    {
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            _zRotation = - 2.0f * rotationGesture.rotation;
            rotationGesture.rotation = 0.0;
            break;
            
        default:
            break;
    }
}


- (void)handleSingleTapGesture:(UITapGestureRecognizer *)singleTapGesture
{
    if (singleTapGesture.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"single tap gesture");
    }
}


- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)doubleTapGesture
{
    if (doubleTapGesture.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"double tap gesture");
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
