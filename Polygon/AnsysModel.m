//
//  AnsysModel.m
//  FEViewer2
//
//  Created by Christian Hansen on 3/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AnsysModel.h"
#import "ColorArrays.h"

@interface AnsysModel () {
    //NSMutableDictionary *materialNumbers;
    NSCharacterSet *spaceAndNewLineSet;
}

@property (nonatomic, strong) NSDictionary *validSolidCubeETypes;
@property (nonatomic, strong) NSDictionary *validSolidTetraETypes;
@property (nonatomic, strong) NSDictionary *validShellETypes;
@property (nonatomic, strong) NSDictionary *validBeamETypes;
@property (nonatomic) MemoryReadingFormat readMode;
@property (nonatomic) BOOL bigModelLimitIsVerified;
@property (nonatomic) BOOL modelParsingShouldContinue;

@end

@implementation AnsysModel

+ (AnsysModel *)ansysFileWithPath:(NSString *)path andDelegate:(id<AnsysModelDelegate>)delegatingObject andSettings:(NSDictionary *)settings
{
    NSUInteger fileSize = [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] objectForKey:NSFileSize] integerValue];
    AnsysModel *_ansysModel = [[super alloc] init];
    _ansysModel.delegate = delegatingObject;
    
    _ansysModel.readMode = [[settings valueForKey:@"MemoryReadFormat"] intValue];
    _ansysModel.readMode = kFullMem;
    
    [_ansysModel _notifyParsingProgressOnMainQueue:0.02f];

    dispatch_async(dispatch_get_main_queue(), ^{ [_ansysModel.delegate startedParsingNodes]; });;
    [_ansysModel nodesWithAnsysFile:path fileSize:fileSize];
    dispatch_async(dispatch_get_main_queue(), ^{ [_ansysModel.delegate finishedParsingNodes:_ansysModel.numOfVertices]; });;
    
    if (_ansysModel.modelParsingShouldContinue)
    {
        [_ansysModel elementsWithAnsysFile:path fileSize:fileSize];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_ansysModel.delegate finishedParsingElements:_ansysModel.numOfSolidCubeVertices / 36 + _ansysModel.numOfSolidTetraVertices / 12 + _ansysModel.numOfQuadFaces + _ansysModel.numOfTriFaces + _ansysModel.numOfBeams];
        });
        
        [_ansysModel _notifyParsingProgressOnMainQueue:0.87f];
        [_ansysModel replaceOriginalIndexesWithNew];
        [_ansysModel _notifyParsingProgressOnMainQueue:0.90f];
        [_ansysModel calculateBoundingBoxOfVertices];
        [_ansysModel _notifyParsingProgressOnMainQueue:0.93f];
        [_ansysModel pullOutVerticesAsTriangles];
        [_ansysModel pullOutQuadsAsTriangles];
        [_ansysModel _notifyParsingProgressOnMainQueue:0.97f];
        [_ansysModel combineTrisAndQuads];
        [_ansysModel pullOutIndexesForEdges];
        _ansysModel.colorMode = kMaterialColor;
        if (_ansysModel.readMode == kMediumMem || _ansysModel.readMode == kFullMem) 
        {
            [_ansysModel setColorsOfLines];
        }
        [_ansysModel _notifyParsingProgressOnMainQueue:0.99f];
        if (_ansysModel.readMode == kMediumMem || _ansysModel.readMode == kFullMem)
        {
            [_ansysModel setColorsOfElementsWithTranparency:[[settings objectForKey:@"transparency"] floatValue]];
        }
        [_ansysModel _notifyParsingProgressOnMainQueue:1.0f];
    }
    
    return _ansysModel;
}


- (void)_notifyParsingProgressOnMainQueue:(CGFloat)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate parsingProgress:progress];
    });
}


#define MEM_VERTICES 10000
#define MEM_ELEMENTS 10000

#define NO_OF_MATPROP 10000


