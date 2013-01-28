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
- (void)awakeFromNib
{
    [super awakeFromNib];
    self.modelImageView.layer.cornerRadius = 5.0f;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.layer.cornerRadius = 7.0;
        self.contentView.backgroundColor = [UIColor underPageBackgroundColor];

    }
    return self;
}


- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview)
    {
        self.contentView.layer.shadowOffset = CGSizeMake(0, 0);
        if (IS_IPAD) {
            self.contentView.layer.shadowOpacity = 0.7;
            self.contentView.layer.shadowRadius = 7;
            self.contentView.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.contentView.bounds,0,2) cornerRadius:self.modelImageView.layer.cornerRadius] CGPath];
        } else {
            self.contentView.layer.shadowOpacity = 0.7;
            self.contentView.layer.shadowRadius = 5;
            self.contentView.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.contentView.bounds,1,3) cornerRadius:self.modelImageView.layer.cornerRadius] CGPath];
        }
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
