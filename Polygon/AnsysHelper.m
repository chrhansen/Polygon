//
//  AnsysHelper.m
//  FEViewer2
//
//  Created by Christian Hansen on 5/3/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "AnsysHelper.h"

@interface AnsysHelper () {
    NSCharacterSet *_whiteSpaceSet;
}



@end

@implementation AnsysHelper


@synthesize xLineLength = _xLineLength;
@synthesize yLineLength = _yLineLength;
@synthesize zLineLength = _zLineLength;
@synthesize node1LineLength = _node1LineLength;
@synthesize node2LineLength = _node2LineLength;
@synthesize node3LineLength = _node3LineLength;
@synthesize node4LineLength = _node4LineLength;

@synthesize xRange = _xRange;
@synthesize yRange = _yRange;
@synthesize zRange = _zRange;
@synthesize nodeNumberRange = _nodeNumberRange;

@synthesize elementNumberRange = _elementNumberRange;
@synthesize elementMaterialRange = _elementMaterialRange;
@synthesize elementSectionRange = _elementSectionRange;
@synthesize elementRealRange = _elementRealRange;
@synthesize elementTypeRange = _eTypeRange;

@synthesize node1Range = _node1Range;
@synthesize node2Range = _node2Range;
@synthesize node3Range = _node3Range;
@synthesize node4Range = _node4Range;
@synthesize node5Range = _node5Range;
@synthesize node6Range = _node6Range;
@synthesize node7Range = _node7Range;
@synthesize node8Range = _node8Range;

#define FIELD_LENGTH 8

- (id)init
{
    _whiteSpaceSet = [NSCharacterSet whitespaceCharacterSet];
    return [super init];
}

+ (NSString *)extractNodeNumberFromLineWithCommaSeparation:(NSString *)aLine
{
    NSArray *nodeComponents = [aLine componentsSeparatedByString:@","];
    if (nodeComponents.count >= 2) 
    {
        return [nodeComponents objectAtIndex:1];
    } 
    else 
    {
        NSLog(@"No position (x,y,z) for comma separated node definition: %@", aLine);
        return @"-1";
    }  
}


- (NSString *)extractNodeNumberFromLine:(NSString *)aLine
{
    if (aLine.length >= (self.nodeNumberRange.location+self.nodeNumberRange.length)) 
    {
        return [[aLine substringWithRange:self.nodeNumberRange] stringByTrimmingCharactersInSet:_whiteSpaceSet];
    } 
    else 
    {
        NSLog(@"-1 aLine: %@", aLine);
        return @"-1";
    } 
}


- (GLKVector3)extractVertexPositionFromLine:(NSString *)aLine
{
    if (aLine.length >= self.zLineLength) 
    {
        return GLKVector3Make([[aLine substringWithRange:self.xRange] floatValue], [[aLine substringWithRange:self.yRange] floatValue], [[aLine substringWithRange:self.zRange] floatValue]);
    } 
    else if (aLine.length >= self.yLineLength) 
    {
        return GLKVector3Make([[aLine substringWithRange:self.xRange] floatValue], [[aLine substringWithRange:self.yRange] floatValue], 0.0);
    } 
    else if (aLine.length >= self.xLineLength) 
    {
        return GLKVector3Make([[aLine substringWithRange:self.xRange] floatValue], 0.0, 0.0);
    } 
    else 
    {
        return GLKVector3Make(0.0, 0.0, 0.0);
    } 
}

+ (GLKVector3)extractVertexPositionFromLineWithCommaSeparation:(NSString *)aLine
{
    NSArray *vertexComponents = [aLine componentsSeparatedByString:@","];
    if (vertexComponents.count >= 4) 
    {
        return GLKVector3Make([[vertexComponents objectAtIndex:1] floatValue], [[vertexComponents objectAtIndex:2] floatValue], [[vertexComponents objectAtIndex:3] floatValue]);
    } 
    else if (vertexComponents.count >= 3) 
    {
        return GLKVector3Make([[vertexComponents objectAtIndex:1] floatValue], [[vertexComponents objectAtIndex:2] floatValue], 0.0);
    }
    else if (vertexComponents.count >= 2) 
    {
        return GLKVector3Make([[vertexComponents objectAtIndex:1] floatValue], 0.0, 0.0);
    } 
    else 
    {
        return GLKVector3Make(0.0, 0.0, 0.0);
    } 
}


