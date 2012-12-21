//
//  NSString+_Format.h
//  FEViewer2
//
//  Created by Christian Hansen on 5/1/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (_Format)

+ (NSString *)formatInterval:(NSTimeInterval)elapsedTime;
+ (NSString *)humanReadableFileSize:(NSNumber *)fileSize;
- (NSString *)fitToLength:(NSUInteger)maxLength; // crops a string to a specified length by replacing from the center of the string

+ (NSString *)timeStamp;

@end
