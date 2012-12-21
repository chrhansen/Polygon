//
//  NSString+_Format.m
//  FEViewer2
//
//  Created by Christian Hansen on 5/1/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "NSString+_Format.h"

@interface SOFileSizeFormatter : NSNumberFormatter
{
@private
    BOOL useBaseTenUnits;
}

@property (nonatomic, readwrite, assign, getter=isUsingBaseTenUnits) BOOL useBaseTenUnits;

@end

static const char sUnits[] = { '\0', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y' };
static int sMaxUnits = sizeof sUnits - 1;

@implementation SOFileSizeFormatter

@synthesize useBaseTenUnits;

- (NSString *) stringFromNumber:(NSNumber *)number
{
    int multiplier = useBaseTenUnits ? 1000 : 1024;
    int exponent = 0;
    
    double bytes = [number doubleValue];
    
    while ((bytes >= multiplier) && (exponent < sMaxUnits)) {
        bytes /= multiplier;
        exponent++;
    }
    
    return [NSString stringWithFormat:@"%@ %cB", [super stringFromNumber: [NSNumber numberWithDouble: bytes]], sUnits[exponent]];
}

@end

@implementation NSString (_Format)

- (NSString *)fitToLength:(NSUInteger)maxLength
{
    if (maxLength < 3) {
        maxLength = 3;
    }
    if (self.length <= maxLength) {
        return self;
    } else {
        NSUInteger excessCharacters = self.length-maxLength;
        return [self stringByReplacingCharactersInRange:NSMakeRange(maxLength/2-1, excessCharacters+3) withString:@"..."];
    }
}


+ (NSString *)formatInterval:(NSTimeInterval)elapsedTime
{    
    NSString *result;
    div_t months = div(elapsedTime, 2592000);
    div_t weeks = div(elapsedTime, 604800);
    div_t days = div(elapsedTime, 86400);
    div_t hours = div(elapsedTime, 3600);
    div_t minutes = div(elapsedTime, 60);
    div_t seconds = div(elapsedTime, 1);;
    
    if (months.quot >= 1) {
        if (months.quot == 1) {
            result = [[NSString stringWithFormat:@"%d ", months.quot] stringByAppendingString:@"month ago"];
        } else {
            result = [[NSString stringWithFormat:@"%d ", months.quot] stringByAppendingString:@"months ago"];
        }
    } else if (weeks.quot >= 1) {
        if (weeks.quot == 1) {
            result = [[NSString stringWithFormat:@"%d ", weeks.quot] stringByAppendingString:@"week ago"];
        } else {
            result = [[NSString stringWithFormat:@"%d ", weeks.quot] stringByAppendingString:@"weeks ago"];
        }
    } else if (days.quot >= 1) {
        if (days.quot == 1) {
            result = [[NSString stringWithFormat:@"%d ", days.quot] stringByAppendingString:@"day ago"];
        } else {
            result = [[NSString stringWithFormat:@"%d ", days.quot] stringByAppendingString:@"days ago"];
        }
    } else if (hours.quot >= 1) {
        if (hours.quot == 1) {
            result = [[NSString stringWithFormat:@"%d ", hours.quot] stringByAppendingString:@"hour ago"];
        } else {
            result = [[NSString stringWithFormat:@"%d ", hours.quot] stringByAppendingString:@"hours ago"];
        }
    } else if (minutes.quot >= 1) {
        if (minutes.quot == 1) {
            result = [[NSString stringWithFormat:@"%d ", minutes.quot] stringByAppendingString:@"minute ago"];
        } else {
            result = [[NSString stringWithFormat:@"%d ", minutes.quot] stringByAppendingString:@"minutes ago"];
        }
    } else if (seconds.quot >= 1) {
        if (seconds.quot > 30) {
            result = [[NSString stringWithFormat:@"%d ", seconds.quot] stringByAppendingString:@"seconds ago"];
        } else {
            result = @"just now";
        }
    } else {
        result = @"just now";
    }
    return result;
}


+ (NSString *)humanReadableFileSize:(NSNumber *)fileSize
{
    SOFileSizeFormatter *sizeFormatter = [[SOFileSizeFormatter alloc] init];
    [sizeFormatter setMaximumFractionDigits:1];
    return [sizeFormatter stringFromNumber:fileSize];
}

+ (NSString *)timeStamp
{
    NSDate *date = NSDate.date;
    return [NSString stringWithFormat:@"%@-%@-%@", 
            [date.description substringToIndex:10],
            [[date.description substringWithRange:NSMakeRange(11, 8)] stringByReplacingOccurrencesOfString:@":" withString:@"_"],
            [date.description substringWithRange:NSMakeRange(21, 4)]];
}

@end
