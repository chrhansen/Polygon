//
//  ShelfView.m
//  Polygon
//
//  Created by Christian Hansen on 20/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ShelfView.h"

@implementation ShelfView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if (IS_IPAD) {
            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"clean-shelf"]];
        } else {
            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"clean-shelf-iphone"]];
        }
//
//        UIImage *backGround = [UIImage imageNamed:@"clena-shelf-minimized"];
//        UIEdgeInsets insets = UIEdgeInsetsMake(0, 80.0f, 0, 80.0f);
//        UIImage *resizedImage = [backGround resizableImageWithCapInsets:insets];
//        self.backgroundColor = [UIColor colorWithPatternImage:resizedImage];
        // Initialization code
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
