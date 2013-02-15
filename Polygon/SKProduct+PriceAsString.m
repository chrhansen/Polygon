//
//  SKProduct+PriceAsString.m
//  Flow2Go
//
//  Created by Christian Hansen on 13/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "SKProduct+PriceAsString.h"

@implementation SKProduct (PriceAsString)

- (NSString *) priceAsString
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:[self priceLocale]];
    
    NSString *str = [formatter stringFromNumber:[self price]];
    return str;
}

@end
