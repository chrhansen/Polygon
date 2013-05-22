//
//  FGStoreCell.m
//  Flow2Go
//
//  Created by Christian Hansen on 13/02/13.
//  Copyright (c) 2013 Christian Hansen. All rights reserved.
//

#import "PGStoreCell.h"
#import <QuartzCore/QuartzCore.h>
@implementation PGStoreCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        self.layer.cornerRadius = 5;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 1.0f;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowRadius = 3;
        self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.layer.shadowOpacity = 0.6f;
        self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.layer.shouldRasterize = YES;

        
        self.mainImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        self.mainImageView.layer.borderWidth = 1.0f;
        self.mainImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.mainImageView.layer.shadowRadius = 3.0f;
        self.mainImageView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        self.mainImageView.layer.shadowOpacity = 0.5f;
        self.mainImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.mainImageView.layer.shouldRasterize = YES;
        
        [self configureBuyButton];
        [self addTextShadow];        
    }
}

- (void)configureBuyButton
{
    UIImage *buttonImage = [[UIImage imageNamed:@"blueButton.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"blueButtonHighlight.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageDisabled = [[UIImage imageNamed:@"greenButton.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    // Set the background for any states you plan to use
    [self.buyButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.buyButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [self.buyButton setBackgroundImage:buttonImageDisabled forState:UIControlStateDisabled];
    
    [self.buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}


- (void)addTextShadow
{
    self.titleLabel.layer.shadowOpacity = 0.4;
    self.titleLabel.layer.shadowRadius = 3.0;
    self.titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.titleLabel.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.titleLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.titleLabel.layer.shouldRasterize = YES;
    
    self.descriptionLabel.layer.shadowOpacity = 0.5;
    self.descriptionLabel.layer.shadowRadius = 2.0;
    self.descriptionLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.descriptionLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    self.descriptionLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    self.descriptionLabel.layer.shouldRasterize = YES;
}

@end
