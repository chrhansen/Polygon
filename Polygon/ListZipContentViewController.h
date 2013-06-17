//
//  ListZipContentViewController.h
//  Polygon
//
//  Created by Christian Hansen on 27/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ListZipContentViewController;

@protocol ListZipContentViewControllerDelegate <NSObject>

- (void)listZipContentViewController:(ListZipContentViewController *)sender extractedZipPath:(NSString *)filepath;

@end

@interface ListZipContentViewController : UITableViewController

@property (nonatomic,strong) NSString *filePathForZip;
@property (nonatomic, weak) id<ListZipContentViewControllerDelegate> delegate;

@end
