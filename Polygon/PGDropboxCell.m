//
//  DropboxCell.m
//  FEViewer2
//
//  Created by Christian Hansen on 5/1/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGDropboxCell.h"

@implementation PGDropboxCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        self.selectionStyle = UITableViewCellAccessoryNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}


- (void)prepareForReuse
{
    self.folderFileName.textColor = [UIColor blackColor];
    self.description.textColor = [UIColor darkGrayColor];
    self.userInteractionEnabled = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
}

@end
