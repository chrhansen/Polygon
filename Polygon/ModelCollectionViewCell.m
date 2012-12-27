//
//  ModelCollectionViewCell.m
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ModelCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>
#define SHADOW_PART 0.95

@implementation ModelCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.layer.cornerRadius = 20.0;

    }
    return self;
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