+ (NSArray *)fieldLengthInfo:(NSString *)rangeString
{
    NSArray *formatSpecifiers = [rangeString componentsSeparatedByString:@","];
    NSString *nodeRangeString = [formatSpecifiers objectAtIndex:0];
    
    NSString *nnFieldLength = [nodeRangeString substringWithRange:NSMakeRange(nodeRangeString.length-1, 1)];
    NSString *numOfNNFields = [[nodeRangeString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] substringWithRange:NSMakeRange(1, 1)];
    return [NSArray arrayWithObjects:numOfNNFields, nnFieldLength, nil];
}


+ (AnsysHelper *)makeNblockWithRanges:(NSString *)ranges
{   
    AnsysHelper *_ansysNblock = [[super alloc] init];
    
    NSArray *formatInfo = [self fieldLengthInfo:ranges];    
    NSInteger numOfNNFields = [[formatInfo objectAtIndex:0] integerValue];
    NSInteger nnFieldLength = [[formatInfo objectAtIndex:1] integerValue];
    
    if ([ranges componentsSeparatedByString:@","].count > 1)
    {
        
        _ansysNblock.nodeNumberRange = NSMakeRange(0, nnFieldLength);
        _ansysNblock.xRange = NSMakeRange(numOfNNFields * nnFieldLength + 0 * 20, 20);
        _ansysNblock.yRange = NSMakeRange(numOfNNFields * nnFieldLength + 1 * 20, 20);
        _ansysNblock.zRange = NSMakeRange(numOfNNFields * nnFieldLength + 2 * 20, 20);
        _ansysNblock.xLineLength = _ansysNblock.xRange.location+_ansysNblock.xRange.length;
        _ansysNblock.yLineLength = _ansysNblock.yRange.location+_ansysNblock.yRange.length;
        _ansysNblock.zLineLength = _ansysNblock.zRange.location+_ansysNblock.zRange.length;
    } 
    else if ([ranges hasPrefix:@"(19i8)"]) 
    {
        _ansysNblock.nodeNumberRange = NSMakeRange(0, nnFieldLength);
        _ansysNblock.xRange = NSMakeRange(numOfNNFields * nnFieldLength + 0 * 20, 20);
        _ansysNblock.yRange = NSMakeRange(numOfNNFields * nnFieldLength + 1 * 20, 20);
        _ansysNblock.zRange = NSMakeRange(numOfNNFields * nnFieldLength + 2 * 20, 20);
        _ansysNblock.xLineLength = _ansysNblock.xRange.location+_ansysNblock.xRange.length;
        _ansysNblock.yLineLength = _ansysNblock.yRange.location+_ansysNblock.yRange.length;
        _ansysNblock.zLineLength = _ansysNblock.zRange.location+_ansysNblock.zRange.length;
    } 
    else 
    {
        NSLog(@"node field ranges unknown: %@", ranges);
    } 
    
    
    return _ansysNblock;
}


