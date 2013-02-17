//
//  ModelCollectionViewCell.m
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGModelCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation PGModelCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

#define CORNER_RADIUS 4

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        self.modelImageView.layer.cornerRadius = CORNER_RADIUS;
//        self.modelImageView.layer.borderColor = [UIColor whiteColor].CGColor;
//        self.modelImageView.layer.borderWidth = 1.5f;
        self.modelImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.modelImageView.layer.shouldRasterize = YES;
        
        self.topContentView.layer.cornerRadius = CORNER_RADIUS;
        self.topContentView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.topContentView.layer.shadowRadius = 6.0f;
        self.topContentView.layer.shadowOpacity = 0.8f;
        self.topContentView.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        self.topContentView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.topContentView.layer.shouldRasterize = YES;
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