- (void)nodesWithAnsysFile:(NSString *)ansysFile fileSize:(NSUInteger)fileSize
{    
    NSInputStream *myStream = [NSInputStream inputStreamWithFileAtPath:ansysFile];
    
    AnsysHelper *ansysNBlock = nil;
    NSCharacterSet *commaCharacter = [NSCharacterSet characterSetWithCharactersInString:@","];
    spaceAndNewLineSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *decimalCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
    self.modelParsingShouldContinue = YES;
    [myStream open];
    uint8_t buffer[65536];
    NSMutableArray *lines;
    
    NSString *lastLineInBuffer = @"";
    self.validSolidCubeETypes = [NSMutableDictionary dictionary];
    self.validSolidTetraETypes = [NSMutableDictionary dictionary];
    self.validShellETypes = [NSMutableDictionary dictionary];
    self.validBeamETypes = [NSMutableDictionary dictionary];
    
    BOOL insideNblock = NO;
    self.origToNew = [NSMutableDictionary dictionary];
    NSUInteger vertexCount = 0;
    AnsysSection lastSection;
    NSUInteger memoryCounter = 2;
     
    self.vertexPositions = calloc(memoryCounter*MEM_VERTICES, sizeof(GLKVector3));
    if (self.readMode == kMediumMem || self.readMode == kFullMem) {
        self.matProperties = calloc(NO_OF_MATPROP, sizeof(AnsysMaterial));
        self.sectionProperties = calloc(NO_OF_MATPROP, sizeof(AnsysSection));
    }
    
    NSUInteger allBytesRead = 0;
    CGFloat parseRatio = 0.4;
    NSString *firstLineInBuffer;

    while ([myStream hasBytesAvailable] && _modelParsingShouldContinue)
    {
        NSUInteger bytesRead = [myStream read:buffer maxLength:sizeof(buffer)];
        allBytesRead += bytesRead;
        [self.delegate parsingProgress:(CGFloat)allBytesRead/fileSize*parseRatio];
        NSString *myString = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSASCIIStringEncoding];
        lines = [NSMutableArray arrayWithArray:[myString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
        myString = @"";
        if (lines.count > 0)
        {
            firstLineInBuffer = [lines objectAtIndex:0];
            [lines replaceObjectAtIndex:0 withObject:[lastLineInBuffer stringByAppendingString:firstLineInBuffer]];
        }
        
        if ([lines count] > 0)
            for (NSUInteger i = 0; i < [lines count]-1; i++)
            {
                if (vertexCount >= (memoryCounter-1)*MEM_VERTICES) {
                    self.vertexPositions = realloc(self.vertexPositions, memoryCounter*MEM_VERTICES*sizeof(GLKVector3));
                    memoryCounter++;
                }
                NSString *aLine = [lines objectAtIndex:i];
                NSString *aCleanLine = [[aLine stringByTrimmingCharactersInSet:spaceAndNewLineSet] lowercaseString];
                
                if ([aCleanLine hasPrefix:@"!"])
                {
                    // Comment line, do nothing
                }
                else if ([aCleanLine hasPrefix:@"n,"] && !insideNblock && [aCleanLine rangeOfString:@"_"].length == 0)
                {
                    [self.origToNew setValue:[NSNumber numberWithInteger:vertexCount] forKey:[AnsysHelper extractNodeNumberFromLineWithCommaSeparation:aLine]];
                    self.vertexPositions[vertexCount] = [AnsysHelper extractVertexPositionFromLineWithCommaSeparation:aLine];
                    vertexCount++;
                    NSLog(@"aLine: %@", aLine);
                }
                else if ([aCleanLine hasPrefix:@"nblock,"])
                {
                    insideNblock = YES;
                }
                else if ([aCleanLine hasPrefix:@"n,"] || [aCleanLine hasPrefix:@"-1"] || [aCleanLine isEqualToString:@"0"])
                {
                    insideNblock = NO;
                }
                else if (insideNblock)
                {
                    if ([aCleanLine hasPrefix:@"("])
                    { //first line of nblock sets nblock ranges
                        ansysNBlock = [AnsysHelper makeNblockWithRanges:aCleanLine];
                    }
                    else if ([aCleanLine rangeOfCharacterFromSet:decimalCharacterSet].location == 0)
                    {
                        [self.origToNew setValue:[NSNumber numberWithInteger:vertexCount] forKey:[ansysNBlock extractNodeNumberFromLine:aLine]];
                        self.vertexPositions[vertexCount] = [ansysNBlock extractVertexPositionFromLine:aLine];
                        //NSLog(@"self.vertexPositions[vertexCount].vertex: %@", NSStringFromGLKVector3(self.vertexPositions[vertexCount].vertex));
                        vertexCount++;
                        if (!_bigModelLimitIsVerified && vertexCount > BIG_MODEL_LIMIT)
                        {
                            if (![self.delegate shouldContinueAfterNodeCountLimitPassed:vertexCount forModel:ansysFile.lastPathComponent])
                            {
                                self.modelParsingShouldContinue = NO;
                            }
                            _bigModelLimitIsVerified = YES;
                        }
                    }
                }
                else if ([aCleanLine hasPrefix:@"et,"])
                {
                    NSArray *eTypeDefinition = [[aCleanLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@","];
                    if ([eTypeDefinition count] > 2)
                    {
                        NSUInteger elementTypeNumber = [[[eTypeDefinition objectAtIndex:2] stringByTrimmingCharactersInSet:[decimalCharacterSet invertedSet]] integerValue];
                        NSString *eTypeKey = [[eTypeDefinition objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        
                        switch (elementTypeNumber)
                        {
                            case 3:
                                [self.validBeamETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 4:
                                [self.validBeamETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 23:
                                [self.validBeamETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 24:
                                [self.validBeamETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 44:
                                [self.validBeamETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 54:
                                [self.validBeamETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 188:
                                [self.validBeamETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 189:
                                [self.validBeamETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 63:
                                [self.validShellETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 93:
                                [self.validShellETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 181:
                                [self.validShellETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 281:
                                [self.validShellETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 154:
                                [self.validShellETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 185:
                                [self.validSolidCubeETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 186:
                                [self.validSolidCubeETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 190:
                                [self.validSolidCubeETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 187:
                                [self.validSolidTetraETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            case 285:
                                [self.validSolidTetraETypes setValue:[NSNumber numberWithBool:YES] forKey:eTypeKey];
                                break;
                            default:
                                break;
                        }
                    }
                    else
                    {
                        NSLog(@"Element type definition wrong, not 3 components in defintion: %@", aLine);
                    }
                }
                else if (self.readMode == kMediumMem || self.readMode == kFullMem)
                {
                    if ([aCleanLine hasPrefix:@"mp,"])
                    {
                        AnsysMaterial newMat;
                        BOOL isNewMaterial = YES;
                        BOOL isUsedMatPar = YES;
                        NSArray *matComponents = [aCleanLine componentsSeparatedByCharactersInSet:commaCharacter];
                        if (matComponents.count >= 4) {
                            newMat.matNo = [[matComponents objectAtIndex:2] integerValue];
                            
                            if ([[matComponents objectAtIndex:1] isEqualToString:@"dens" ]) {
                                newMat.dens = [[matComponents objectAtIndex:3] floatValue];
                                for (NSUInteger matCounter = 0; matCounter < _numOfMatProperties; matCounter++) {
                                    if (newMat.matNo == self.matProperties[matCounter].matNo) {
                                        self.matProperties[matCounter].dens = newMat.dens;
                                        isNewMaterial = NO;
                                        break;
                                    }
                                }
                            }
                            else if ([[matComponents objectAtIndex:1] isEqualToString:@"ex"]) {
                                newMat.eX = [[matComponents objectAtIndex:3] doubleValue];
                                for (NSUInteger matCounter = 0; matCounter < _numOfMatProperties; matCounter++) {
                                    if (newMat.matNo == self.matProperties[matCounter].matNo) {
                                        self.matProperties[matCounter].eX = newMat.eX;
                                        isNewMaterial = NO;
                                        break;
                                    }
                                }
                            }
                            else if ([[matComponents objectAtIndex:1] isEqualToString:@"nuxy"]) {
                                newMat.nuXY = [[matComponents objectAtIndex:3] floatValue];
                                for (NSUInteger matCounter = 0; matCounter < _numOfMatProperties; matCounter++) {
                                    if (newMat.matNo == self.matProperties[matCounter].matNo) {
                                        self.matProperties[matCounter].nuXY = newMat.nuXY;
                                        isNewMaterial = NO;
                                        break;
                                    }
                                }
                            }
                            else {
                                isUsedMatPar = NO;
                            }
                            if (isNewMaterial && isUsedMatPar) {
                                self.matProperties[_numOfMatProperties] = newMat;
                                _numOfMatProperties++;
                            }
                        }
                    }
                    else if ([aCleanLine hasPrefix:@"mpdata,"])
                    {
                        AnsysMaterial newMat;
                        BOOL isNewMaterial = YES;
                        BOOL isUsedMatPar = YES;
                        NSArray *matComponents = [aCleanLine componentsSeparatedByCharactersInSet:commaCharacter];
                        if (matComponents.count >= 7) {
                            newMat.matNo = [[matComponents objectAtIndex:4] integerValue];
                            
                            if ([[matComponents objectAtIndex:3] isEqualToString:@"dens" ]) {
                                newMat.dens = [[matComponents objectAtIndex:6] floatValue];
                                for (NSUInteger matCounter = 0; matCounter < _numOfMatProperties; matCounter++) {
                                    if (newMat.matNo == self.matProperties[matCounter].matNo) {
                                        self.matProperties[matCounter].dens = newMat.dens;
                                        isNewMaterial = NO;
                                        break;
                                    }
                                }
                            }
                            else if ([[matComponents objectAtIndex:3] isEqualToString:@"ex"]) {
                                newMat.eX = [[matComponents objectAtIndex:6] doubleValue];
                                for (NSUInteger matCounter = 0; matCounter < _numOfMatProperties; matCounter++) {
                                    if (newMat.matNo == self.matProperties[matCounter].matNo) {
                                        self.matProperties[matCounter].eX = newMat.eX;
                                        isNewMaterial = NO;
                                        break;
                                    }
                                }
                            }
                            else if ([[matComponents objectAtIndex:3] isEqualToString:@"nuxy"]) {
                                newMat.nuXY = [[matComponents objectAtIndex:6] floatValue];
                                for (NSUInteger matCounter = 0; matCounter < _numOfMatProperties; matCounter++) {
                                    if (newMat.matNo == self.matProperties[matCounter].matNo) {
                                        self.matProperties[matCounter].nuXY = newMat.nuXY;
                                        isNewMaterial = NO;
                                        break;
                                    }
                                }
                            }
                            else {
                                isUsedMatPar = NO;
                            }
                            if (isNewMaterial && isUsedMatPar) {
                                self.matProperties[_numOfMatProperties] = newMat;
                                _numOfMatProperties++;
                            }
                        }
                    }
                    else if ([aCleanLine hasPrefix:@"sectype,"])
                    {
                        AnsysSection newSection;
                        BOOL isNewSection = YES;
                        
                        NSArray *secComponents = [aCleanLine componentsSeparatedByCharactersInSet:commaCharacter];
                        if (secComponents.count >= 2) {
                            newSection.secNo = [[secComponents objectAtIndex:1] integerValue];
                            
                            if ([[secComponents objectAtIndex:2] isEqualToString:@"shell" ]) {
                                newSection.secType = kShell;
                            } else if ([[secComponents objectAtIndex:2] isEqualToString:@"beam" ]) {
                                newSection.secType = kBeam;
                            } else {
                                newSection.secType = kUnknown;
                            }
                            
                            lastSection.secNo = newSection.secNo;
                            lastSection.secType = newSection.secType;
                            
                            
                            for (NSUInteger secCounter = 0; secCounter < _numOfSecProperties; secCounter++) {
                                if (newSection.secNo == self.sectionProperties[secCounter].secNo) {
                                    self.sectionProperties[secCounter].secType = newSection.secType;
                                    isNewSection = NO;
                                    break;
                                }
                            }
                            if (isNewSection) {
                                self.sectionProperties[_numOfSecProperties] = newSection;
                                _numOfSecProperties++;
                            }
                        }
                    }
                    else if ([aCleanLine hasPrefix:@"secdata,"])
                    {
                        NSArray *secComponents = [aCleanLine componentsSeparatedByCharactersInSet:commaCharacter];
                        if (secComponents.count >= 5) {
                            lastSection.val1 = [[secComponents objectAtIndex:1] floatValue];
                            lastSection.val2 = [[secComponents objectAtIndex:2] floatValue];
                            lastSection.val3 = [[secComponents objectAtIndex:3] floatValue];
                            lastSection.val4 = [[secComponents objectAtIndex:4] floatValue];
                        } else if (secComponents.count >= 4) {
                            lastSection.val1 = [[secComponents objectAtIndex:1] floatValue];
                            lastSection.val2 = [[secComponents objectAtIndex:2] floatValue];
                            lastSection.val3 = [[secComponents objectAtIndex:3] floatValue];
                        } else if (secComponents.count >= 3) {
                            lastSection.val1 = [[secComponents objectAtIndex:1] floatValue];
                            lastSection.val2 = [[secComponents objectAtIndex:2] floatValue];
                        } else if (secComponents.count >= 2) {
                            lastSection.val1 = [[secComponents objectAtIndex:1] floatValue];
                        }
                        for (NSUInteger secCounter = 0; secCounter < _numOfSecProperties; secCounter++) {
                            if (lastSection.secNo == self.sectionProperties[secCounter].secNo) {
                                self.sectionProperties[secCounter] = lastSection;
                                break;
                            }
                        }
                    } 
                }
            }
        lastLineInBuffer = [lines lastObject];
        lines = nil;
    }
    
    [myStream close];
    myStream = nil;
    
    self.numOfVertices = vertexCount;
    NSLog(@"self.numOfSecProperties: %d", self.numOfSecProperties); 

//    for (NSUInteger i = 0; i < self.numOfSecProperties; i++) {
//        NSLog(@"%i %i %f %f %f %f", self.sectionProperties[i].secNo, self.sectionProperties[i].secType, self.sectionProperties[i].val1, self.sectionProperties[i].val2, self.sectionProperties[i].val3, self.sectionProperties[i].val4);
//    }    
    NSLog(@"self.numOfMatProperties: %d", self.numOfMatProperties);
}



- (void)elementsWithAnsysFile:(NSString *)ansysFile fileSize:(NSUInteger)fileSize
{        
    NSInputStream *myStream = [NSInputStream inputStreamWithFileAtPath:ansysFile];
    AnsysHelper *ansysEBlock;
    //materialNumbers = [NSMutableDictionary dictionary];
    
    [myStream open];
    uint8_t buffer[65536];
    
    NSString *lastLineInBuffer = @"";
    BOOL insideEblock = NO;
    BOOL solidKey;
    NSUInteger triFaceCount = 0;
    NSUInteger quadFaceCount = 0;
    _numOfSolidCubeVertices = 0;
    _numOfSolidPrismVertices = 0;
    _numOfSolidTetraVertices = 0;
    NSUInteger beamCount = 0;
    
    NSUInteger solidCubeMemCounter, solidPrismMemCounter, solidTetraMemCounter, quadMemCounter,triMemCounter, beamMemCounter, triPropMemCounter, quadPropMemCounter;
    solidCubeMemCounter = solidPrismMemCounter = solidTetraMemCounter = quadMemCounter = triMemCounter = beamMemCounter = triPropMemCounter = quadPropMemCounter = 2;

    self.triFaces = calloc(MEM_ELEMENTS, sizeof(TriFace)); 
    self.quadFaces = calloc(MEM_ELEMENTS, sizeof(QuadFace));
    NSLog(@"sizeof(TriFace): %lu, sizeof(QuadFace): %lu, sizeof(Vertex): %lu", sizeof(TriFace), sizeof(QuadFace), sizeof(Vertex));
    self.triVerticesFromCubeSolids = calloc(MEM_ELEMENTS, sizeof(Vertex));
    self.triVerticesFromPrismSolids = calloc(MEM_ELEMENTS, sizeof(Vertex));
    self.triVerticesFromTetraSolids = calloc(MEM_ELEMENTS, sizeof(Vertex));

    self.lines = calloc(MEM_ELEMENTS, sizeof(Line));
    
    if (self.readMode == kMediumMem || self.readMode == kFullMem) {
        self.solidCubeElemProp = calloc(MEM_ELEMENTS, sizeof(ElementProperties));
        self.solidPrismElemProp = calloc(MEM_ELEMENTS, sizeof(ElementProperties));
        self.solidTetraElemProp = calloc(MEM_ELEMENTS, sizeof(ElementProperties));
        self.quadElemProp = calloc(MEM_ELEMENTS, sizeof(ElementProperties));
        self.triElemProp = calloc(MEM_ELEMENTS, sizeof(ElementProperties));
        self.beamElemProp = calloc(MEM_ELEMENTS, sizeof(ElementProperties));
    }
    
    NSUInteger allBytesRead = 0;
    CGFloat parseRatio = 0.45;
    NSString *firstLineInBuffer;

    while ([myStream hasBytesAvailable])
    {
        NSUInteger bytesRead = [myStream read:buffer maxLength:sizeof(buffer)];
        allBytesRead += bytesRead;
        [self.delegate parsingProgress:(CGFloat)allBytesRead/fileSize*parseRatio+0.4];
        NSString *myString = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSASCIIStringEncoding];
        NSMutableArray *lines = [NSMutableArray arrayWithArray:[myString componentsSeparatedByString:@"\n"]];
        myString = @"";
        if (lines.count > 0)
        {
            firstLineInBuffer = [lines objectAtIndex:0];
            [lines replaceObjectAtIndex:0 withObject:[lastLineInBuffer stringByAppendingString:firstLineInBuffer]];
        }
        
        if ([lines count] > 0)
            for (NSUInteger i = 0; i < [lines count]-1; i++)
        {
            if (_numOfSolidCubeVertices >= (solidCubeMemCounter-1)*MEM_ELEMENTS)
            {
                self.triVerticesFromCubeSolids = realloc(self.triVerticesFromCubeSolids, (solidCubeMemCounter+1)*MEM_ELEMENTS*sizeof(Vertex));
                if (self.readMode == kMediumMem || self.readMode == kFullMem) 
                {
                    self.solidCubeElemProp = realloc(self.solidCubeElemProp, (solidCubeMemCounter+1)*MEM_ELEMENTS*sizeof(ElementProperties));
                }                
                solidCubeMemCounter++;
            }
            if (_numOfSolidPrismVertices >= (solidPrismMemCounter-1)*MEM_ELEMENTS)
            {
                self.triVerticesFromPrismSolids = realloc(self.triVerticesFromPrismSolids, (solidPrismMemCounter+1)*MEM_ELEMENTS*sizeof(Vertex));
                if (self.readMode == kMediumMem || self.readMode == kFullMem)
                {
                    self.solidPrismElemProp = realloc(self.solidPrismElemProp, (solidPrismMemCounter+1)*MEM_ELEMENTS*sizeof(ElementProperties));
                }
                solidPrismMemCounter++;
            }
            if (_numOfSolidTetraVertices >= (solidTetraMemCounter-1)*MEM_ELEMENTS)
            {
                self.triVerticesFromTetraSolids = realloc(self.triVerticesFromTetraSolids, (solidTetraMemCounter+1)*MEM_ELEMENTS*sizeof(Vertex));
                if (self.readMode == kMediumMem || self.readMode == kFullMem)
                {
                    self.solidTetraElemProp = realloc(self.solidTetraElemProp, (solidTetraMemCounter+1)*MEM_ELEMENTS*sizeof(ElementProperties));
                }
                solidTetraMemCounter++;
            }
            if (quadFaceCount >= (quadMemCounter-1)*MEM_ELEMENTS)
            {
                self.quadFaces = realloc(self.quadFaces, quadMemCounter*MEM_ELEMENTS*sizeof(QuadFace));
                if (self.readMode == kMediumMem || self.readMode == kFullMem) 
                {
                    self.quadElemProp = realloc(self.quadElemProp, quadMemCounter*MEM_ELEMENTS*sizeof(ElementProperties));
                }
                quadMemCounter++;
            }
            if (triFaceCount >= (triMemCounter-1)*MEM_ELEMENTS) 
            {
                self.triFaces = realloc(self.triFaces, triMemCounter*MEM_ELEMENTS*sizeof(TriFace));
                if (self.readMode == kMediumMem || self.readMode == kFullMem) 
                {
                    self.triElemProp = realloc(self.triElemProp, triMemCounter*MEM_ELEMENTS*sizeof(ElementProperties));
                }
                triMemCounter++;
            }
            if (beamCount >= (beamMemCounter-1)*MEM_ELEMENTS) 
            {
                self.lines = realloc(self.lines, beamMemCounter*MEM_ELEMENTS*sizeof(Line));
                if (self.readMode == kMediumMem || self.readMode == kFullMem) 
                {
                    self.beamElemProp = realloc(self.beamElemProp, beamMemCounter*MEM_ELEMENTS*sizeof(ElementProperties));
                }
                beamMemCounter++;
            }
            
            NSString *aLine = [lines objectAtIndex:i];
            NSString *aCleanLine = [[aLine stringByTrimmingCharactersInSet:spaceAndNewLineSet] lowercaseString];
            if ([aCleanLine hasPrefix:@"!"]) 
            {
                // Comment line - do nothing
            } 
            else if ([aCleanLine hasPrefix:@"e,"] && !insideEblock) 
            {
                //NSLog(@"Unblocked element formulation or unknown: %@", aLine);
            } 
            else if ([aCleanLine hasPrefix:@"eblock,"]) 
            {
                insideEblock = YES;
                if ([aCleanLine rangeOfString:@"solid"].length)
                {
                    solidKey = YES;
                } else {
                    solidKey = NO;
                }
            } 
            else if (insideEblock && [aCleanLine hasPrefix:@"-1"]) 
            {
                insideEblock = NO;
            } 
            else if (insideEblock) 
            {
                if ([aCleanLine hasPrefix:@"("]) 
                { //first line of eblock sets eblock ranges
                    ansysEBlock = [AnsysHelper makeEblockWithRanges:aCleanLine withSolid:solidKey];
                }
                else if ([self isSolidCubeElement:aLine withValidRange:ansysEBlock.elementTypeRange])
                {
#warning this is in this method that "PLM Ural - Delcam-Ural.inp" crashes
                    NSArray *elementIndicies = [ansysEBlock extractSolidCubeIndexComponentsFromLine:aLine];
                    if ([elementIndicies count] == 8) 
                    {
                        // pull out position values for each node number
                        //I, J, K, L, M, N, O, P (Solid185 and Solid186 - discarding midside nodes on Solid186)
                        
                        self.solidCubeElemProp[_numOfSolidCubeVertices] = [ansysEBlock extractElementPropertiesFromLine:aLine];
                        for (NSInteger j = 1; j<36; j++) 
                        {
                            self.solidCubeElemProp[_numOfSolidCubeVertices+j] = self.solidCubeElemProp[_numOfSolidCubeVertices];
                        }
                        GLKVector3 vertexI = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:0]];
                        GLKVector3 vertexJ = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:1]];
                        GLKVector3 vertexK = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:2]];
                        GLKVector3 vertexL = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:3]];
                        GLKVector3 vertexM = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:4]];
                        GLKVector3 vertexN = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:5]];
                        GLKVector3 vertexO = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:6]];
                        GLKVector3 vertexP = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:7]];

                        [self addTriangle:vertexJ 
                                position2:vertexI 
                             andPosition3:vertexL 
                                  toArray:self.triVerticesFromCubeSolids
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        
                        [self addTriangle:vertexL 
                                position2:vertexK 
                             andPosition3:vertexJ 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        
                        // face 2
                        [self addTriangle:vertexM 
                                position2:vertexI 
                             andPosition3:vertexJ 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        
                        [self addTriangle:vertexJ 
                                position2:vertexN 
                             andPosition3:vertexM 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        
                        // face 3
                        [self addTriangle:vertexJ 
                                position2:vertexK 
                             andPosition3:vertexO 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        
                        [self addTriangle:vertexO 
                                position2:vertexN 
                             andPosition3:vertexJ 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        
                        // face 4
                        [self addTriangle:vertexN 
                                position2:vertexO 
                             andPosition3:vertexP 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        [self addTriangle:vertexP 
                                position2:vertexM 
                             andPosition3:vertexN 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        // face 5
                        [self addTriangle:vertexK 
                                position2:vertexL 
                             andPosition3:vertexP 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3; 
                        
                        [self addTriangle:vertexP 
                                position2:vertexO 
                             andPosition3:vertexK 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                        
                        // face 6
                        [self addTriangle:vertexL 
                                position2:vertexI 
                             andPosition3:vertexM 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;

                        [self addTriangle:vertexM 
                                position2:vertexP 
                             andPosition3:vertexL 
                                  toArray:self.triVerticesFromCubeSolids 
                                  counter:_numOfSolidCubeVertices];
                        _numOfSolidCubeVertices += 3;
                    }
                    else if ([elementIndicies count] == 6)
                    {
                        self.solidPrismElemProp[_numOfSolidCubeVertices] = [ansysEBlock extractElementPropertiesFromLine:aLine];
                        for (NSInteger j = 1; j<24; j++)
                        {
                            self.solidPrismElemProp[_numOfSolidCubeVertices+j] = self.solidPrismElemProp[_numOfSolidCubeVertices];
                        }
                        GLKVector3 vertexI = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:0]];
                        GLKVector3 vertexJ = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:1]];
                        GLKVector3 vertexK = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:2]];
                        GLKVector3 vertexM = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:4]];
                        GLKVector3 vertexN = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:5]];
                        GLKVector3 vertexO = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:6]];
                        
                        // rect 1
                        [self addTriangle:vertexJ
                                position2:vertexN
                             andPosition3:vertexM
                                  toArray:self.triVerticesFromPrismSolids
                                  counter:_numOfSolidPrismVertices];
                        _numOfSolidPrismVertices += 3;
                        
                        [self addTriangle:vertexM
                                position2:vertexI
                             andPosition3:vertexJ
                                  toArray:self.triVerticesFromPrismSolids
                                  counter:_numOfSolidPrismVertices];
                        _numOfSolidPrismVertices += 3;
                        
                        // rect 2
                        [self addTriangle:vertexJ
                                position2:vertexK
                             andPosition3:vertexO
                                  toArray:self.triVerticesFromPrismSolids
                                  counter:_numOfSolidPrismVertices];
                        _numOfSolidPrismVertices += 3;
                        
                        [self addTriangle:vertexO
                                position2:vertexN
                             andPosition3:vertexJ
                                  toArray:self.triVerticesFromPrismSolids
                                  counter:_numOfSolidPrismVertices];
                        _numOfSolidPrismVertices += 3;
                        
                        // rect 3
                        [self addTriangle:vertexK
                                position2:vertexI
                             andPosition3:vertexM
                                  toArray:self.triVerticesFromPrismSolids
                                  counter:_numOfSolidPrismVertices];
                        _numOfSolidPrismVertices += 3;
                        
                        [self addTriangle:vertexM
                                position2:vertexO
                             andPosition3:vertexK
                                  toArray:self.triVerticesFromPrismSolids
                                  counter:_numOfSolidPrismVertices];
                        _numOfSolidPrismVertices += 3;
                        
                        // tri 1
                        [self addTriangle:vertexM
                                position2:vertexN
                             andPosition3:vertexO
                                  toArray:self.triVerticesFromPrismSolids
                                  counter:_numOfSolidPrismVertices];
                        _numOfSolidPrismVertices += 3;
                        
                        // tri 2
                        [self addTriangle:vertexK
                                position2:vertexJ
                             andPosition3:vertexI
                                  toArray:self.triVerticesFromPrismSolids
                                  counter:_numOfSolidPrismVertices];
                        _numOfSolidPrismVertices += 3;
                    }
                    else if ([elementIndicies count] == 4)
                    {
                        // pull out position values for each node number
                        //I, J, K, L, (Solid187 and Solid285 - discarding midside nodes on Solid187)
                        
                        self.solidTetraElemProp[_numOfSolidTetraVertices] = [ansysEBlock extractElementPropertiesFromLine:aLine];
                        for (NSInteger j = 1; j<12; j++)
                        {
                            self.solidTetraElemProp[_numOfSolidTetraVertices + j] = self.solidTetraElemProp[_numOfSolidTetraVertices];
                        }
                        // Directly create triangles from positions
                        // for the 4 triangles save the corresponding element property
                        //A 'cube',
                        GLKVector3 vertexI = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:0]];
                        GLKVector3 vertexJ = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:1]];
                        GLKVector3 vertexK = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:2]];
                        GLKVector3 vertexL = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:3]];
                        
                        //                        NSLog(@"aLine: %@", aLine);
                        //                        NSLog(@"\n1: %@\n2: %@\n3: %@\n4: %@\n5: %@\n6: %@\n7: %@\n8: %@\n", NSStringFromGLKVector3(vertexI), NSStringFromGLKVector3(vertexJ),NSStringFromGLKVector3(vertexK),NSStringFromGLKVector3(vertexL),NSStringFromGLKVector3(vertexM),NSStringFromGLKVector3(vertexN),NSStringFromGLKVector3(vertexO),NSStringFromGLKVector3(vertexP));
                        //
                        //                        NSLog(@"solidVertexCount: %i", solidVertexCount);
                        //                        NSLog(@"solidMemCounter: %i", solidMemCounter);
                        // face 1
                        [self addTriangle:vertexJ
                                position2:vertexI
                             andPosition3:vertexK
                                  toArray:self.triVerticesFromTetraSolids
                                  counter:_numOfSolidTetraVertices];
                        _numOfSolidTetraVertices += 3;
                        // face 2
                        [self addTriangle:vertexI
                                position2:vertexJ
                             andPosition3:vertexL
                                  toArray:self.triVerticesFromTetraSolids
                                  counter:_numOfSolidTetraVertices];
                        _numOfSolidTetraVertices += 3;
                        
                        // face 3
                        [self addTriangle:vertexJ
                                position2:vertexK
                             andPosition3:vertexL
                                  toArray:self.triVerticesFromTetraSolids
                                  counter:_numOfSolidTetraVertices];
                        _numOfSolidTetraVertices += 3;
                        // face 4
                        [self addTriangle:vertexI
                                position2:vertexL
                             andPosition3:vertexK
                                  toArray:self.triVerticesFromTetraSolids
                                  counter:_numOfSolidTetraVertices];
                        _numOfSolidTetraVertices += 3;
                    }
                }
                else if ([self isSolidTetraElement:aLine withValidRange:ansysEBlock.elementTypeRange]) 
                {
                    NSArray *elementIndicies = [ansysEBlock extractSolidTetraIndexComponentsFromLine:aLine];
                    if (elementIndicies.count >= 4) 
                    {
                        // pull out position values for each node number
                        //I, J, K, L, (Solid187 and Solid285 - discarding midside nodes on Solid187)
                        
                        self.solidTetraElemProp[_numOfSolidTetraVertices] = [ansysEBlock extractElementPropertiesFromLine:aLine];
                        for (NSInteger j = 1; j<12; j++) 
                        {
                            self.solidTetraElemProp[_numOfSolidTetraVertices + j] = self.solidTetraElemProp[_numOfSolidTetraVertices];
                        }
                        // Directly create triangles from positions
                        // for the 4 triangles save the corresponding element property
                        //A 'cube',
                        GLKVector3 vertexI = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:0]];
                        GLKVector3 vertexJ = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:1]];
                        GLKVector3 vertexK = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:2]];
                        GLKVector3 vertexL = [self vertexPositionForNodeNumber:[elementIndicies objectAtIndex:3]];

                        // face 1
                        [self addTriangle:vertexJ 
                                position2:vertexI 
                             andPosition3:vertexK 
                                  toArray:self.triVerticesFromTetraSolids
                                  counter:_numOfSolidTetraVertices];
                        _numOfSolidTetraVertices += 3;
                        // face 2
                        [self addTriangle:vertexI 
                                position2:vertexJ 
                             andPosition3:vertexL 
                                  toArray:self.triVerticesFromTetraSolids 
                                  counter:_numOfSolidTetraVertices];
                        _numOfSolidTetraVertices += 3;
                        
                        // face 3
                        [self addTriangle:vertexJ 
                                position2:vertexK 
                             andPosition3:vertexL 
                                  toArray:self.triVerticesFromTetraSolids 
                                  counter:_numOfSolidTetraVertices];
                        _numOfSolidTetraVertices += 3;
                        // face 4
                        [self addTriangle:vertexI 
                                position2:vertexL 
                             andPosition3:vertexK 
                                  toArray:self.triVerticesFromTetraSolids 
                                  counter:_numOfSolidTetraVertices];
                        _numOfSolidTetraVertices += 3;
                    }
                }
                else if ([self isShellElement:aLine withValidRange:ansysEBlock.elementTypeRange]) 
                {
                    NSArray *elementIndicies = [ansysEBlock extractShellIndexComponentsFromLine:aLine];
                    //NSLog(@"elementIndicies: %@", elementIndicies);
                    if ([elementIndicies count] == 4) 
                    {
                        //A 'rectangle', convert to trianglestrip (swithching index 3 and 4 later)
                        self.quadFaces[quadFaceCount].vertex1 = [[elementIndicies objectAtIndex:0] intValue];
                        self.quadFaces[quadFaceCount].vertex2 = [[elementIndicies objectAtIndex:1] intValue];
                        self.quadFaces[quadFaceCount].vertex3 = [[elementIndicies objectAtIndex:2] intValue];
                        self.quadFaces[quadFaceCount].vertex4 = [[elementIndicies objectAtIndex:3] intValue];
                        if (self.readMode == kMediumMem || self.readMode == kFullMem) {
                            self.quadElemProp[quadFaceCount] = [ansysEBlock extractElementPropertiesFromLine:aLine];
                        }
                        quadFaceCount++;
                    } 
                    else if ([elementIndicies count] == 3) 
                    {
                        //A triangle, make one triangle
                        self.triFaces[triFaceCount].vertex1 = [[elementIndicies objectAtIndex:0] intValue];
                        self.triFaces[triFaceCount].vertex2 = [[elementIndicies objectAtIndex:1] intValue];
                        self.triFaces[triFaceCount].vertex3 = [[elementIndicies objectAtIndex:2] intValue];
                        if (self.readMode == kMediumMem || self.readMode == kFullMem) {
                            self.triElemProp[triFaceCount] = [ansysEBlock extractElementPropertiesFromLine:aLine];
                        }
                        triFaceCount++;
                    }
                }
                else if ([self isBeamElement:aLine withValidRange:ansysEBlock.elementTypeRange]) 
                {
                    NSArray *elementIndicies = [ansysEBlock extractBeamIndexComponentsFromLine:aLine];
                    if (elementIndicies.count == 3) 
                    {
                        //A degenerate beam element, convert to two beams/lines 
                        self.lines[beamCount].vertex1 = [[elementIndicies objectAtIndex:0] intValue];
                        self.lines[beamCount].vertex2 = [[elementIndicies objectAtIndex:1] intValue];
                        self.lines[beamCount+1].vertex1 = [[elementIndicies objectAtIndex:1] intValue];
                        self.lines[beamCount+1].vertex2 = [[elementIndicies objectAtIndex:2] intValue];
                        if (self.readMode == kMediumMem || self.readMode == kFullMem) {
                            self.beamElemProp[beamCount] = self.beamElemProp[beamCount+1] = [ansysEBlock extractElementPropertiesFromLine:aLine];
                        }

                        beamCount+=2;
                    } 
                    else if (elementIndicies.count == 2) 
                    {
                        //A triangle, make one triangle
                        self.lines[beamCount].vertex1 = [[elementIndicies objectAtIndex:0] intValue];
                        self.lines[beamCount].vertex2 = [[elementIndicies objectAtIndex:1] intValue];
                        if (self.readMode == kMediumMem || self.readMode == kFullMem) {
                            self.beamElemProp[beamCount] = [ansysEBlock extractElementPropertiesFromLine:aLine];
                        }
                        beamCount++;
                    }
                }
            } 
        }
        lastLineInBuffer = [lines lastObject];
        lines = nil;
    }
    
    [myStream close];
    myStream = nil;
    
    self.numOfTriFaces = triFaceCount;
    self.numOfQuadFaces = quadFaceCount;
    self.numOfBeams = beamCount; 
}


