//
//  FEViewerViewController.m
//  FEViewer2
//
//  Created by Christian Hansen on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define PI_2 1.570796327
#define PI 3.141592653
#define ROT 6.283185306

#import "PGFEModelViewController.h"
#import "PGModel+Management.h"
#import "AnsysModel.h"
#import "BackgroundVertices.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Resize.h"
#import "PGElementTypeViewController.h"
#import "PGTransparencyViewController.h"
#import "PGViewsTableViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "UIImage+RoundedCorner.h"
#import "PGView+Management.h"
#import "UIBarButtonItem+Customview.h"
#import "PopoverView.h"

@interface PGFEModelViewController ()  <UIGestureRecognizerDelegate, UIPopoverControllerDelegate, AnsysModelDelegate, PGElementTypeDelegate, PGTransparencyDelegate, MBProgressHUDDelegate, UIActionSheetDelegate, ViewsTableViewControllerDelegate, PopoverViewDelegate>
{    
    NSArray *_names;
    NSArray *_paths;
    
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelViewMatrix;
    GLKMatrix4 _backgroundModelViewMatrix;
    GLKMatrix4 _modelMatrix;
    GLKMatrix4 _viewMatrix;
    GLKMatrix4 viewRotationOffsetMatrix;
    GLKMatrix4 viewRotationMatrix;
    GLKMatrix4 viewTranslateMatrix;
    GLKVector3 _cameraPosition;
    GLKMatrix3 normalMatrix;
    GLKVector3 rotVector;
    GLKVector4 startVector;
    GLKVector4 endVector;
    float rotation;
    CGFloat lastPinch;
    float _farZ;
    float orthoSideLength;
    float initialOrthoSidelength;
    float _animationTime;
    CGFloat lastDistance;
    CGFloat _orientationScale;
    
    // Rotate animation
    BOOL _runRotationAnimation;
    float _slerpCur;
    float _slerpMax;
    GLKQuaternion _slerpStart;
    GLKQuaternion _slerpEnd;
    
    // Position animation
    BOOL _runPositionAnimation;
    float _lerpPosCur;
    float _lerpPosMax;
    GLKVector3 _lerpStart;
    GLKVector3 _lerpEnd;
    
    GLuint backgroundVertexBuffer;
    GLuint backgroundVertexArray;     
    
    GLuint solidCubeVertexBuffer;
    GLuint solidCubeVertexArray;
    
    GLuint solidPrismVertexBuffer;
    GLuint solidPrismVertexArray;
    
    GLuint solidTetraVertexBuffer;
    GLuint solidTetraVertexArray;
    
    GLuint facesVertexBuffer;
    GLuint facesVertexArray; 

    GLuint beamIndexBuffer;
    GLuint beamIndexArray;
    
    GLuint edgeVertexBuffer;
    GLuint edgeVertexArray;
    
    GLuint allVertexBuffer;
    GLuint allVertexArray;
    
    BoundingBox boundingBox;
    AnsysModel *_anAnsysModel;   
}


@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, strong) UIPopoverController *thePopoverController;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) GLKTextureInfo *background;
@property (strong, nonatomic) GLKSkyboxEffect *skyboxEffect;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic) BOOL readingModelData;
@property (nonatomic) float progress;

@property (nonatomic) CGPoint myRotation;
@property (nonatomic) CGPoint panTranslation;
@property (nonatomic) CGFloat zRotation;
@property (nonatomic) CGFloat pinchScale;
@property (nonatomic) NSInteger activeGestures;
@property (nonatomic) BOOL isPerpective;
@property (nonatomic) BOOL plotSolids;
@property (nonatomic) BOOL plotShells;
@property (nonatomic) BOOL plotBeams;
@property (nonatomic) BOOL plotEdges;
@property (nonatomic) BOOL plotNodes;
@property (nonatomic) CGFloat elementTransparency;
@property (nonatomic) NSUInteger colorType;
@property (nonatomic, strong) PopoverView *popoverView;
@property (nonatomic, strong) UIViewController *popoverContentViewController;

@end

@implementation PGFEModelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(bigModelLimitPassed:) name:PolygonModelTypeNotPurchased object:nil];
    self.title = self.model.filePath.lastPathComponent;
    [self.navigationController.navigationBar setTranslucent:YES];
    [self _configureToolBarButtonItems];
    [self setupBasicGL];
    [self makeGradientBackground];
    [self loadModelFile];
    [self _setToolBarTransparent];
    self.isPerpective = ![[NSUserDefaults standardUserDefaults] boolForKey:@"UserDefaults_PerspectiveView"];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _hideStatusBar];    
}


