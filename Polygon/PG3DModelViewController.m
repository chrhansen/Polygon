//
//  Model3DViewController.m
//  Polygon
//
//  Created by Christian Hansen on 16/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PG3DModelViewController.h"
#import "PGModel+Management.h"
#import <NinevehGL/NinevehGL.h>
#import "PGViewsTableViewController.h"
#import "TSPopoverController.h"
#import "PGView+Management.h"

@interface PG3DModelViewController () <NGLViewDelegate, NGLMeshDelegate, ViewsTableViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NGLCamera *camera;
@property (nonatomic) BOOL shouldCreateScreenShot;
@property (nonatomic) CGPoint panTranslation;
@property (nonatomic) CGPoint xyRotation;
@property (nonatomic) CGFloat zRotation;
@property (nonatomic) CGFloat pinchScale;
@property (nonatomic) CGFloat initialCameraDistanceZ;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end

@implementation PG3DModelViewController

- (void) loadView
{
	NGLView *nglView = [[NGLView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	nglView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	nglView.delegate = self;
	nglView.contentScaleFactor = 1.5f;
//    nglView.antialias = NGLAntialias4X;
    nglGlobalColor((NGLvec4){123.0f/256.0f, 170.0f/256.0f, 239.0f/256.0f, 1.0f});
	nglGlobalLightEffects(NGLLightEffectsON);
    nglGlobalFPS(60);
	nglGlobalFrontAndCullFace(NGLFrontFaceCCW, NGLCullFaceNone);
    nglGlobalMultithreading(NGLMultithreadingParser);

    nglGlobalFlush();

	self.view = nglView;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setTranslucent:YES];
    self.title = self.model.filePath.lastPathComponent;
    _shouldCreateScreenShot = NO;
    [self _addGestureRecognizers];
    
    NGLMesh *mesh = [self _loadMesh];
    if (mesh) {
        [self _startCameraWithMesh:mesh];
    } else {
        NSLog(@"Error: Couldn't initialize mesh");
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _hideStatusBar];
}


- (void)dealloc
{
    
}

- (NGLMesh *)_loadMesh
{
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
							  @"1.0", kNGLMeshKeyNormalize,
                              kNGLMeshCentralizeYes, kNGLMeshKeyCentralize, nil];
    NGLMesh *modelMesh = [[NGLMesh alloc] initWithFile:self.model.fullModelFilePath settings:settings delegate:self];
    modelMesh.rotationSpace = NGLRotationSpaceWorld;
	return modelMesh;
}


- (void)_startCameraWithMesh:(NGLMesh *)mesh
{
    _initialCameraDistanceZ = 2.0;
    _pinchScale = 1.0f;
	_camera = [[NGLCamera alloc] initWithMeshes:mesh, nil];
    [_camera autoAdjustAspectRatio:YES animated:YES];
    _camera.z = _initialCameraDistanceZ * 1.0f / _pinchScale;
}




- (void)_hideStatusBar
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}


- (void)drawView
{    
    [_camera moveRelativeTo:NGLMoveRight distance:self.panTranslation.x/self.view.bounds.size.width*0.8];
    [_camera moveRelativeTo:NGLMoveUp distance:-self.panTranslation.y/self.view.bounds.size.height];
    _camera.z = _initialCameraDistanceZ / _pinchScale;
    
    NGLMesh *mesh = [_camera.allMeshes lastObject];
    [mesh rotateRelativeToX:_xyRotation.y toY:_xyRotation.x toZ:-_zRotation];
    
	[_camera drawCamera];
    
    if (_shouldCreateScreenShot) {
        UIImage *screenshot = [(NGLView *)self.view drawToImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self ninevehGLDidCreateScreenshot:screenshot];
        });
        _shouldCreateScreenShot = NO;
    }
    [self _resetTranslationsAndRotations];
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
        [(PGViewsTableViewController *)navigationController.topViewController setModel:self.model];
        [(PGViewsTableViewController *)navigationController.topViewController setDelegate:self];
    }
}