- (GLKVector3)vertexPositionForNodeNumber:(NSString *)nodeNumber
{
//    NSLog(@"  node_no: %@", [NSString stringWithFormat:@"%i", nodeNumber]);
//    NSLog(@"vertex_no: %@", [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", nodeNumber]] stringValue]);
    return self.vertexPositions[[[self.origToNew valueForKey:nodeNumber] integerValue]];
}


- (void)addTriangle:(GLKVector3)position1
          position2:(GLKVector3)position2
       andPosition3:(GLKVector3)position3
            toArray:(Vertex *)theArray 
            counter:(NSUInteger)counter
{
    GLKVector4 color = GLKVector4Make(119.0/256.0f, 136.0/256.0f, 153.0/256.0f, 1.0f);
    theArray[counter].color = color;
    theArray[counter+1].color = color;
    theArray[counter+2].color = color;
    theArray[counter].position = position1;
    theArray[counter+1].position = position2;
    theArray[counter+2].position = position3;
    GLKVector3 vec1to2      = GLKVector3Subtract(position2, position1);
    GLKVector3 vec1to3      = GLKVector3Subtract(position3, position1);
    GLKVector3 normalVector = GLKVector3Normalize(GLKVector3CrossProduct(vec1to2, vec1to3));
    theArray[counter].normal = theArray[counter+1].normal = theArray[counter+2].normal = normalVector;
}