- (void)dealloc
{
    [self tearDownGL];

    if ([EAGLContext currentContext] == self.context) [EAGLContext setCurrentContext:nil];
	self.context = nil;
    _anAnsysModel = nil;
    [self setDoneBarButton:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


- (void)_hideStatusBar
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}


- (void)_setToolBarTransparent
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.toolbar setBackgroundImage:transparentImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
}

- (void)updateOrientationDependantValues:(UIInterfaceOrientation)newOrientation
{
    if (UIInterfaceOrientationIsLandscape(newOrientation)) {
        _orientationScale = 1.0f;
    } else if (UIInterfaceOrientationIsPortrait(newOrientation)) {
        _orientationScale = 0.5f;
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
    {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } 
    else 
    {
        [self updateOrientationDependantValues:interfaceOrientation];
        return YES;
    }
}


- (void)didReceiveMemoryWarning
{
    NSLog(@"Memory warning for model: %@", self.model.fullModelFilePath);
    [super didReceiveMemoryWarning];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Views"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        [(PGViewsTableViewController *)navigationController.topViewController setDelegate:self];
        [(PGViewsTableViewController *)navigationController.topViewController setModel:self.model];
    }
}


- (void)_configureToolBarButtonItems
{
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *elemTypeBarButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0159"] style:UIBarButtonItemStylePlain target:self action:@selector(elementTypeTapped:)];
    UIBarButtonItem *transparencyBarButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"62-contrast"] style:UIBarButtonItemStylePlain target:self action:@selector(transparencyTapped:)];
    UIBarButtonItem *lookAtBarButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0219"] style:UIBarButtonItemStylePlain target:self action:@selector(lookAtTapped:)];
    UIBarButtonItem *orthoPerspBarButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0206"] style:UIBarButtonItemStylePlain target:self action:@selector(orthoPerspectiveTapped:)];
    UIBarButtonItem *resetBarButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0300"] style:UIBarButtonItemStylePlain target:self action:@selector(animateToReset)];
    [self setToolbarItems:@[flexibleSpace, elemTypeBarButton, transparencyBarButton, lookAtBarButton, orthoPerspBarButton, resetBarButton, flexibleSpace]];
}

- (void)loadModelFile
{
    _anAnsysModel = nil;
    self.readingModelData = YES;
    [self showAnnularProgressHUD];
    self.elementTransparency = 1.0;
    NSDictionary *initialSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:self.elementTransparency], @"transparency", nil];
    if (!self.model.fullModelFilePath) {
        return;
    }
    NSString *modelPath = [self.model.fullModelFilePath copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _anAnsysModel = [AnsysModel ansysFileWithPath:modelPath andDelegate:self andSettings:initialSettings];
        if (_anAnsysModel) {
            boundingBox = _anAnsysModel.boundingBox[0];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadModelDataToGL];
                self.readingModelData = NO;
                [self _addGestureRecognizers];
                [self animateToReset];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.readingModelData = NO;
            });
        }
    });
}


- (void)setupBasicGL
{
    rotation = 0.0;
    lastPinch = 1.0;
    self.pinchScale = 1.0;
    self.panTranslation = CGPointZero;
    rotVector = GLKVector3Make(1.0, 1.0, 1.0);
    viewRotationOffsetMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, 0.0f); 
    viewRotationMatrix = GLKMatrix4Identity;
    boundingBox.lengthMax = 10.0;
    _backgroundModelViewMatrix = GLKMatrix4MakeTranslation(0, 0, -5);
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) NSLog(@"Failed to create ES context");

    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24; // check resolution
    view.drawableMultisample = GLKViewDrawableMultisample4X;//GLKViewDrawableMultisample4X;
    
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    // Set material
    self.effect.colorMaterialEnabled = GL_TRUE;
    self.effect.material.diffuseColor = GLKVector4Make(159.0/256.0f,182.0/256.0f,205.0/256.0f, 1.0f);
    self.effect.material.shininess = 20;
    
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);;
    self.effect.light0.position = GLKVector4Make(1.0f, -0.5f, 1.0f, 1.0f);
    self.effect.lightingType = GLKLightingTypePerVertex;    
    
    self.effect.lightModelTwoSided = GL_TRUE;
    
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
}