- (IBAction)doneTapped:(UIBarButtonItem *)sender
{
    NGLView *nglView = (NGLView *)self.view;
    nglView.antialias = NGLAntialiasNone;
    _shouldCreateScreenShot = YES;
}


#pragma mark Call back from the render thread when screenshot has been created
- (void)ninevehGLDidCreateScreenshot:(UIImage *)screenshot
{
    [(NGLView *)self.view setDelegate:nil];
    [self.modelViewDelegate modelViewController:self didTapDone:screenshot model:self.model];
}

- (void)_resetTranslationsAndRotations
{
    _panTranslation = CGPointZero;
    _xyRotation = CGPointZero;
    _zRotation = 0.0f;
}


#pragma mark NGLMeshloading Delegate
- (void) meshLoadingWillStart:(NGLParsing)parsing
{
    self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    self.progressHUD.progress = 0.0f;
    self.progressHUD.mode = MBProgressHUDModeAnnularDeterminate;
    self.progressHUD.labelText = @"Loading";
    [self.view addSubview:self.progressHUD];
}

- (void) meshLoadingProgress:(NGLParsing)parsing
{
    self.progressHUD.progress = parsing.progress;
}

- (void) meshLoadingDidFinish:(NGLParsing)parsing
{
    self.progressHUD.progress = parsing.progress;
	[self.progressHUD hide:YES];
}


#pragma mark - Views Table View Controller Delegate
- (PGView *)viewsTableViewController:(PGViewsTableViewController *)viewsTableViewController currentViewForModel:(PGModel *)model
{
    NGLvec3 *position = _camera.position;
    NGLvec3 *rotation = _camera.rotation;
    
    PGView *currentView = [PGView createWithLocationX:position->x locationY:position->y locationZ:position->z
                                          quaternionX:rotation->x quaternionY:rotation->y quaternionZ:rotation->z quaternionW:-1.0f
                                           screenShot:nil]; // TODO: create callback/selector or equiv. to get screenshot for saved views
    return currentView;
}


- (void)viewsTableViewController:(PGViewsTableViewController *)viewsTableViewController didSelectView:(PGView *)savedView
{
    NSLog(@"didSelectView: %@", savedView);
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
    [self.view addGestureRecognizer:singleTapGesture];
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
    if (!self.navigationController.navigationBar.isHidden) [self _hideNavigationBar:YES];
    
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
    _xyRotation.x += (1.0f - PREVIOUSWEIGHT) * velocitySample.x;
    _xyRotation.y += (1.0f - PREVIOUSWEIGHT) * velocitySample.y;
}

-(void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGesture
{
    switch (pinchGesture.state) {
        case UIGestureRecognizerStateBegan:
            _initialCameraDistanceZ = _camera.z;
            _pinchScale = pinchGesture.scale;
            break;
            
        case UIGestureRecognizerStateChanged:
            _pinchScale = pinchGesture.scale;
            break;

        case UIGestureRecognizerStateEnded:
            _initialCameraDistanceZ = _camera.z;
            _pinchScale = 1.0f;
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
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            _zRotation = [rotationGesture rotation] * RADIANS_TO_DEGREES;
            [rotationGesture setRotation:0.0f];
            break;
            
        default:
            break;
    }
}

- (void)addZRotatinSample:(CGFloat)rotationSample
{
    _zRotation *= PREVIOUSWEIGHT;
    _zRotation += (1.0f - PREVIOUSWEIGHT) * rotationSample;
}

- (void)handleSingleTapGesture:(UITapGestureRecognizer *)singleTapGesture
{
    if (singleTapGesture.state == UIGestureRecognizerStateEnded) {
        [self _hideNavigationBar:!self.navigationController.navigationBar.isHidden];
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

- (void)_hideNavigationBar:(BOOL)shouldHide
{
    UINavigationBar *navBar = self.navigationController.navigationBar;
    CGFloat endAlpha = 0.0f;
    if (!shouldHide) {
        endAlpha = 1.0f;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
    }
    
    [UIView animateWithDuration:0.2f
                     animations:^{navBar.alpha = endAlpha;}
                     completion:^(BOOL finished){ [self.navigationController setNavigationBarHidden:shouldHide animated:NO];
                     }];
}

@end
