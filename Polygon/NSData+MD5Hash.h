//
//  NSData+MD5Hash.h
//  Polygon
//
//  Created by Christian Hansen on 19/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (MD5Hash)

+ (NSString *)md5HashForFile:(NSString *)filePath;

@end
