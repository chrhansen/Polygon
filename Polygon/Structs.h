//
//  Structs.h
//  FEViewer2
//
//  Created by Christian Hansen on 05/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <GLKit/GLKit.h>

#ifndef FEViewer2_Structs_h
#define FEViewer2_Structs_h

struct BoundingBox
{
    GLKVector3 box;
    GLKVector3 offset;
    float lengthMax;
};
typedef struct BoundingBox BoundingBox;
typedef BoundingBox* BoundingBoxPtr;

struct Vertex
{
    GLKVector3 position;
    GLKVector4 color;
    GLKVector3 normal;
};
typedef struct Vertex Vertex;
typedef Vertex* VertexPtr;

struct LowMemVertex
{
    GLKVector3 position;
    GLKVector3 normal;
};
typedef struct LowMemVertex LowMemVertex;
typedef LowMemVertex* LowMemVertexPtr;

struct Line
{
	uint vertex1;
    uint vertex2;
};
typedef struct Line Line;
typedef Line* LinePtr;

struct TriFace
{
	NSUInteger vertex1;
    NSUInteger vertex2;
	NSUInteger vertex3;
};
typedef struct TriFace TriFace;
typedef TriFace* TriFacePtr;

struct QuadFace
{
	NSUInteger vertex1;
    NSUInteger vertex2;
	NSUInteger vertex3;
    NSUInteger vertex4;
};
typedef struct QuadFace QuadFace;
typedef QuadFace* QuadFacePtr;

typedef enum {
    kThicknessColor,
    kMaterialColor,
    kDensityColor
} ColorMode;


struct vertexDataTextured
{
	GLKVector3		vertex;
	GLKVector3		normal;
	GLKVector2      texCoord;
};
typedef struct vertexDataTextured vertexDataTextured;
typedef vertexDataTextured* vertexDataTexturedPtr;

#endif
