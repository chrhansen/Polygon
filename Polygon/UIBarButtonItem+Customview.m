//
//  UIBarButtonItem+Customview.m
//  Lifebeat
//
//  Created by Christian Hansen on 29/10/12.
//  Copyright (c) 2012 Kwamecorp. All rights reserved.
//

#import "UIBarButtonItem+Customview.h"

@implementation UIBarButtonItem (Customview)

+ (id)barButtonWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, MAX(44, image.size.width), 44);
    button.contentMode = UIViewContentModeCenter;
    [button setShowsTouchWhenHighlighted:YES];
    
    [button setImage:image forState:UIControlStateNormal];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return barButtonItem;
}

+ (id)deleteButtonWithTarget:(id)target action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
    [button setTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0f];
    [button.layer setCornerRadius:4.0f];
    [button.layer setMasksToBounds:YES];
    [button.layer setBorderWidth:1.0f];
    [button.layer setBorderColor: [[UIColor grayColor] CGColor]];
    button.frame = CGRectMake(0.0, 100.0, 60.0, 30.0);
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return [UIBarButtonItem.alloc initWithCustomView:button];
}

@end
