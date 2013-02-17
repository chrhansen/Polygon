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
        
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