- (BOOL)isBeamElement:(NSString *)aLine withValidRange:(NSRange)elementTypeRange
{
    if(aLine.length >= elementTypeRange.location+elementTypeRange.length)
    {
        if ([[self.validBeamETypes valueForKey:[[aLine substringWithRange:elementTypeRange] stringByTrimmingCharactersInSet:spaceAndNewLineSet]] boolValue])
        {
            return YES;
        } 
    } 
    return NO;
}


- (BOOL)isShellElement:(NSString *)aLine withValidRange:(NSRange)elementTypeRange
{
    if(aLine.length >= elementTypeRange.location+elementTypeRange.length)
    {
        if ([[self.validShellETypes valueForKey:[[aLine substringWithRange:elementTypeRange] stringByTrimmingCharactersInSet:spaceAndNewLineSet]] boolValue])
        {
            return YES;
        } 
    } 
    return NO;
}


- (BOOL)isSolidCubeElement:(NSString *)aLine withValidRange:(NSRange)elementTypeRange
{
    if(aLine.length >= elementTypeRange.location+elementTypeRange.length)
    {
        if ([[self.validSolidCubeETypes valueForKey:[[aLine substringWithRange:elementTypeRange] stringByTrimmingCharactersInSet:spaceAndNewLineSet]] boolValue])
        {
            return YES; 
        } 
    } 
    return NO;
}