+ (AnsysHelper *)makeEblockWithRanges:(NSString *)ranges withSolid:(BOOL)solidKey
{
    AnsysHelper *_ansysEblock = [[super alloc] init];
    
    ranges = [ranges stringByTrimmingCharactersInSet:[NSCharacterSet symbolCharacterSet]];
    NSInteger fieldLength = [[[ranges componentsSeparatedByCharactersInSet:[NSCharacterSet letterCharacterSet]]
                              lastObject] integerValue];    
    if (solidKey)
    {
        _ansysEblock.node1Range = NSMakeRange(11 * fieldLength, fieldLength);
        _ansysEblock.node2Range = NSMakeRange(12 * fieldLength, fieldLength);
        _ansysEblock.node3Range = NSMakeRange(13 * fieldLength, fieldLength);
        _ansysEblock.node4Range = NSMakeRange(14 * fieldLength, fieldLength);
        _ansysEblock.node5Range = NSMakeRange(15 * fieldLength, fieldLength);
        _ansysEblock.node6Range = NSMakeRange(16 * fieldLength, fieldLength);
        _ansysEblock.node7Range = NSMakeRange(17 * fieldLength, fieldLength);
        _ansysEblock.node8Range = NSMakeRange(18 * fieldLength, fieldLength);
        _ansysEblock.elementMaterialRange = NSMakeRange( 0 * fieldLength, fieldLength);
        _ansysEblock.elementTypeRange     = NSMakeRange( 1 * fieldLength, fieldLength);
        _ansysEblock.elementRealRange     = NSMakeRange( 2 * fieldLength, fieldLength);
        _ansysEblock.elementSectionRange  = NSMakeRange( 3 * fieldLength, fieldLength);
        _ansysEblock.elementNumberRange   = NSMakeRange(10 * fieldLength, fieldLength);
    }
    else
    {
        _ansysEblock.node1Range = NSMakeRange( 5 * fieldLength, fieldLength);
        _ansysEblock.node2Range = NSMakeRange( 6 * fieldLength, fieldLength);
        _ansysEblock.node3Range = NSMakeRange( 7 * fieldLength, fieldLength);
        _ansysEblock.node4Range = NSMakeRange( 8 * fieldLength, fieldLength);
        _ansysEblock.node5Range = NSMakeRange( 9 * fieldLength, fieldLength);
        _ansysEblock.node6Range = NSMakeRange(10 * fieldLength, fieldLength);
        _ansysEblock.node7Range = NSMakeRange(11 * fieldLength, fieldLength);
        _ansysEblock.node8Range = NSMakeRange(12 * fieldLength, fieldLength);
        _ansysEblock.elementMaterialRange = NSMakeRange( 3 * fieldLength, fieldLength); // ok
        //self.elementTypeRange           = NSMakeRange( 1 * fieldLength, fieldLength);
        _ansysEblock.elementRealRange     = NSMakeRange( 2 * fieldLength, fieldLength); // ok
        _ansysEblock.elementSectionRange  = NSMakeRange( 1 * fieldLength, fieldLength); // ok
        _ansysEblock.elementNumberRange   = NSMakeRange( 0 * fieldLength, fieldLength); // ok
    }
    return _ansysEblock;
}


