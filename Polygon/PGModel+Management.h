//
//  FEModel+Management.h
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGModel.h"

@interface PGModel (Management)

+ (void)deleteModels:(NSArray *)modelsToDelete completion:(void (^)(NSError *error))completion;
+ (ModelType)modelTypeForFileName:(NSString *)fileNameWithExtension;

@property (nonatomic, readonly) NSString *fullModelFilePath;
@property (nonatomic, readonly) NSDictionary *subitems;
@property (nonatomic, readonly) NSString *enclosingFolder;
@property (nonatomic, readonly) ModelType modelType;
@property (nonatomic, readonly) BOOL isDownloaded;
@property (nonatomic, weak, readonly) NSDate *dateAddedAsDate;
@property (nonatomic, weak, readonly) NSString *dateAddedAsLocalizedString;

@end
