//
//  NSString+UUID.h
//  Flow2Go
//
//  Created by Christian Hansen on 26/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UUID)

+ (NSString *)getUUID;

+ (NSString *)percentageAsString:(NSInteger)subsetCount ofAll:(NSInteger)totalCount;


@end