- (NSArray *)extractSolidCubeIndexComponentsFromLine:(NSString *)aLine
{
    //Nodes Solid185 and Solid186
    //I, J, K, L, M, N, O, P
    //All elements must have eight nodes.
    
    if (aLine.length >= _node8Range.location + _node8Range.length) 
    {
        NSString *node1 = [[aLine substringWithRange:self.node1Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node2 = [[aLine substringWithRange:self.node2Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node3 = [[aLine substringWithRange:self.node3Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node4 = [[aLine substringWithRange:self.node4Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node5 = [[aLine substringWithRange:self.node5Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node6 = [[aLine substringWithRange:self.node6Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node7 = [[aLine substringWithRange:self.node7Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node8 = [[aLine substringWithRange:self.node8Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        
        if ([node3 isEqualToString:node4] && [node7 isEqualToString:node8]) 
        {
            // last two nodes are the same, i.e. either tetrahedal or Prism element
            if ([node5 isEqualToString:node6] && [node6 isEqualToString:node7]) 
            {
                //Tetrahedal element
                return [NSArray arrayWithObjects:node1,node2,node3,node5, nil];
            }
            else
            {
                //Prism element
                return [NSArray arrayWithObjects:node1,node2,node3,node5,node6,node7, nil];
            }
        } 
        else 
        {
            // eight node solid element 
            return [NSArray arrayWithObjects:node1,node2,node3,node4,node5,node6,node7,node8, nil];
        }  
    } 
    else if (aLine.length >= _node7Range.location + _node7Range.length) 
    {
        NSString *node1 = [[aLine substringWithRange:self.node1Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node2 = [[aLine substringWithRange:self.node2Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node3 = [[aLine substringWithRange:self.node3Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node4 = [[aLine substringWithRange:self.node4Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node5 = [[aLine substringWithRange:self.node5Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node6 = [[aLine substringWithRange:self.node6Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node7 = [[aLine substringWithRange:self.node7Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        
        if ([node3 isEqualToString:node4]) 
        {
            // last two nodes are the same, i.e. either tetrahedal or Prism element
            if ([node5 isEqualToString:node6] && [node6 isEqualToString:node7]) 
            {
                //Tetrahedal element
                return [NSArray arrayWithObjects:node1,node2,node3,node5, nil];
            }
            else
            {
                //Prism element
                return [NSArray arrayWithObjects:node1,node2,node3,node5,node6,node7, nil];
            }
        } 
    }
    else 
    {
        NSLog(@"Did not find at least 7 nodes in declaration of cube solid element: %@", aLine);
        return nil;
    }
    return nil;
}


- (NSArray *)extractSolidTetraIndexComponentsFromLine:(NSString *)aLine
{
    //Nodes Solid187 and Solid285
    //I, J, K, L (M, N, O, P is discarded for Solid187)
    
    if (aLine.length >= _node4Range.location + _node4Range.length) 
    {
        NSString *node1 = [[aLine substringWithRange:self.node1Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node2 = [[aLine substringWithRange:self.node2Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node3 = [[aLine substringWithRange:self.node3Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node4 = [[aLine substringWithRange:self.node4Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        
        //Tetrahedal element
        return [NSArray arrayWithObjects:node1,node2,node3,node4, nil];
        
    } 
    else 
    {
        NSLog(@"Did not find 4 nodes in declaration of tetrahedral solid element: %@", aLine);
        return nil;
    }
    return nil;
}


- (NSArray *)extractShellIndexComponentsFromLine:(NSString *)aLine
{
    if (aLine.length >= self.node4LineLength) 
    {
        NSString *node1 = [[aLine substringWithRange:self.node1Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node2 = [[aLine substringWithRange:self.node2Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node3 = [[aLine substringWithRange:self.node3Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node4 = [[aLine substringWithRange:self.node4Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        
        if ([node3 isEqualToString:node4]) {
            // last two nodes are the same, i.e. triangle element
            return [NSArray arrayWithObjects:node1,node2,node3, nil];
        } else {
            // quad element / or degenerate beam element
            return [NSArray arrayWithObjects:node1,node2,node3,node4, nil];
        }  
    } 
    else if (aLine.length >= self.node3LineLength) 
    {
        NSString *node1 = [[aLine substringWithRange:self.node1Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node2 = [[aLine substringWithRange:self.node2Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        NSString *node3 = [[aLine substringWithRange:self.node3Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
        // triangle or beam element
        return [NSArray arrayWithObjects:node1,node2,node3, nil];
    } 
    else 
    {
        NSLog(@"only found two nodes in declaration of shell element: %@", aLine);
        return nil;
    } 
}

- (NSArray *)extractBeamIndexComponentsFromLine:(NSString *)aLine
{
    /*
     // **** Here, add support for degenerate beam elements *****
     if (aLine.length >= self.node3LineLength) 
     {
     NSString *node1 = [[aLine substringWithRange:self.node1Range] stringByReplacingOccurrencesOfString:@" " withString:@""];
     NSString *node2 = [[aLine substringWithRange:self.node2Range] stringByReplacingOccurrencesOfString:@" " withString:@""];
     NSString *node3 = [[aLine substringWithRange:self.node3Range] stringByReplacingOccurrencesOfString:@" " withString:@""];
     return [NSArray arrayWithObjects:node1,node2,node3, nil];
     } 
     else*/ if (aLine.length >= self.node2LineLength) 
     {
         NSString *node1 = [[aLine substringWithRange:self.node1Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
         NSString *node2 = [[aLine substringWithRange:self.node2Range] stringByTrimmingCharactersInSet:_whiteSpaceSet];
         return [NSArray arrayWithObjects:node1,node2, nil];
     }
     else 
     {
         NSLog(@"only found one node in declaration of beam element: %@", aLine);
         return nil;
     } 
}

- (ElementProperties)extractElementPropertiesFromLine:(NSString *)aLine
{
    ElementProperties newElemProp;
    
    if (aLine.length >= 40) // this number should be the max range necessary
    {
        newElemProp.elementNo  = [[aLine substringWithRange:self.elementNumberRange] integerValue];
        newElemProp.realNo     = [[aLine substringWithRange:self.elementRealRange] integerValue];
        newElemProp.materialNo = [[aLine substringWithRange:self.elementMaterialRange] integerValue];
        newElemProp.sectionNo  = [[aLine substringWithRange:self.elementSectionRange] integerValue];
    } 
    else 
    {
        NSLog(@"Element properties not found in line (line too short): %@", aLine);
    }
    return newElemProp;
}


+ (AnsysMaterial)extractMaterialPropertyFromMPLine:(NSString *)aLine separatedBy:(NSCharacterSet *)characterSet
{
    AnsysMaterial newMat;
    NSArray *matComponents = [aLine componentsSeparatedByCharactersInSet:characterSet];
    
    if (matComponents.count >= 4) {
        newMat.matNo = [[matComponents objectAtIndex:2] integerValue];
        if ([@"dens" isEqualToString:[matComponents objectAtIndex:1]]) {
            newMat.dens = [[matComponents objectAtIndex:3] integerValue];
        }
        else if ([@"ex" isEqualToString:[matComponents objectAtIndex:1]]) {
            newMat.eX = [[matComponents objectAtIndex:3] integerValue];
        }
        else if ([@"nuxy" isEqualToString:[matComponents objectAtIndex:1]]) {
            newMat.nuXY = [[matComponents objectAtIndex:3] integerValue];
        }
    }
    return newMat;
}


+ (GLKVector3)getNormalizedNormalVectorNode1:(NSArray *)node1 node2:(NSArray *)node2 andNode3:(NSArray *)node3 
{
    GLKVector3 vec1 = GLKVector3Make([[node2 objectAtIndex:0] floatValue] - [[node1 objectAtIndex:0] floatValue], 
                                     [[node2 objectAtIndex:1] floatValue] - [[node1 objectAtIndex:1] floatValue], 
                                     [[node2 objectAtIndex:2] floatValue] - [[node1 objectAtIndex:2] floatValue]);
    
    GLKVector3 vec2 = GLKVector3Make([[node3 objectAtIndex:0] floatValue] - [[node1 objectAtIndex:0] floatValue], 
                                     [[node3 objectAtIndex:1] floatValue] - [[node1 objectAtIndex:1] floatValue], 
                                     [[node3 objectAtIndex:2] floatValue] - [[node1 objectAtIndex:2] floatValue]);
    
    return GLKVector3Normalize(GLKVector3CrossProduct(vec1, vec2));
}


+ (NSString *)stringFromElementProperties:(ElementProperties)elementProperties
{    
    return [NSString stringWithFormat:@"(No: %d, Mat: %d, Sec: %d, Real: %d)", elementProperties.elementNo, elementProperties.materialNo, elementProperties.sectionNo, elementProperties.realNo];
}

+ (NSString *)stringFromMaterialProperties:(AnsysMaterial)matProperties
{    
    return [NSString stringWithFormat:@"(MatNo: %d, Dens: %f, Ex: %f, NUxy: %f)", matProperties.matNo, matProperties.dens, matProperties.eX, matProperties.nuXY];
}


@end