- (void)loadModelDataToGL
{
    orthoSideLength = boundingBox.lengthMax;
    _modelMatrix = GLKMatrix4MakeTranslation(-boundingBox.offset.x, -boundingBox.offset.y, -boundingBox.offset.z);

    viewTranslateMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, +boundingBox.lengthMax);
    _cameraPosition = GLKVector3Make(viewTranslateMatrix.m30, viewTranslateMatrix.m31, viewTranslateMatrix.m32);
      
    //---- Solids Vertex Array Objects --------
    
    glGenVertexArraysOES(1, &solidCubeVertexArray);
    glGenBuffers(1, &solidCubeVertexBuffer);
    
    glGenVertexArraysOES(1, &solidPrismVertexArray);
    glGenBuffers(1, &solidPrismVertexBuffer);
    
    glGenVertexArraysOES(1, &solidTetraVertexArray);
    glGenBuffers(1, &solidTetraVertexBuffer);
    
    [self loadSolidVertexData];
    
    //---- First Vertex Array Object --------
    
    glGenVertexArraysOES(1, &facesVertexArray);
    glGenBuffers(1, &facesVertexBuffer);

    [self loadFaceVertexData];
    
    //----- Second Vertex Array Object ----------
    glGenVertexArraysOES(1, &edgeVertexArray);
    glGenBuffers(1, &edgeVertexBuffer);
    glBindVertexArrayOES(edgeVertexArray);
    
    glBindBuffer(GL_ARRAY_BUFFER, edgeVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _anAnsysModel.numOfEdges*2*sizeof(GLKVector3), _anAnsysModel.edgeVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLKVector3), 0);


    //----- Third Vertex Array Object ----------   
    glGenBuffers(1, &allVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, allVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _anAnsysModel.numOfVertices*sizeof(GLKVector3), _anAnsysModel.vertexPositions, GL_STATIC_DRAW);
    
    //----- First Index Array Object ----------
    glGenBuffers(1, &beamIndexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, beamIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _anAnsysModel.numOfBeams*sizeof(Line), _anAnsysModel.lines, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);
    self.plotSolids = YES;
    self.plotShells = YES;
    self.plotBeams = YES;
    self.plotEdges = YES;
    self.plotNodes = NO;
}

- (void)loadFaceVertexData
{
    glBindVertexArrayOES(facesVertexArray);
    
    glBindBuffer(GL_ARRAY_BUFFER, facesVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, (_anAnsysModel.numOfQuadFaces*6+_anAnsysModel.numOfTriFaces*3)*sizeof(Vertex), _anAnsysModel.triVerticesFromAllFaces, GL_STATIC_DRAW);
    
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, normal));
    
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, color));
}