- (BOOL)isSolidTetraElement:(NSString *)aLine withValidRange:(NSRange)elementTypeRange
{
    if(aLine.length >= elementTypeRange.location+elementTypeRange.length)
    {
        if ([[self.validSolidTetraETypes valueForKey:[[aLine substringWithRange:elementTypeRange] stringByTrimmingCharactersInSet:spaceAndNewLineSet]] boolValue])
        {
            return YES; 
        } 
    } 
    return NO;
}


- (void)pullOutIndexesForEdges
{
    NSUInteger edgeCount = 0;
    self.edgeVertices = calloc(self.numOfTriFaces*3+self.numOfQuadFaces*4+self.numOfSolidCubeVertices*12+self.numOfSolidCubeVertices*9+self.numOfSolidTetraVertices*6, 2*sizeof(GLKVector3));

    NSUInteger triFaceOffset = 0;
    for (NSUInteger faceNo = 0; faceNo < self.numOfTriFaces; faceNo++) 
    {
        //            NSLog(@"3*edgeCount+0: %i", edgeCount+0);
        //            NSLog(@"faceNo: %i", faceNo);
        
        self.edgeVertices[2*edgeCount+0] = self.triVerticesFromAllFaces[(faceNo*3)+0].position;        
        self.edgeVertices[2*edgeCount+1] = self.triVerticesFromAllFaces[(faceNo*3)+1].position;        
        self.edgeVertices[2*edgeCount+2] = self.triVerticesFromAllFaces[(faceNo*3)+1].position;        
        self.edgeVertices[2*edgeCount+3] = self.triVerticesFromAllFaces[(faceNo*3)+2].position;        
        self.edgeVertices[2*edgeCount+4] = self.triVerticesFromAllFaces[(faceNo*3)+2].position;        
        self.edgeVertices[2*edgeCount+5] = self.triVerticesFromAllFaces[(faceNo*3)+0].position; 
        edgeCount += 3;
        triFaceOffset = (faceNo*3)+3;
    }

    for (NSUInteger faceNo = 0; faceNo < self.numOfQuadFaces; faceNo++) 
    {
        self.edgeVertices[2*edgeCount+0] = self.triVerticesFromAllFaces[triFaceOffset+(faceNo*6)+0].position;
        self.edgeVertices[2*edgeCount+1] = self.triVerticesFromAllFaces[triFaceOffset+(faceNo*6)+1].position;
        self.edgeVertices[2*edgeCount+2] = self.triVerticesFromAllFaces[triFaceOffset+(faceNo*6)+1].position;
        self.edgeVertices[2*edgeCount+3] = self.triVerticesFromAllFaces[triFaceOffset+(faceNo*6)+2].position;
        self.edgeVertices[2*edgeCount+4] = self.triVerticesFromAllFaces[triFaceOffset+(faceNo*6)+3].position;
        self.edgeVertices[2*edgeCount+5] = self.triVerticesFromAllFaces[triFaceOffset+(faceNo*6)+4].position;
        self.edgeVertices[2*edgeCount+6] = self.triVerticesFromAllFaces[triFaceOffset+(faceNo*6)+4].position;
        self.edgeVertices[2*edgeCount+7] = self.triVerticesFromAllFaces[triFaceOffset+(faceNo*6)+5].position;
        edgeCount += 4;
    } 
    self.numOfEdges = edgeCount;
    
    for (NSUInteger vertexNo = 0; vertexNo < self.numOfSolidCubeVertices; vertexNo+=3)
    {
        self.edgeVertices[2*edgeCount+0] = self.triVerticesFromCubeSolids[vertexNo+0].position;
        self.edgeVertices[2*edgeCount+1] = self.triVerticesFromCubeSolids[vertexNo+1].position;
        self.edgeVertices[2*edgeCount+2] = self.triVerticesFromCubeSolids[vertexNo+1].position;
        self.edgeVertices[2*edgeCount+3] = self.triVerticesFromCubeSolids[vertexNo+2].position;
        edgeCount += 2;
    }
    
    for (NSUInteger vertexNo = 0; vertexNo < self.numOfSolidPrismVertices; vertexNo+=24)
    {
        self.edgeVertices[2*edgeCount+0] =  self.triVerticesFromTetraSolids[vertexNo+0].position;
        self.edgeVertices[2*edgeCount+1] =  self.triVerticesFromTetraSolids[vertexNo+1].position;
        self.edgeVertices[2*edgeCount+2] =  self.triVerticesFromTetraSolids[vertexNo+1].position;
        self.edgeVertices[2*edgeCount+3] =  self.triVerticesFromTetraSolids[vertexNo+2].position;
        
        self.edgeVertices[2*edgeCount+4] =  self.triVerticesFromTetraSolids[vertexNo+3].position;
        self.edgeVertices[2*edgeCount+5] =  self.triVerticesFromTetraSolids[vertexNo+4].position;
        self.edgeVertices[2*edgeCount+6] =  self.triVerticesFromTetraSolids[vertexNo+4].position;
        self.edgeVertices[2*edgeCount+7] =  self.triVerticesFromTetraSolids[vertexNo+5].position;
        
        self.edgeVertices[2*edgeCount+8] =  self.triVerticesFromTetraSolids[vertexNo+6].position;
        self.edgeVertices[2*edgeCount+9] =  self.triVerticesFromTetraSolids[vertexNo+7].position;
        self.edgeVertices[2*edgeCount+10] = self.triVerticesFromTetraSolids[vertexNo+7].position;
        self.edgeVertices[2*edgeCount+11] = self.triVerticesFromTetraSolids[vertexNo+8].position;
        
        self.edgeVertices[2*edgeCount+12] = self.triVerticesFromTetraSolids[vertexNo+9].position;
        self.edgeVertices[2*edgeCount+13] = self.triVerticesFromTetraSolids[vertexNo+10].position;
        
        self.edgeVertices[2*edgeCount+14] = self.triVerticesFromTetraSolids[vertexNo+19].position;
        self.edgeVertices[2*edgeCount+15] = self.triVerticesFromTetraSolids[vertexNo+20].position;
        
        self.edgeVertices[2*edgeCount+16] = self.triVerticesFromTetraSolids[vertexNo+22].position;
        self.edgeVertices[2*edgeCount+17] = self.triVerticesFromTetraSolids[vertexNo+23].position;

        edgeCount += 9;
    }
    
    for (NSUInteger vertexNo = 0; vertexNo < self.numOfSolidTetraVertices; vertexNo+=3)
    {
        self.edgeVertices[2*edgeCount+0] = self.triVerticesFromTetraSolids[vertexNo+0].position;
        self.edgeVertices[2*edgeCount+1] = self.triVerticesFromTetraSolids[vertexNo+1].position;
        self.edgeVertices[2*edgeCount+2] = self.triVerticesFromTetraSolids[vertexNo+1].position;
        self.edgeVertices[2*edgeCount+3] = self.triVerticesFromTetraSolids[vertexNo+2].position;
        edgeCount += 2;
    }
    self.numOfEdges = edgeCount;
    
    NSLog(@"self.numOfEdges: %i", self.numOfEdges);

}


