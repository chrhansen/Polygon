//
//  AnsysModel.h
//  FEViewer2
//
//  Created by Christian Hansen on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "AnsysHelper.h"
#import "Structs.h"

@protocol AnsysModelDelegate <NSObject>

@optional
- (void)startedParsingNodes;
- (void)finishedParsingNodes:(NSUInteger)noOfNodes;
- (void)startedParsingElements;
- (void)finishedParsingElements:(NSUInteger)noOfElements;
- (void)parsingProgress:(float)progress;
- (BOOL)shouldContinueAfterNodeCountLimitPassed:(NSUInteger)allowedNodeCount forModel:(NSString *)fileName;

@end

@interface AnsysModel : NSObject

+ (AnsysModel *)ansysFileWithPath:(NSString *)path andDelegate:(id<AnsysModelDelegate>)delegatingObject andSettings:(NSDictionary *)settings;

- (void)setColorsOfElementsWithTranparency:(float)transparency;

- (void)releaseArrays;

@property (nonatomic, weak) id<AnsysModelDelegate> delegate;
@property (nonatomic) GLKVector3 *vertexPositions;
@property (nonatomic) GLKVector3 *edgeVertices;
@property (nonatomic) Vertex *triVertices;
@property (nonatomic) Vertex *triVerticesFromQuads;
@property (nonatomic) Vertex *triVerticesFromCubeSolids;
@property (nonatomic) Vertex *triVerticesFromPrismSolids;
@property (nonatomic) Vertex *triVerticesFromTetraSolids;
@property (nonatomic) Vertex *triVerticesFromAllFaces;
@property (nonatomic) LowMemVertex *lowMemTriVertices;
@property (nonatomic) LowMemVertex *lowMemTriVerticesFromQuads;
@property (nonatomic) LowMemVertex *lowMemTriVerticesFromAllFaces;
@property (nonatomic) Line *lines;
@property (nonatomic) TriFace *triFaces;
@property (nonatomic) QuadFace *quadFaces;
@property (nonatomic) ElementProperties *solidCubeElemProp;
@property (nonatomic) ElementProperties *solidPrismElemProp;
@property (nonatomic) ElementProperties *solidTetraElemProp;
@property (nonatomic) ElementProperties *quadElemProp;
@property (nonatomic) ElementProperties *triElemProp;
@property (nonatomic) ElementProperties *beamElemProp;
@property (nonatomic) AnsysMaterial *matProperties;
@property (nonatomic) AnsysSection *sectionProperties;
@property (nonatomic) GLKVector4 *colorArray;
@property (nonatomic) BoundingBox *boundingBox;
@property (nonatomic, strong) NSMutableDictionary *origToNew;
@property (nonatomic) NSUInteger numOfSolidCubeVertices;
@property (nonatomic) NSUInteger numOfSolidPrismVertices;
@property (nonatomic) NSUInteger numOfSolidTetraVertices;
@property (nonatomic) NSUInteger numOfVertices;
@property (nonatomic) NSUInteger numOfTriFaces;
@property (nonatomic) NSUInteger numOfQuadFaces;
@property (nonatomic) NSUInteger numOfEdges;
@property (nonatomic) NSUInteger numOfBeams;
@property (nonatomic) NSUInteger numOfMatProperties;
@property (nonatomic) NSUInteger numOfSecProperties;
@property (nonatomic) ColorMode colorMode; 
@property (nonatomic) BOOL isAnsysParsingPurchased;


@end