- (void)loadSolidVertexData
{
    glBindVertexArrayOES(solidCubeVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, solidCubeVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, (_anAnsysModel.numOfSolidCubeVertices)*sizeof(Vertex), _anAnsysModel.triVerticesFromCubeSolids, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, normal));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, color));
    
    glBindVertexArrayOES(solidPrismVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, solidPrismVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, (_anAnsysModel.numOfSolidPrismVertices)*sizeof(Vertex), _anAnsysModel.triVerticesFromPrismSolids, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, normal));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, color));
    
    glBindVertexArrayOES(solidTetraVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, solidTetraVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, (_anAnsysModel.numOfSolidTetraVertices)*sizeof(Vertex), _anAnsysModel.triVerticesFromTetraSolids, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, normal));
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, color));
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    _farZ = 20*boundingBox.lengthMax;

    _cameraPosition = GLKVector3Make(viewTranslateMatrix.m30, viewTranslateMatrix.m31, viewTranslateMatrix.m32);
    float cameraDistance = GLKVector3Length(_cameraPosition);
    if (cameraDistance > _farZ*0.5) cameraDistance = _farZ*0.5;
        
    // Background ModelViewMatrix
    float scaleFactor = -_orientationScale*_farZ*0.9f*GLKMathDegreesToRadians(65.0f);
    _backgroundModelViewMatrix =  GLKMatrix4Multiply(GLKMatrix4MakeScale(scaleFactor, scaleFactor / aspect, 1.0f), GLKMatrix4MakeTranslation(0.0f, 0.0f, -_farZ*0.9f));
    //NSLog(@"%@", NSStringFromGLKMatrix4(_backgroundModelViewMatrix));
    
    // translation animation
    if (_runPositionAnimation) {
        _lerpPosCur += self.timeSinceLastUpdate;
        float slerpAmt = _lerpPosCur / _lerpPosMax;
        if (slerpAmt > 1.0) {
            slerpAmt = 1.0;
            _runPositionAnimation = NO;
        }
        GLKVector3 position = GLKVector3Lerp(_lerpStart, _lerpEnd, slerpAmt);
        viewTranslateMatrix = GLKMatrix4MakeTranslation(position.x, position.y, position.z);
    } else {
        viewTranslateMatrix = GLKMatrix4Translate(viewTranslateMatrix, 
                                                  self.panTranslation.x / self.view.bounds.size.width * 2.0f * cameraDistance, 
                                                  -self.panTranslation.y / self.view.bounds.size.height * 2.0f *  cameraDistance, 
                                                  (self.pinchScale-lastPinch)* 1.0f * cameraDistance);
    }
    
    // rotation animation
    if (_runRotationAnimation) {
        _slerpCur += self.timeSinceLastUpdate;
        float slerpAmt = _slerpCur / _slerpMax;
        if (slerpAmt > 1.0) {
            slerpAmt = 1.0;
            _runRotationAnimation = NO;
        }
        viewRotationMatrix = GLKMatrix4MakeWithQuaternion(GLKQuaternionSlerp(_slerpStart, _slerpEnd, slerpAmt));
    } else {
        GLKMatrix4 viewXRot = GLKMatrix4MakeXRotation(GLKMathDegreesToRadians(_myRotation.y));
        GLKMatrix4 viewYRot = GLKMatrix4MakeYRotation(GLKMathDegreesToRadians(_myRotation.x));
        GLKMatrix4 viewZRot = GLKMatrix4MakeZRotation(_zRotation);
        viewRotationMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(viewZRot, GLKMatrix4Multiply(viewYRot, viewXRot)), viewRotationMatrix);
    }
    
    _viewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(viewTranslateMatrix, viewRotationMatrix), viewRotationOffsetMatrix);
    
    self.myRotation = CGPointZero;
    self.panTranslation = CGPointZero;
    self.zRotation = 0.0;
    lastPinch = self.pinchScale;
    
    
    _modelViewMatrix = GLKMatrix4Multiply(_viewMatrix, _modelMatrix);
    
    if (_isPerpective) {
        _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.01f, _farZ);
    } else {
        float halfWidth = cameraDistance*0.5;
        _projectionMatrix = GLKMatrix4MakeOrtho(-aspect*halfWidth, aspect*halfWidth, 
                                                -halfWidth, halfWidth, 
                                                0.01f, _farZ);
    }
    self.effect.transform.projectionMatrix = _projectionMatrix;
    self.effect.transform.modelviewMatrix  = _modelViewMatrix;
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render the background with GLKit
    
    self.effect.transform.modelviewMatrix = _backgroundModelViewMatrix;
    [self.effect prepareToDraw];
    glBindVertexArrayOES(backgroundVertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, backgroundVertexBuffer);
    glDrawArrays(GL_TRIANGLES, 0, sizeof(MeshVertexData) / sizeof(vertexDataTextured));

    // Reset the model view matrix for the rest of the objects
    self.effect.transform.modelviewMatrix = _modelViewMatrix;;
    [self.effect prepareToDraw];
    
    
    if (self.plotSolids) {
        glBindVertexArrayOES(solidCubeVertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, solidCubeVertexBuffer);
        glEnable (GL_BLEND);
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDrawArrays(GL_TRIANGLES, 0, _anAnsysModel.numOfSolidCubeVertices);
        
        glBindVertexArrayOES(solidPrismVertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, solidPrismVertexBuffer);
        glEnable (GL_BLEND);
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDrawArrays(GL_TRIANGLES, 0, _anAnsysModel.numOfSolidPrismVertices);
        
        glBindVertexArrayOES(solidTetraVertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, solidTetraVertexBuffer);
        glEnable (GL_BLEND);
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDrawArrays(GL_TRIANGLES, 0, _anAnsysModel.numOfSolidTetraVertices);
    }
        
    if (self.plotShells) {
        // Render the quads with GLKit
        glBindVertexArrayOES(facesVertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, facesVertexBuffer);
        glEnable (GL_BLEND);
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDrawArrays(GL_TRIANGLES, 0, _anAnsysModel.numOfQuadFaces*6+_anAnsysModel.numOfTriFaces*3);
    }
  
    if (self.plotEdges) {

        glLineWidth(2.0f);
        glColor4f(0, 0, 0, 1);
        glBindVertexArrayOES(edgeVertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, edgeVertexBuffer);
        glDrawArrays(GL_LINES, 0, _anAnsysModel.numOfEdges*2);
    }

    if (self.plotBeams) {
        //Bind all vertices
        glBindVertexArrayOES(allVertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, allVertexBuffer);
        
        // Render the beams with GLKit
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, beamIndexBuffer);
        
        glLineWidth(7.0f);
        // glColor / alpha white + alpha
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLKVector3), 0);
        
        glDrawElements(GL_LINES, _anAnsysModel.numOfBeams*2, GL_UNSIGNED_INT, 0);
    }
    
    if (self.plotNodes) {
        glPointSize(2.0f);
        glBindVertexArrayOES(allVertexArray);
        glBindBuffer(GL_ARRAY_BUFFER, allVertexBuffer);
        glDrawArrays(GL_POINTS, 0, _anAnsysModel.numOfVertices);
    }
}


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &facesVertexBuffer);
    glDeleteVertexArraysOES(1, &facesVertexArray);
    
    glDeleteBuffers(1, &edgeVertexBuffer);
    glDeleteVertexArraysOES(1, &edgeVertexArray);
    
    glDeleteBuffers(1, &beamIndexBuffer);
    glDeleteVertexArraysOES(1, &beamIndexArray);
    
    glDeleteBuffers(1, &allVertexBuffer);
    glDeleteVertexArraysOES(1, &allVertexArray);
    
    self.effect = nil;
}


