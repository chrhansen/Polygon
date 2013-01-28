//
//  DropboxCell.h
//  FEViewer2
//
//  Created by Christian Hansen on 5/1/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PGDropboxCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *folderFileImage;
@property (nonatomic, weak) IBOutlet UILabel *folderFileName;
@property (nonatomic, weak) IBOutlet UILabel *description;
@property (nonatomic) BOOL isFolder;

@end
