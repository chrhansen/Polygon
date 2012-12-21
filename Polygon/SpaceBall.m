//
//  SpaceBall.m
//  Polygon
//
//  Created by Christian Hansen on 02/06/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "SpaceBall.h"
@interface SpaceBall ()

@property (nonatomic) float radius;

@end

@implementation SpaceBall
@synthesize vertices = _vertices;
@synthesize radius = _radius;
@synthesize location = _location;
@synthesize numOfVertices = _numOfVertices;
@synthesize hasChanged = _hasChanged;

#define NUM_OF_VERTS 24

+ (SpaceBall *)spaceBallWithRadius:(float)radius atLocation:(GLKVector3)location
{
    SpaceBall *newSpaceBall = [[super alloc] init];
    newSpaceBall.hasChanged = YES;
    newSpaceBall.radius = radius;
    newSpaceBall.location = location;
    [newSpaceBall setColor: GLKVector4Make(219.0/256.0f, 112.0/256.0f, 147.0/256.0f, 1.0)];
    
    return newSpaceBall;
}


- (void)setColor:(GLKVector4)color
{
    if (self.vertices == nil)
    {
        self.vertices = calloc(NUM_OF_VERTS, sizeof(Vertex));
    }
        
    for (NSUInteger i = 0; i < NUM_OF_VERTS; i++) 
    {
        self.vertices[i].color = color;
    }
}


- (void)setRadius:(float)radius
{
    _radius = radius;
    if (self.vertices == nil)
    {
        self.vertices = calloc(NUM_OF_VERTS, sizeof(Vertex));
    }
    // tri 0
    self.vertices[0].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f, -1.0f,  1.0f), _radius);
    self.vertices[1].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f, -1.0f, -1.0f), _radius);
    self.vertices[2].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f,  1.0f, -1.0f), _radius);
    // tri 1
    self.vertices[3].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f,  1.0f, -1.0f), _radius);
    self.vertices[4].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f,  1.0f,  1.0f), _radius);
    self.vertices[5].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f, -1.0f,  1.0f), _radius);
    // tri 2
    self.vertices[6].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f,  1.0f,  1.0f), _radius);
    self.vertices[7].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f,  1.0f, -1.0f), _radius);
    self.vertices[8].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f,  1.0f, -1.0f), _radius);
    // tri 3
    self.vertices[9].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f,  1.0f, -1.0f), _radius);
    self.vertices[10].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f,  1.0f,  1.0f), _radius);
    self.vertices[11].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f,  1.0f,  1.0f), _radius);
    // tri 4
    self.vertices[12].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f, -1.0f, -1.0f), _radius);
    self.vertices[13].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f, -1.0f,  1.0f), _radius);
    self.vertices[14].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f,  1.0f,  1.0f), _radius); 
    // tri 5
    self.vertices[15].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f,  1.0f,  1.0f), _radius);
    self.vertices[16].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f,  1.0f, -1.0f), _radius);
    self.vertices[17].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f, -1.0f, -1.0f), _radius);    
    // tri 6
    self.vertices[18].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f, -1.0f,  1.0f), _radius);
    self.vertices[19].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f, -1.0f, -1.0f), _radius);
    self.vertices[20].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f, -1.0f, -1.0f), _radius);
    // tri 7
    self.vertices[21].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f, -1.0f, -1.0f), _radius);
    self.vertices[22].position = GLKVector3MultiplyScalar(GLKVector3Make( 1.0f, -1.0f,  1.0f), _radius);
    self.vertices[23].position = GLKVector3MultiplyScalar(GLKVector3Make(-1.0f, -1.0f,  1.0f), _radius);
    
    for (NSUInteger i = 0; i < NUM_OF_VERTS; i++) 
    {
        self.vertices[i].normal = GLKVector3Normalize(self.vertices[i].position);
    }
}


- (void)setLocation:(GLKVector3)location
{
    self.hasChanged = YES;
    _location = location;
    [self setRadius:_radius];
    if (self.vertices == nil)
    {
        self.vertices = calloc(NUM_OF_VERTS, sizeof(Vertex));
    }
    for (NSUInteger i = 0; i < NUM_OF_VERTS; i++) 
    {
        self.vertices[i].position = GLKVector3Add(self.vertices[i].position, location);
    }
}

- (NSUInteger)numOfVertices
{
    _numOfVertices = NUM_OF_VERTS;
    return NUM_OF_VERTS;
}

@end