- (void)pullOutVerticesAsTriangles
{
    NSLog(@"self.numOfTriFaces: %i", self.numOfTriFaces);

    self.triVertices = calloc(self.numOfTriFaces*3, sizeof(Vertex));
 
    for (int faceNo = 0; faceNo < self.numOfTriFaces; faceNo++) 
    {
        int vertex1 = self.triFaces[faceNo].vertex1;
        int vertex2 = self.triFaces[faceNo].vertex2;
        int vertex3 = self.triFaces[faceNo].vertex3;
        
        self.triVertices[faceNo*3].position   = self.vertexPositions[vertex1];
        self.triVertices[faceNo*3+1].position = self.vertexPositions[vertex2];
        self.triVertices[faceNo*3+2].position = self.vertexPositions[vertex3]; 
    }

    for (int faceNo = 0; faceNo < self.numOfTriFaces; faceNo++) 
    {
        GLKVector3 vec1to2      = GLKVector3Subtract(self.triVertices[3*faceNo+1].position, self.triVertices[3*faceNo].position);
        GLKVector3 vec1to3      = GLKVector3Subtract(self.triVertices[3*faceNo+2].position, self.triVertices[3*faceNo].position);
        GLKVector3 normalVector = GLKVector3Normalize(GLKVector3CrossProduct(vec1to2, vec1to3));
        
        self.triVertices[3*faceNo].normal   = normalVector;
        self.triVertices[3*faceNo+1].normal = normalVector;
        self.triVertices[3*faceNo+2].normal = normalVector;
    }
}


- (void)pullOutQuadsAsTriangles
{
    NSLog(@"self.numOfQuadFaces: %i", self.numOfQuadFaces);
    
    self.triVerticesFromQuads = calloc(self.numOfQuadFaces*6, sizeof(Vertex));
    
    for (int faceNo = 0; faceNo < self.numOfQuadFaces; faceNo++) 
    {
        int vertex1 = self.quadFaces[faceNo].vertex1;
        int vertex2 = self.quadFaces[faceNo].vertex2;
        int vertex3 = self.quadFaces[faceNo].vertex3;
        int vertex4 = self.quadFaces[faceNo].vertex4;
            
        self.triVerticesFromQuads[faceNo*6].position   = self.vertexPositions[vertex1];
        self.triVerticesFromQuads[faceNo*6+1].position = self.vertexPositions[vertex2];
        self.triVerticesFromQuads[faceNo*6+2].position = self.vertexPositions[vertex3]; 
        
        self.triVerticesFromQuads[faceNo*6+3].position = self.vertexPositions[vertex3];
        self.triVerticesFromQuads[faceNo*6+4].position = self.vertexPositions[vertex4]; 
        self.triVerticesFromQuads[faceNo*6+5].position = self.vertexPositions[vertex1]; 
    }
    
    for (int faceNo = 0; faceNo < self.numOfQuadFaces; faceNo++) 
    {
        GLKVector3 vec1to2      = GLKVector3Subtract(self.triVerticesFromQuads[6*faceNo+1].position, self.triVerticesFromQuads[6*faceNo].position);
        GLKVector3 vec1to3      = GLKVector3Subtract(self.triVerticesFromQuads[6*faceNo+2].position, self.triVerticesFromQuads[6*faceNo].position); //Note: using 4. vertex to be consistent with normals for tri's
        GLKVector3 normalVector = GLKVector3Normalize(GLKVector3CrossProduct(vec1to2, vec1to3));
                
        self.triVerticesFromQuads[6*faceNo].normal   = normalVector;
        self.triVerticesFromQuads[6*faceNo+1].normal = normalVector;
        self.triVerticesFromQuads[6*faceNo+2].normal = normalVector;
        self.triVerticesFromQuads[6*faceNo+3].normal = normalVector;
        self.triVerticesFromQuads[6*faceNo+4].normal = normalVector;
        self.triVerticesFromQuads[6*faceNo+5].normal = normalVector;
    }
}

void *array_concat(const void *a, size_t an,
                   const void *b, size_t bn, size_t s)
{
    char *p = malloc(s * (an + bn));
    memcpy(p, a, an*s);
    memcpy(p + an*s, b, bn*s);
    return p;
}

- (void)combineTrisAndQuads
{
    self.triVerticesFromAllFaces = calloc(self.numOfTriFaces*3+self.numOfQuadFaces*6, sizeof(Vertex));
    for (NSUInteger i = 0; i < self.numOfTriFaces*3; i++) 
    {
        self.triVerticesFromAllFaces[i] = self.triVertices[i];
    }
    for (NSUInteger i = 0; i < self.numOfQuadFaces*6; i++) 
    {
        self.triVerticesFromAllFaces[self.numOfTriFaces*3+i] = self.triVerticesFromQuads[i];
    }
//    self.triVerticesFromAllFaces = array_concat(self.triVertices, self.numOfTriFaces*3, 
//                                                self.triVerticesFromQuads, self.numOfQuadFaces*6, 
//                                                sizeof(Vertex));
    if (self.triVertices) {
        free(self.triVertices);
    }
    if (self.triVerticesFromQuads) {
        free(self.triVerticesFromQuads);
    }
}


- (void)replaceOriginalIndexesWithNew
{
    //NSLog(@"self.origToNew: %@", self.origToNew );
    TriFace *tempTriFaces = calloc(self.numOfTriFaces, sizeof(TriFace));

    for (int faceNo = 0; faceNo < self.numOfTriFaces; faceNo++) 
    {
        //NSLog(@"triElemProp: %@", [AnsysHelper stringFromElementProperties:self.triElemProp[faceNo]]);
        int origVertex1 = self.triFaces[faceNo].vertex1;
        int origVertex2 = self.triFaces[faceNo].vertex2;
        int origVertex3 = self.triFaces[faceNo].vertex3;
         
        tempTriFaces[faceNo].vertex1 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex1]] intValue];
        tempTriFaces[faceNo].vertex2 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex2]] intValue];
        tempTriFaces[faceNo].vertex3 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex3]] intValue];
    }
    for (int faceNo = 0; faceNo < self.numOfTriFaces; faceNo++) 
    {
        self.triFaces[faceNo].vertex1 = tempTriFaces[faceNo].vertex1;
        self.triFaces[faceNo].vertex2 = tempTriFaces[faceNo].vertex2;
        self.triFaces[faceNo].vertex3 = tempTriFaces[faceNo].vertex3;
    }
    free(tempTriFaces);
    
    QuadFace *tempQuadFaces = calloc(self.numOfQuadFaces, sizeof(QuadFace));
    
    for (int faceNo = 0; faceNo < self.numOfQuadFaces; faceNo++) 
    {
        //NSLog(@"quadElemProp: %@", [AnsysHelper stringFromElementProperties:self.quadElemProp[faceNo]]);
        int origVertex1 = self.quadFaces[faceNo].vertex1;
        int origVertex2 = self.quadFaces[faceNo].vertex2;
        int origVertex3 = self.quadFaces[faceNo].vertex3;
        int origVertex4 = self.quadFaces[faceNo].vertex4;
        
        tempQuadFaces[faceNo].vertex1 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex1]] intValue];
        tempQuadFaces[faceNo].vertex2 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex2]] intValue];
        tempQuadFaces[faceNo].vertex3 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex3]] intValue];
        tempQuadFaces[faceNo].vertex4 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex4]] intValue];
        //NSLog(@"self.quadFaces[%i]: %i, %i, %i, %i", faceNo, self.quadFaces[faceNo].vertex1, self.quadFaces[faceNo].vertex2, self.quadFaces[faceNo].vertex3, self.quadFaces[faceNo].vertex4);
    }
    for (int faceNo = 0; faceNo < self.numOfQuadFaces; faceNo++) 
    {
        self.quadFaces[faceNo].vertex1 = tempQuadFaces[faceNo].vertex1;
        self.quadFaces[faceNo].vertex2 = tempQuadFaces[faceNo].vertex2;
        self.quadFaces[faceNo].vertex3 = tempQuadFaces[faceNo].vertex3;
        self.quadFaces[faceNo].vertex4 = tempQuadFaces[faceNo].vertex4;
       // NSLog(@"self.quadFaces[%i]: %i, %i, %i, %i", faceNo, self.quadFaces[faceNo].vertex1, self.quadFaces[faceNo].vertex2, self.quadFaces[faceNo].vertex3, self.quadFaces[faceNo].vertex4);
    }
    free(tempQuadFaces);
    
    Line *tempBeams = calloc(self.numOfBeams, sizeof(Line));

    NSLog(@"self.numOfBeams: %i", self.numOfBeams);

    for (int lineNo = 0; lineNo < self.numOfBeams; lineNo++) 
    {
        int origVertex1 = self.lines[lineNo].vertex1;
        int origVertex2 = self.lines[lineNo].vertex2;        
        
        tempBeams[lineNo].vertex1 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex1]] intValue];
        tempBeams[lineNo].vertex2 = [[self.origToNew valueForKey:[NSString stringWithFormat:@"%i", origVertex2]] intValue];
        //NSLog(@"self.lines[%i]: %i, %i", lineNo, self.lines[lineNo].vertex1, self.lines[lineNo].vertex2);
    }
    for (int lineNo = 0; lineNo < self.numOfBeams; lineNo++) 
    {
        self.lines[lineNo].vertex1 = tempBeams[lineNo].vertex1;
        self.lines[lineNo].vertex2 = tempBeams[lineNo].vertex2;
        
        //NSLog(@"self.lines[%i]: %i, %i", lineNo, self.lines[lineNo].vertex1, self.lines[lineNo].vertex2);
        //NSLog(@"self.lines[%i]: %@ || %@", lineNo, NSStringFromGLKVector3(self.vertexPositions[self.lines[lineNo].vertex1]), NSStringFromGLKVector3(self.vertexPositions[self.lines[lineNo].vertex2]));

        // NSLog(@"self.quadFaces[%i]: %i, %i, %i, %i", faceNo, self.quadFaces[faceNo].vertex1, self.quadFaces[faceNo].vertex2, self.quadFaces[faceNo].vertex3, self.quadFaces[faceNo].vertex4);
    }
    free(tempBeams);
    
    //NSLog(@"self.origToNew: %@", self.origToNew);
    //self.origToNew = nil;
}


