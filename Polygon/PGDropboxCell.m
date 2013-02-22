//
//  DropboxCell.m
//  FEViewer2
//
//  Created by Christian Hansen on 5/1/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGDropboxCell.h"
#import "UIImage+Alpha.h"

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

- (void)setUnselectable
{
    self.userInteractionEnabled = NO;
    self.folderFileName.textColor = [UIColor lightGrayColor];
    self.description.textColor = [UIColor lightGrayColor];
    self.folderFileImage.image = [self.folderFileImage.image imageByApplyingAlpha:0.5f];
}


- (void)prepareForReuse
{
    self.folderFileName.textColor = [UIColor blackColor];
    self.description.textColor = [UIColor darkGrayColor];
    self.userInteractionEnabled = YES;
    self.accessoryType = UITableViewCellAccessoryNone;
}

@end
