//
//  PGTransparencyViewController.h
//  Polygon
//
//  Created by Christian Hansen on 18/02/13.
//  Copyright (c) 2013 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PGTransparencyDelegate <NSObject>

@optional
- (void)transparencyChanged:(UISlider *)sender; // values between 0.0 and 1.0

@end

@interface PGTransparencyViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISlider *transparencySlider;
@property (weak, nonatomic) id<PGTransparencyDelegate> delegate;

@end