- (void)setColorsOfElementsWithTranparency:(float)transparency
{
    self.colorArray = [ColorArrays materialColorsWithTransparency:transparency];
    
    if (self.colorMode == kMaterialColor)
    {
        NSMutableDictionary *colorNoForMatNo = [NSMutableDictionary dictionaryWithCapacity:self.numOfMatProperties];
        NSUInteger colorNo = 0;
        
        for (NSUInteger matProp = 0; matProp < self.numOfMatProperties; matProp++) {
            [colorNoForMatNo setValue:[NSNumber numberWithInteger:colorNo] forKey:[NSString stringWithFormat:@"%d", self.matProperties[matProp].matNo]];
            //        NSLog(@"colorNo: %i", colorNo);
            //        NSLog(@"colorNo: %d", colorNo);
            
            colorNo++;
            
            if (colorNo > 19) {
                colorNo = 0;
            }
        }
        int faceNoOffset = 0;
        for (int faceNo = 0; faceNo < self.numOfTriFaces; faceNo++) 
        {
            GLKVector4 triColorVector  = self.colorArray[[[colorNoForMatNo valueForKey:[NSString stringWithFormat:@"%d", self.triElemProp[faceNo].materialNo]] integerValue]];
            self.triVerticesFromAllFaces[3*faceNo].color   = triColorVector;
            self.triVerticesFromAllFaces[3*faceNo+1].color = triColorVector;
            self.triVerticesFromAllFaces[3*faceNo+2].color = triColorVector;
            faceNoOffset = 3*faceNo+3;
        }
        
//        for (NSUInteger i = 0; i<self.numOfTriFaces*3+self.numOfQuadFaces*6; i++) 
//        {
//            NSLog(@"%i: %@", i, NSStringFromGLKVector3(self.triVerticesFromAllFaces[i].position));
//        }
        
        for (int faceNo = 0; faceNo < self.numOfQuadFaces; faceNo++) 
        {
            GLKVector4 quadColorVector  = self.colorArray[[[colorNoForMatNo valueForKey:[NSString stringWithFormat:@"%d", self.quadElemProp[faceNo].materialNo]] integerValue]];         
            self.triVerticesFromAllFaces[faceNoOffset+6*faceNo].color   = quadColorVector;
            self.triVerticesFromAllFaces[faceNoOffset+6*faceNo+1].color = quadColorVector;
            self.triVerticesFromAllFaces[faceNoOffset+6*faceNo+2].color = quadColorVector;
            self.triVerticesFromAllFaces[faceNoOffset+6*faceNo+3].color = quadColorVector;        
            self.triVerticesFromAllFaces[faceNoOffset+6*faceNo+4].color = quadColorVector;
            self.triVerticesFromAllFaces[faceNoOffset+6*faceNo+5].color = quadColorVector;
        }
        
        for (NSUInteger vertexNo = 0; vertexNo < self.numOfSolidCubeVertices; vertexNo+=36)
        {
            GLKVector4 solidCubeColorVector  = self.colorArray[[[colorNoForMatNo valueForKey:[NSString stringWithFormat:@"%d", self.solidCubeElemProp[vertexNo].materialNo]] integerValue]];
            self.triVerticesFromCubeSolids[vertexNo].color   = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+1].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+2].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+3].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+4].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+5].color = solidCubeColorVector;
            
            self.triVerticesFromCubeSolids[vertexNo+6].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+7].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+8].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+9].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+10].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+11].color = solidCubeColorVector;
            
            self.triVerticesFromCubeSolids[vertexNo+12].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+13].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+14].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+15].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+16].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+17].color = solidCubeColorVector;
            
            self.triVerticesFromCubeSolids[vertexNo+18].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+19].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+20].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+21].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+22].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+23].color = solidCubeColorVector;
            
            self.triVerticesFromCubeSolids[vertexNo+24].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+25].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+26].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+27].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+28].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+29].color = solidCubeColorVector;
            
            self.triVerticesFromCubeSolids[vertexNo+30].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+31].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+32].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+33].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+34].color = solidCubeColorVector;
            self.triVerticesFromCubeSolids[vertexNo+35].color = solidCubeColorVector;
        }
        
        for (NSUInteger vertexNo = 0; vertexNo < self.numOfSolidPrismVertices; vertexNo+=24)
        {
            GLKVector4 solidCubeColorVector  = self.colorArray[[[colorNoForMatNo valueForKey:[NSString stringWithFormat:@"%d", self.solidPrismElemProp[vertexNo].materialNo]] integerValue]];
            self.triVerticesFromPrismSolids[vertexNo].color   = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+1].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+2].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+3].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+4].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+5].color = solidCubeColorVector;
            
            self.triVerticesFromPrismSolids[vertexNo+6].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+7].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+8].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+9].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+10].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+11].color = solidCubeColorVector;
            
            self.triVerticesFromPrismSolids[vertexNo+12].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+13].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+14].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+15].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+16].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+17].color = solidCubeColorVector;
            
            self.triVerticesFromPrismSolids[vertexNo+18].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+19].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+20].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+21].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+22].color = solidCubeColorVector;
            self.triVerticesFromPrismSolids[vertexNo+23].color = solidCubeColorVector;
        }
        
        for (NSUInteger vertexNo = 0; vertexNo < self.numOfSolidTetraVertices; vertexNo+=12)
        {
            GLKVector4 solidCubeColorVector  = self.colorArray[[[colorNoForMatNo valueForKey:[NSString stringWithFormat:@"%d", self.solidTetraElemProp[vertexNo].materialNo]] integerValue]];
            self.triVerticesFromTetraSolids[vertexNo].color   = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+1].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+2].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+3].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+4].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+5].color = solidCubeColorVector;
            
            self.triVerticesFromTetraSolids[vertexNo+6].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+7].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+8].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+9].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+10].color = solidCubeColorVector;
            self.triVerticesFromTetraSolids[vertexNo+11].color = solidCubeColorVector;
        }
        //NSLog(@"colorNoForMatNo: %@", colorNoForMatNo);
        colorNoForMatNo = nil;
    } 
    else if (self.colorMode == kThicknessColor) 
    {
        NSLog(@"coloring according to thickness");
        NSMutableDictionary *colorNoForSecNo = [NSMutableDictionary dictionaryWithCapacity:self.numOfSecProperties];
        NSUInteger colorNo = 0;
        
        for (NSUInteger secProp = 0; secProp < self.numOfSecProperties; secProp++) {
            [colorNoForSecNo setValue:[NSNumber numberWithInteger:colorNo] forKey:[NSString stringWithFormat:@"%f", self.sectionProperties[secProp].val1]];
            //        NSLog(@"colorNo: %i", colorNo);
            //        NSLog(@"colorNo: %d", colorNo);
            
            colorNo++;
            
            if (colorNo > 19) {
                colorNo = 0;
            }
        }
        
        for (int faceNo = 0; faceNo < self.numOfTriFaces; faceNo++) 
        {
            GLKVector4 triColorVector  = self.colorArray[[[colorNoForSecNo valueForKey:[NSString stringWithFormat:@"%f",  self.sectionProperties[self.triElemProp[faceNo].sectionNo].val1]] integerValue]];
            self.triVertices[3*faceNo].color   = triColorVector;
            self.triVertices[3*faceNo+1].color = triColorVector;
            self.triVertices[3*faceNo+2].color = triColorVector;
        }
        
        for (int faceNo = 0; faceNo < self.numOfQuadFaces; faceNo++) 
        {
            GLKVector4 quadColorVector  = self.colorArray[[[colorNoForSecNo valueForKey:[NSString stringWithFormat:@"%f",  self.sectionProperties[self.quadElemProp[faceNo].sectionNo].val1]] integerValue]];         
            self.triVerticesFromQuads[6*faceNo].color   = quadColorVector;
            self.triVerticesFromQuads[6*faceNo+1].color = quadColorVector;
            self.triVerticesFromQuads[6*faceNo+2].color = quadColorVector;
            self.triVerticesFromQuads[6*faceNo+3].color = quadColorVector;        
            self.triVerticesFromQuads[6*faceNo+4].color = quadColorVector;
            self.triVerticesFromQuads[6*faceNo+5].color = quadColorVector;
        }
        //NSLog(@"colorNoForMatNo: %@", colorNoForMatNo);
        colorNoForSecNo = nil;
    }
}


- (void)setColorsOfLines
{
    //GLKVector4 lineColorVector  = GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f);
    
    /*for (int lineNo = 0; lineNo < self.numOfLines; lineNo++) 
    {
        //self.lineVertices[2*lineNo+0].color = lineColorVector;
        //self.lineVertices[2*lineNo+1].color = lineColorVector;
    }*/
    
}


