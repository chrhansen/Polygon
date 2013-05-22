//
//  PGInfoTableViewController.h
//  Polygon
//
//  Created by Christian Hansen on 22/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PGModel, PGInfoTableViewController;

@protocol PGInfoTableViewControllerDelegate <NSObject>

- (void)infoTableViewController:(PGInfoTableViewController *)infoController didRequestAddingSubItemsToModel:(PGModel *)model;

@end

@interface PGInfoTableViewController : UITableViewController

@property (nonatomic, strong) PGModel *model;
@property (nonatomic, weak) id <PGInfoTableViewControllerDelegate> delegate;
@end
