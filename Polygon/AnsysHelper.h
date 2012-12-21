//
//  AnsysHelper.h
//  FEViewer2
//
//  Created by Christian Hansen on 5/3/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface AnsysHelper : NSObject

struct ElementProperties
{
	NSUInteger elementNo;
	NSUInteger materialNo;
	NSUInteger sectionNo;
    NSUInteger realNo;
};
typedef struct ElementProperties ElementProperties;
typedef ElementProperties* ElementPropertiesPtr;

struct AnsysMaterial
{
	NSUInteger matNo;
	CGFloat eX;
	CGFloat dens;
	CGFloat nuXY;
};
typedef struct AnsysMaterial AnsysMaterial;
typedef AnsysMaterial* AnsysMaterialPtr;

typedef enum {
    kUnknown,
    kSolid,
    kShell,
    kBeam
} SecType;

struct AnsysSection
{
	NSUInteger secNo;
	SecType secType;
	CGFloat val1;
	CGFloat val2;
    CGFloat val3;
    CGFloat val4;
};
typedef struct AnsysSection AnsysSection;
typedef AnsysSection* AnsysSectionPtr;


+ (AnsysHelper *)makeNblockWithRanges:(NSString *)ranges;

+ (AnsysHelper *)makeEblockWithRanges:(NSString *)ranges withSolid:(BOOL)solidKey;

+ (NSString *)extractNodeNumberFromLineWithCommaSeparation:(NSString *)aLine;

- (NSString *)extractNodeNumberFromLine:(NSString *)aLine;

+ (GLKVector3)extractVertexPositionFromLineWithCommaSeparation:(NSString *)aLine;

- (GLKVector3)extractVertexPositionFromLine:(NSString *)aLine;

- (NSArray *)extractSolidCubeIndexComponentsFromLine:(NSString *)aLine;

- (NSArray *)extractSolidTetraIndexComponentsFromLine:(NSString *)aLine;

- (NSArray *)extractShellIndexComponentsFromLine:(NSString *)aLine;

- (NSArray *)extractBeamIndexComponentsFromLine:(NSString *)aLine;

- (ElementProperties)extractElementPropertiesFromLine:(NSString *)aLine;

+ (AnsysMaterial)extractMaterialPropertyFromMPLine:(NSString *)aLine separatedBy:(NSCharacterSet *)characterSet;

+ (GLKVector3)getNormalizedNormalVectorNode1:(NSArray *)node1 node2:(NSArray *)node2 andNode3:(NSArray *)node3;

+ (NSString *)stringFromElementProperties:(ElementProperties)elementProperties;

+ (NSString *)stringFromMaterialProperties:(AnsysMaterial)matProperties;

@property (nonatomic) NSUInteger xLineLength, yLineLength, zLineLength;
@property (nonatomic) NSUInteger node1LineLength, node2LineLength, node3LineLength, node4LineLength;

@property (nonatomic) NSRange xRange, yRange, zRange;
@property (nonatomic) NSRange nodeNumberRange;

@property (nonatomic) NSRange node1Range, node2Range, node3Range, node4Range, node5Range, node6Range, node7Range, node8Range;
@property (nonatomic) NSRange elementTypeRange, elementNumberRange, elementMaterialRange, elementSectionRange, elementRealRange;

@end