- (void)calculateBoundingBoxOfVertices
{
    self.boundingBox = calloc(1, sizeof(BoundingBox));
    float maxX;
    float minX;
    float maxY;
    float minY;
    float maxZ;
    float minZ;
    
    //Setting min, max to an actual coordinate from the geometry as initial value
    int aUsedVertex = 0;
    if (self.numOfTriFaces > 0) 
    {
        aUsedVertex = self.triFaces[0].vertex1;
    }
    else if (self.numOfQuadFaces > 0) 
    {
        aUsedVertex = self.quadFaces[0].vertex1;
    }
    if (self.numOfSolidCubeVertices > 0)
    {
        minX = self.triVerticesFromCubeSolids[0].position.x;
        minY = self.triVerticesFromCubeSolids[0].position.y;
        minZ = self.triVerticesFromCubeSolids[0].position.z;
    }
    else if (self.numOfSolidTetraVertices > 0)
    {
        minX = self.triVerticesFromTetraSolids[0].position.x;
        minY = self.triVerticesFromTetraSolids[0].position.y;
        minZ = self.triVerticesFromTetraSolids[0].position.z;
    }
    
    minX = self.vertexPositions[aUsedVertex].x;
    maxX = minX;
    minY = self.vertexPositions[aUsedVertex].y;
    maxY = minY;
    minZ = self.vertexPositions[aUsedVertex].z;
    maxZ = minZ;

    int vertexNo;
    for (int faceNo = 0; faceNo < self.numOfTriFaces; faceNo++) 
    {
        for (int indexNumber = 0; indexNumber < 3; indexNumber++) 
        {
            switch (indexNumber) 
            {
                case 0:
                    vertexNo = self.triFaces[faceNo].vertex1;
                    break;
                case 1:
                    vertexNo = self.triFaces[faceNo].vertex2;
                    break;
                case 2:
                    vertexNo = self.triFaces[faceNo].vertex3;
                    break;
                default:
                    break;
            }        
            //note: only one of the three face nodes is used (risk max coordinate not catched)
            if (self.vertexPositions[vertexNo].x <= minX) 
            {
                minX = self.vertexPositions[vertexNo].x;
            } 
            else if (self.vertexPositions[vertexNo].x > maxX) 
            {
                maxX = self.vertexPositions[vertexNo].x;
            }
            if (self.vertexPositions[vertexNo].y <= minY) 
            {
                minY = self.vertexPositions[vertexNo].y;
            } 
            else if (self.vertexPositions[vertexNo].y > maxY) 
            {
                maxY = self.vertexPositions[vertexNo].y;
            }
            if (self.vertexPositions[vertexNo].z <= minZ) 
            {
                minZ = self.vertexPositions[vertexNo].z;
            } 
            else if (self.vertexPositions[vertexNo].z > maxZ) 
            {
                maxZ = self.vertexPositions[vertexNo].z;
            }
        }
    }
    
    for (int faceNo = 0; faceNo < self.numOfQuadFaces; faceNo++) 
    {
        for (int indexNumber = 0; indexNumber < 4; indexNumber++) 
        {
            switch (indexNumber) 
            {
                case 0:
                    vertexNo = self.quadFaces[faceNo].vertex1;
                    break;
                case 1:
                    vertexNo = self.quadFaces[faceNo].vertex2;
                    break;
                case 2:
                    vertexNo = self.quadFaces[faceNo].vertex3;
                    break;
                case 3:
                    vertexNo = self.quadFaces[faceNo].vertex4;
                    break;
                default:
                    break;
            }
            
            if (self.vertexPositions[vertexNo].x <= minX) 
            {
                minX = self.vertexPositions[vertexNo].x;
            } 
            else if (self.vertexPositions[vertexNo].x > maxX) 
            {
                maxX = self.vertexPositions[vertexNo].x;
            }
            if (self.vertexPositions[vertexNo].y <= minY) 
            {
                minY = self.vertexPositions[vertexNo].y;
            } 
            else if (self.vertexPositions[vertexNo].y > maxY) 
            {
                maxY = self.vertexPositions[vertexNo].y;
            }
            if (self.vertexPositions[vertexNo].z <= minZ) 
            {
                minZ = self.vertexPositions[vertexNo].z;
            } 
            else if (self.vertexPositions[vertexNo].z > maxZ) 
            {
                maxZ = self.vertexPositions[vertexNo].z;
            }
        }
    }
    
    for (int vertexNo = 0; vertexNo < self.numOfSolidCubeVertices; vertexNo++) 
    {
        if (self.triVerticesFromCubeSolids[vertexNo].position.x <= minX) 
        {
            minX = self.triVerticesFromCubeSolids[vertexNo].position.x;
        } 
        else if (self.triVerticesFromCubeSolids[vertexNo].position.x > maxX) 
        {
            maxX = self.triVerticesFromCubeSolids[vertexNo].position.x;
        }
        if (self.triVerticesFromCubeSolids[vertexNo].position.y <= minY) 
        {
            minY = self.triVerticesFromCubeSolids[vertexNo].position.y;
        } 
        else if (self.triVerticesFromCubeSolids[vertexNo].position.y > maxY) 
        {
            maxY = self.triVerticesFromCubeSolids[vertexNo].position.y;
        }
        if (self.triVerticesFromCubeSolids[vertexNo].position.z <= minZ) 
        {
            minZ = self.triVerticesFromCubeSolids[vertexNo].position.z;
        } 
        else if (self.triVerticesFromCubeSolids[vertexNo].position.z > maxZ) 
        {
            maxZ = self.triVerticesFromCubeSolids[vertexNo].position.z;
        }
    }
    
    for (int vertexNo = 0; vertexNo < self.numOfSolidTetraVertices; vertexNo++)
    {
        if (self.triVerticesFromTetraSolids[vertexNo].position.x <= minX)
        {
            minX = self.triVerticesFromTetraSolids[vertexNo].position.x;
        }
        else if (self.triVerticesFromTetraSolids[vertexNo].position.x > maxX)
        {
            maxX = self.triVerticesFromTetraSolids[vertexNo].position.x;
        }
        if (self.triVerticesFromTetraSolids[vertexNo].position.y <= minY)
        {
            minY = self.triVerticesFromTetraSolids[vertexNo].position.y;
        }
        else if (self.triVerticesFromTetraSolids[vertexNo].position.y > maxY)
        {
            maxY = self.triVerticesFromTetraSolids[vertexNo].position.y;
        }
        if (self.triVerticesFromTetraSolids[vertexNo].position.z <= minZ)
        {
            minZ = self.triVerticesFromTetraSolids[vertexNo].position.z;
        }
        else if (self.triVerticesFromTetraSolids[vertexNo].position.z > maxZ)
        {
            maxZ = self.triVerticesFromTetraSolids[vertexNo].position.z;
        }
    }
    


    self.boundingBox[0].box.x = maxX-minX;
    self.boundingBox[0].box.y = maxY-minY;
    self.boundingBox[0].box.z = maxZ-minZ;
    
    self.boundingBox[0].offset.x = minX+(maxX-minX)/2;
    self.boundingBox[0].offset.y = minY+(maxY-minY)/2;
    self.boundingBox[0].offset.z = minZ+(maxZ-minZ)/2;
    
    self.boundingBox[0].lengthMax = 1.0;
    if ((self.boundingBox[0].box.x >= self.boundingBox[0].box.y ) && (self.boundingBox[0].box.x >= self.boundingBox[0].box.z)) 
    {
        self.boundingBox[0].lengthMax = self.boundingBox[0].box.x;
    } 
    else if (self.boundingBox[0].box.y >= self.boundingBox[0].box.z) {
        self.boundingBox[0].lengthMax = self.boundingBox[0].box.y;
    } else {
        self.boundingBox[0].lengthMax = self.boundingBox[0].box.z; 
    }
}


- (void)normalizeAndCenterModel
{
    NSLog(@"self.numOfVertices: %i", self.numOfVertices);

    float offsetX = self.boundingBox[0].offset.x;
    float offsetY = self.boundingBox[0].offset.y;
    float offsetZ = self.boundingBox[0].offset.z;
    float scale = self.boundingBox[0].lengthMax*0.5;
    
    for (int vertexNo = 0; vertexNo < self.numOfVertices; vertexNo++) 
    {
        //NSLog(@"self.vertexPositions[%i].vertex: %@", vertexNo, NSStringFromGLKVector3(self.vertexPositions[vertexNo].vertex));
        self.vertexPositions[vertexNo].x = (self.vertexPositions[vertexNo].x - offsetX) / scale;
        self.vertexPositions[vertexNo].y = (self.vertexPositions[vertexNo].y - offsetY) / scale;
        self.vertexPositions[vertexNo].z = (self.vertexPositions[vertexNo].z - offsetZ) / scale;
        //NSLog(@"self.vertexPositions[%i].vertex: %@", vertexNo, NSStringFromGLKVector3(self.vertexPositions[vertexNo].vertex));
    }
}

- (void)releaseArrays
{
    if (self.vertexPositions != nil)         free(self.vertexPositions);
    if (self.edgeVertices != nil)               free(self.edgeVertices);
    if (self.triVertices != nil)             free(self.triVertices);
    if (self.triVerticesFromQuads != nil)    free(self.triVerticesFromQuads);
    if (self.triVerticesFromAllFaces != nil) free(self.triVerticesFromAllFaces);
    if (self.lines != nil)                   free(self.lines);
    if (self.triFaces != nil)                free(self.triFaces);
    if (self.quadFaces != nil)               free(self.quadFaces);
    if (self.quadElemProp != nil)            free(self.quadElemProp);
    if (self.triElemProp != nil)             free(self.triElemProp);
    if (self.beamElemProp != nil)            free(self.beamElemProp);
    if (self.matProperties != nil)           free(self.matProperties);
    if (self.sectionProperties != nil)       free(self.sectionProperties);
    if (self.colorArray != nil)              free(self.colorArray);
    if (self.boundingBox != nil)             free(self.boundingBox);
}

@end