- (void)makeGradientBackground
{    
    glGenVertexArraysOES(1, &backgroundVertexArray);
    glBindVertexArrayOES(backgroundVertexArray);
    
    glGenBuffers(1, &backgroundVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, backgroundVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(MeshVertexData), MeshVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), 0);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE,  sizeof(vertexDataTextured), (char *)12);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (char *)24);
    
    glActiveTexture(GL_TEXTURE0);
    NSString *path = [[NSBundle mainBundle] pathForResource:@"gradient_1600x1" ofType:@"jpg"];
    
    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:GLKTextureLoaderOriginBottomLeft];
    
    self.background = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (self.background == nil || error != nil) NSLog(@"Error loading texture: %@", [error localizedDescription]);
    
    GLKEffectPropertyTexture *texture = [[GLKEffectPropertyTexture alloc] init];
    texture.enabled = YES;
    texture.name = self.background.name;
    self.effect.texture2d0.name = texture.name;
}

#pragma mark - 
#pragma mark - Gesture recognizers
- (void)_addGestureRecognizers
{
    UIPanGestureRecognizer *panMoveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panMoveGesture.minimumNumberOfTouches = 1;
    panMoveGesture.maximumNumberOfTouches = 2;
    self.activeGestures = 0;
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
    [self.view  addGestureRecognizer:singleTapGesture];
    [singleTapGesture setDelegate:self];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGesture:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.view  addGestureRecognizer:doubleTapGesture];
    [doubleTapGesture setDelegate:self];
    
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
}

# pragma mark - Gesture actions
- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
    if (!self.navigationController.navigationBar.isHidden) [self _hideNavigationBarAndToolsView:YES];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
        {
            if(panGesture.numberOfTouches == 2) {
                _panTranslation = [panGesture translationInView:self.view] ;
                [panGesture setTranslation:CGPointZero inView:self.view];
            } else if(panGesture.numberOfTouches == 1) {
                [self addVelocitySample:[panGesture translationInView:self.view]];
                [panGesture setTranslation:CGPointZero inView:self.view];
            }
        }
            break;
            
        default:
            break;
    }
}

#define PREVIOUSWEIGHT 0.75f

- (void)addVelocitySample:(CGPoint)velocitySample
{
    _myRotation.x *= PREVIOUSWEIGHT;
    _myRotation.y *= PREVIOUSWEIGHT;
    _myRotation.x += (1 - PREVIOUSWEIGHT) * velocitySample.x;
    _myRotation.y += (1 - PREVIOUSWEIGHT) * velocitySample.y;
}

-(void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchGesture 
{
    switch (pinchGesture.state) {
        case UIGestureRecognizerStateBegan:
            initialOrthoSidelength = orthoSideLength;
            lastDistance = 1.0;
            lastPinch = 1.0;
            self.pinchScale = 1.0;
            
            break;
            
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self addPinchVelocitySample:pinchGesture.scale];
            orthoSideLength = initialOrthoSidelength / _pinchScale;

            break;
            
        default:
            break;
    }
}

- (void)addPinchVelocitySample:(CGFloat)pinchVelocitySample
{
    _pinchScale *= PREVIOUSWEIGHT;
    _pinchScale += (1 - PREVIOUSWEIGHT) * pinchVelocitySample;
}

#define RADIANS_TO_DEGREES 57.2957805

