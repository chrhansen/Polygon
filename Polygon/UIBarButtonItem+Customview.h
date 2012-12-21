//
//  UIBarButtonItem+Customview.h
//  Lifebeat
//
//  Created by Christian Hansen on 29/10/12.
//  Copyright (c) 2012 Kwamecorp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Customview)

+ (id)barButtonWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action;

+ (id)deleteButtonWithTarget:(id)target action:(SEL)action;

@end
