//
//  SKProduct+PriceAsString.h
//  Flow2Go
//
//  Created by Christian Hansen on 13/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import <StoreKit/StoreKit.h>

@interface SKProduct (PriceAsString)
@property (nonatomic, readonly) NSString *priceAsString;
@end