-(void)handleRotationGesture:(UIRotationGestureRecognizer *)rotationGesture
{
    switch (rotationGesture.state) {
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
    if (singleTapGesture.state == UIGestureRecognizerStateEnded) {
        [self _hideNavigationBarAndToolsView:!self.navigationController.navigationBar.isHidden];
    }
}


- (void)_hideNavigationBarAndToolsView:(BOOL)shouldHide
{
    UINavigationBar *navBar = self.navigationController.navigationBar;
    UIToolbar *toolBar = self.navigationController.toolbar;
    CGFloat endAlpha = 0.0f;
    if (!shouldHide) {
        endAlpha = 1.0f;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
    [UIView animateWithDuration:0.2f animations:^{
        navBar.alpha = endAlpha;
        toolBar.alpha = endAlpha;
    } completion:^(BOOL finished){
        [navBar setHidden:shouldHide];
        [toolBar setHidden:shouldHide];
    }];
}




- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)doubleTapGesture
{
    if (doubleTapGesture.state == UIGestureRecognizerStateEnded) NSLog(@"double tap gesture");
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


- (UIImage *)currentViewAsModelScreenshot
{
    return [(GLKView *)self.view snapshot];
}


- (IBAction)doneTapped:(UIBarButtonItem *)sender
{
    if (self.thePopoverController.isPopoverVisible) {
        [self.thePopoverController dismissPopoverAnimated:YES];
        self.thePopoverController = nil;
    }
    [self.modelViewDelegate modelViewController:self didTapDone:[self currentViewAsModelScreenshot] model:self.model];
}

- (IBAction)viewsTapped:(UIBarButtonItem *)sender
{
    [self dismissPopopoverIfVisible];
    if (!self.thePopoverController.isPopoverVisible) {
        NSLog(@"IMplement show the views table view controller popover");
        //        ViewsTableViewController *viewsTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Views Table View Controller"];
        //        viewsTableViewController.delegate = self;
        //        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewsTableViewController];
        //        self.thePopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
//        self.thePopoverController.delegate = self;
//        [self.thePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    } else {
        [self.thePopoverController dismissPopoverAnimated:NO];
        self.thePopoverController = nil;
    }
    
}


#pragma mark - ElementTypeTableViewControllerDelegate methods
- (void)solidTypeWasChanged:(UISwitch *)sender
{
    self.plotSolids = sender.isOn;
}

- (void)shellTypeWasChanged:(UISwitch *)sender
{
    self.plotShells = sender.isOn;
}

- (void)beamTypeWasChanged:(UISwitch *)sender
{
    self.plotBeams = sender.isOn;
}

- (void)edgesWasChanged:(UISwitch *)sender
{
    self.plotEdges = sender.isOn;
}

- (void)nodeWasChanged:(UISwitch *)sender
{
    self.plotNodes = sender.isOn;    
}

#pragma mark - ColorTableViewControllerDelegate methods
- (void)transparencyChanged:(UISlider *)sender
{
    self.elementTransparency = sender.value;
    [_anAnsysModel setColorsOfElementsWithTranparency:self.elementTransparency];
    [self loadFaceVertexData];
    [self loadSolidVertexData];
}

- (void)dismissPopopoverIfVisible
{
    if (self.thePopoverController.isPopoverVisible) {
        [self.thePopoverController dismissPopoverAnimated:YES];
        self.thePopoverController = nil;
    }
}

#pragma mark - Popoverview delegate
- (void)popoverViewDidDismiss:(PopoverView *)popoverView
{
    [self.popoverContentViewController removeFromParentViewController];
    self.popoverContentViewController = nil;
}

#define ORTHO_PERSPECTIVE_TAG 10
#define LOOK_AT_TAG 20

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index
{
    switch (popoverView.tag) {
        case ORTHO_PERSPECTIVE_TAG:
            self.isPerpective = (index == 0) ? YES : NO;
            break;
            
        case LOOK_AT_TAG:
            switch (index) {
                case 0:
                    [self animationToEndOrientation:GLKQuaternionMakeWithAngleAndAxis(PI_2, 0.0, 1.0, 0.0)];
                    break;
                    
                case 1:
                    [self animationToEndOrientation:GLKQuaternionMakeWithAngleAndAxis(PI_2, 1.0, 0.0, 0.0)];
                    break;
                    
                case 2:
                    [self animationToEndOrientation:GLKQuaternionMakeWithAngleAndAxis(0.0, 0.0, 0.0, 1.0)];
                    break;
            }
            break;
            
        default:
            break;
    }
    [popoverView dismiss:YES];
}

- (void)elementTypeTapped:(UIButton *)sender
{
    PGElementTypeViewController *elementTypeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"testViewController"];
    elementTypeVC.delegate = self;
    self.popoverContentViewController = elementTypeVC;
    elementTypeVC.view.frame = CGRectMake(0, 0, 280, 180);
    self.popoverView = [PopoverView showPopoverAtPoint:sender.center inView:self.navigationController.toolbar withContentView:elementTypeVC.view delegate:self];
    [elementTypeVC didMoveToParentViewController:self];
    elementTypeVC.solidElements.on = self.plotSolids;
    elementTypeVC.shellElements.on = self.plotShells;
    elementTypeVC.beamElements.on = self.plotBeams;
    elementTypeVC.edges.on = self.plotEdges;
}




- (void)transparencyTapped:(UIButton *)sender
{
    PGTransparencyViewController *transparencyVC = [self.storyboard instantiateViewControllerWithIdentifier:@"transparencyViewController"];
    transparencyVC.delegate = self;
    self.popoverContentViewController = transparencyVC;
    transparencyVC.view.frame = CGRectMake(0, 0, 250, 100);
    self.popoverView = [PopoverView showPopoverAtPoint:sender.center inView:self.navigationController.toolbar withContentView:transparencyVC.view delegate:self];
    [transparencyVC didMoveToParentViewController:self];
    [transparencyVC.transparencySlider setValue:self.elementTransparency];
}


- (void)animationToEndOrientation:(GLKQuaternion)endAngle
{
    _runRotationAnimation = YES;
    _slerpCur = 0;
    _slerpMax = 0.5;
    _slerpStart = GLKQuaternionMakeWithMatrix4(viewRotationMatrix);
    _slerpEnd = endAngle;
}


- (void)animateCameraToEndLocation:(GLKVector3)endLocation
{
    _runPositionAnimation = YES;
    _lerpPosCur = 0;
    _lerpPosMax = 0.5;
    _lerpStart = GLKVector3Make(viewTranslateMatrix.m30, viewTranslateMatrix.m31, viewTranslateMatrix.m32);
    _lerpEnd = endLocation;
}


- (void)lookAtTapped:(UIButton *)sender
{
    self.popoverView = [PopoverView showPopoverAtPoint:sender.center inView:self.navigationController.toolbar withTitle:NSLocalizedString(@"Look-at Axis", nil) withStringArray:@[NSLocalizedString(@"X-Axis", nil), NSLocalizedString(@"Y-Axis", nil), NSLocalizedString(@"Z-Axis", nil)] delegate:self];
    self.popoverView.tag = LOOK_AT_TAG;
}


- (void)orthoPerspectiveTapped:(UIButton *)sender
{
    self.popoverView = [PopoverView showPopoverAtPoint:sender.center inView:self.navigationController.toolbar withTitle:NSLocalizedString(@"View Mode", nil) withStringArray:@[NSLocalizedString(@"Perspective", nil), NSLocalizedString(@"Orthographic", nil)] delegate:self];
    self.popoverView.tag = ORTHO_PERSPECTIVE_TAG;
}


- (void)animateToReset
{
    GLKQuaternion rotationQuat         = GLKQuaternionMakeWithAngleAndAxis(-0.25 * ROT, 1.0, 0.0, 0.0);
    rotationQuat = GLKQuaternionMultiply(GLKQuaternionMakeWithAngleAndAxis(0.125 * ROT, 0.0, 1.0, 0.0),rotationQuat);
    rotationQuat = GLKQuaternionMultiply(GLKQuaternionMakeWithAngleAndAxis(0.125 * ROT, 1.0, 0.0, 0.0),rotationQuat);

    [self animationToEndOrientation:rotationQuat];
    [self animateCameraToEndLocation:GLKVector3Make(0.0, 0.0, -2*boundingBox.lengthMax)];
}


- (void)showAnnularProgressHUD
{
    self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:self.progressHUD];
    
    // Set determinate mode
    self.progressHUD.mode = MBProgressHUDModeAnnularDeterminate;
    [self.progressHUD dimBackground];
    
    self.progressHUD.delegate = self;
    self.progressHUD.labelText = @"Loading";
    
    // myProgressTask uses the HUD instance to update progress
    [self.progressHUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
}


- (void)myProgressTask 
{
	// This just increases the progress indicator in a loop
	while (self.readingModelData) {
		usleep(50000);
	}
}


#pragma mark - MBProgresHUD delegate method
- (void)hudWasHidden:(MBProgressHUD *)hud 
{
	// Remove HUD from screen when the HUD was hidden
	[hud removeFromSuperview];
	hud = nil;
}

#pragma mark - AnsysModelDelegate methods
- (void)parsingProgress:(float)progress
{
    self.progressHUD.progress = progress;
}


- (void)startedParsingNodes
{
    self.progressHUD.labelText = [NSString stringWithFormat:@"Reading nodes"];
}


- (void)finishedParsingNodes:(NSUInteger)noOfNodes
{
    self.progressHUD.labelText = [NSString stringWithFormat:@"Read %i nodes", noOfNodes];
}

- (void)startedParsingElements
{
    self.progressHUD.labelText = [NSString stringWithFormat:@"Reading elements"];
}

- (void)finishedParsingElements:(NSUInteger)noOfElements
{
    self.progressHUD.labelText = [NSString stringWithFormat:@"Read %i elements", noOfElements];
}

- (BOOL)shouldContinueAfterNodeCountLimitPassed:(NSUInteger)allowedNodeCount forModel:(NSString *)fileName
{
    if ([self fileTypeIsPurchased:fileName]) {
        return YES;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hide:YES];
        //[self.delegate doneButtonTapped:self];
        
        [NSNotificationCenter.defaultCenter postNotificationName:PolygonModelTypeNotPurchased object:self userInfo:[NSDictionary dictionaryWithObject:fileName forKey:@"filename"]];
    }); 
    return NO;
}


