//
//  PGInfoTableViewController.m
//  Polygon
//
//  Created by Christian Hansen on 22/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGInfoTableViewController.h"
#import "PGModel+Management.h"
#import "NSString+_Format.h"
#import "PGView+Management.h"
#import "UIImage+Resize.h"
#import "PGDropboxViewController.h"

@interface PGInfoTableViewController ()

@property (nonatomic, strong) NSDictionary *subitems;
@property (nonatomic, strong) NSArray *views;
@property (nonatomic, strong) dispatch_queue_t imageQueue;
@property (nonatomic, strong) NSMutableDictionary *images;

@end

@implementation PGInfoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageQueue = dispatch_queue_create("it.calcul8.imageQueue", NULL);
    self.images = [NSMutableDictionary new];
    self.title = self.model.modelName;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.images removeAllObjects];
}


- (NSDictionary *)subitems
{
    if (!_subitems) {
        _subitems = self.model.subitems;
    }
    return _subitems;
}


- (NSArray *)views
{
    if (!_views) {
        _views = self.model.views.array;
    }
    return _views;
}


- (IBAction)showDropbox
{
    PGDropboxViewController *dropboxViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"dropboxViewController"];
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:dropboxViewController];
    navCon.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navCon animated:YES completion:nil];
}


- (void)configureBasicCell:(UITableViewCell *)cell atRow:(NSUInteger)row
{
    switch (row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Added", nil);
            cell.detailTextLabel.text = self.model.dateAddedAsLocalizedString.capitalizedString;
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Size", nil);
            cell.detailTextLabel.text = [NSString humanReadableFileSize:self.model.modelSize];
            break;
            
        default:
            break;
    }
}


- (void)configureSavedViewCell:(UITableViewCell *)cell atRow:(NSUInteger)row
{
    PGView *savedView = self.views[row];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    imageView.image = savedView.image;
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:2];
    titleLabel.text = savedView.title;
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:3];
    dateLabel.text = savedView.dateAddedAsLocalizedString;
}


- (void)configureSubitemCell:(UITableViewCell *)cell atRow:(NSUInteger)row
{
    NSArray *sortedKeys = [[self.subitems allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    NSString *filePath = sortedKeys[row];
    
    UILabel *fileNameLabel = (UILabel *)[cell viewWithTag:2];
    fileNameLabel.text = filePath.lastPathComponent;

    UILabel *fileSizeLabel = (UILabel *)[cell viewWithTag:3];
    NSNumber *fileSize = self.subitems[filePath][NSFileSize];
    fileSizeLabel.text = [NSString humanReadableFileSize:fileSize];

    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    
    
    UIImage *image = self.images[filePath];
    imageView.image = image;
    UILabel *extensionLabel = (UILabel *)[cell viewWithTag:4];
    if (image) {
        extensionLabel.hidden = YES;
    } else {
        extensionLabel.hidden = NO;
        extensionLabel.text = [NSString stringWithFormat:@".%@", filePath.pathExtension];
        [self loadImage:filePath forIndexPath:[NSIndexPath indexPathForItem:row inSection:2]];
    }
}

#define IMAGEVIEW_WIDTH 84
#define IMAGEVIEW_HEIGHT 84

- (void)loadImage:(NSString *)imagePath forIndexPath:(NSIndexPath *)indexPath
{
    dispatch_async(self.imageQueue, ^{
        CGFloat scale = [[UIScreen mainScreen] scale]; //Retina vs. non-retina
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        image = [image resizedImage:CGSizeMake(IMAGEVIEW_WIDTH * scale, IMAGEVIEW_HEIGHT * scale) interpolationQuality:kCGInterpolationDefault];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                [self.images setValue:image forKey:imagePath];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell) [self configureSubitemCell:cell atRow:indexPath.row];
            }
        });
    });
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 2;
            break;
            
        case 1:
            return self.views.count;
            break;
            
        case 2:
            return self.subitems.count;
            break;
            
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *BasicCellIdentifier = @"Basic Info Cell";
    static NSString *SavedViewCellIdentifier = @"Saved View Cell";
    static NSString *SubItemCellIdentifier = @"SubItem Cell";
    
    UITableViewCell *cell;
    
    switch (indexPath.section)
    {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:BasicCellIdentifier forIndexPath:indexPath];
            [self configureBasicCell:cell atRow:indexPath.row];
            break;
            
        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:SavedViewCellIdentifier forIndexPath:indexPath];
            if (cell) {
                [self configureSavedViewCell:cell atRow:indexPath.row];
            }
            break;
            
        case 2:
            cell = [tableView dequeueReusableCellWithIdentifier:SubItemCellIdentifier forIndexPath:indexPath];
            if (cell) {
                [self configureSubitemCell:cell atRow:indexPath.row];
            }
            break;
            
        default:
            break;
    }

    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return NSLocalizedString(@"Basic Info", nil);
            break;
            
        case 1:
            return NSLocalizedString(@"Saved Views", nil);
            break;
            
        case 2:
            return NSLocalizedString(@"Sub Items", nil);
            break;
            
        default:
            break;
    }
    return nil;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section)
    {
        case 1:
            if (self.views.count == 0) {
                return NSLocalizedString(@"There is no saved views", nil);
            }
            break;
            
        case 2:
            if (self.subitems.count == 0) {
                return NSLocalizedString(@"This model has no subitems", nil);
            }
            break;
            
        default:
            break;
    }
    return nil;
}
#pragma mark TableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
            return 44.f;
            break;
            
        case 1:
        case 2:
            return 100.f;
            break;

        default:
            break;
    }
    return 44.f;
}

@end
