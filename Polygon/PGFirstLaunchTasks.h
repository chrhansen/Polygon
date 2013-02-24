//
//  PGLocalFilesImporter.h
//  Polygon
//
//  Created by Christian Hansen on 24/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGFirstLaunchTasks : NSObject

+ (NSArray *)findModelsInDirectory:(NSString *)directoryToSearch;

+ (void)performFirstLaunchTasksWithCompletion:(void (^)(NSError *error))completion;

@end