#pragma mark - Views Table View Controller Delegate
- (PGView *)viewsTableViewController:(PGViewsTableViewController *)viewsTableViewController currentViewForModel:(PGModel *)model
{
    GLKVector3 currentPosition = GLKVector3Make(viewTranslateMatrix.m30, viewTranslateMatrix.m31, viewTranslateMatrix.m32);
    GLKQuaternion currentOrientation = GLKQuaternionMakeWithMatrix4(viewRotationMatrix);
    PGView *currentView = [PGView createWithLocationX:currentPosition.x locationY:currentPosition.y locationZ:currentPosition.z
                                          quaternionX:currentOrientation.x quaternionY:currentOrientation.y quaternionZ:currentOrientation.z quaternionW:currentOrientation.w screenShot:[self currentViewAsModelScreenshot]];
    return currentView;
}


- (void)viewsTableViewController:(PGViewsTableViewController *)viewsTableViewController didSelectView:(PGView *)savedView
{
    NSLog(@"didSelectView: %@", savedView);
}

//- (ROI3D *)currentROI:(ViewsTableViewController *)sender
//{
//    GLKVector3 currentPosition = GLKVector3Make(viewTranslateMatrix.m30, viewTranslateMatrix.m31, viewTranslateMatrix.m32);
//    GLKQuaternion currentOrientation = GLKQuaternionMakeWithMatrix4(viewRotationMatrix);;
//    ROI3D *currentROI = [ROI3D createROIAt:currentPosition andOrientation:currentOrientation];
//    //currentROI.snapshot = [(GLKView *)self.view snapshot];
//    return currentROI;
//}
//
//
//- (NSString *)directoryForROIList:(ViewsTableViewController *)sender
//{
//    NSLog(@"Implement Find roi list");
//    return nil;
//    NSString *currentFolder = [self.modelPath stringByDeletingLastPathComponent];
//    NSString *roiFolder = [currentFolder stringByAppendingPathComponent:ROIs];
//    
//    BOOL isADir;
//    
//    if (![NSFileManager.defaultManager fileExistsAtPath:roiFolder isDirectory:&isADir]) 
//    {
//        NSError *error;
//        [NSFileManager.defaultManager createDirectoryAtPath:roiFolder withIntermediateDirectories:NO attributes:nil error:&error];
//    }
//    return roiFolder;
//}
//
//- (UIImage *)currentSnapshot:(ViewsTableViewController *)sender
//{
//    return [(GLKView *)self.view snapshot];
//}
//
//- (void)didSelectROI:(ROI3D *)aRoi
//{
//    [self animationToEndOrientation:aRoi.orientation];
//    [self animateCameraToEndLocation:aRoi.location];
//}

#pragma mark - Helper methods

- (BOOL)fileTypeIsPurchased:(NSString *)fileName
{
    NSLog(@"IS purchased not implemented");
//    NSString *modelTypeIdentifier = [ModelAssetsLibrary modelTypeIdentifierForFile:fileName];
//    NSString *productIdentifier = [InAppPolygonIAPHelper productIdentifierForModelTypeIdentifier:modelTypeIdentifier];
    return YES;
//    return [InAppPolygonIAPHelper productIdentifierIsPurchased:productIdentifier];
}

@end
