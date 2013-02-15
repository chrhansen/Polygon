//
//  DropboxViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "PGDropboxViewController.h"
#import "PGDownloadManager.h"
#import "PGDropboxCell.h"
#import "NSString+_Format.h"
#import "PGModel+Management.h"
#import "UIBarButtonItem+Customview.h"
#import "UIImage+Alpha.h"

@interface PGDropboxViewController () <DownloadManagerDelegate>

@property (nonatomic, strong) NSArray *directoryContents;
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) UIBarButtonItem *tempBarButtonItem;

@end

@implementation PGDropboxViewController

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
    [self _addObservers];
    [self _addPullToRefresh];
    self.directoryContents = @[];
    
    if (!self.subPath) {
        self.subPath = @"";
        self.title = @"Dropbox";
    }
    if (!DBSession.sharedSession.isLinked) {
        [DBSession.sharedSession linkFromController:self];
    } else {
        [self _requestFolderList];
    }
}


- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSMutableArray *)selectedItems
{
    if (!_selectedItems) {
        _selectedItems = [NSMutableArray new];
    }
    return _selectedItems;
}

- (void)doneTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)_cancelTapped
{
    [self.selectedItems removeAllObjects];
    [self _setSelectSubitemsState];
    [self.tableView reloadData];
}


- (void)_addObservers
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_requestFolderList)
                                               name:DropboxLinkStateChangedNotification
                                             object:nil];
}

- (void)_addPullToRefresh
{
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(_requestFolderList) forControlEvents:UIControlEventValueChanged];
    refreshControl.tintColor = [UIColor lightGrayColor];
    self.refreshControl = refreshControl;
}

- (void)_requestFolderList
{
    if (DBSession.sharedSession.isLinked) {
        PGDownloadManager.sharedInstance.delegate = self;
        [self _showSpinner:YES];
        [PGDownloadManager.sharedInstance.restClient loadMetadata:[DropboxBaseURL stringByAppendingPathComponent:self.subPath]];
    } else {
        NSLog(@"not linked");
    }
}

- (void)_showSpinner:(BOOL)shouldShow
{
    UIBarButtonItem *barbuttonItem;
    if (shouldShow) {
        UIActivityIndicatorView *spinner = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [spinner startAnimating];
        barbuttonItem = [UIBarButtonItem.alloc initWithCustomView:spinner];
        self.tempBarButtonItem = self.navigationItem.rightBarButtonItem;
    } else {
        barbuttonItem = self.tempBarButtonItem;
        self.tempBarButtonItem = nil;
    }
    [self.navigationItem setRightBarButtonItem:barbuttonItem animated:YES];
}


- (void)_showSubDirectory:(DBMetadata *)directoryMetadata
{
    if (!directoryMetadata.isDirectory) {
        return;
    }
    PGDropboxViewController *nextLevelViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"dropboxViewController"];
    nextLevelViewController.subPath = [self.subPath stringByAppendingPathComponent:directoryMetadata.filename];
    nextLevelViewController.title = directoryMetadata.filename;
    [self.navigationController pushViewController:nextLevelViewController animated:YES];
}


- (void)_setSelectSubitemsState
{
    if (self.selectedItems.count > 0) {
        UIBarButtonItem *cancelButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelTapped)];
        [self.navigationItem setRightBarButtonItem:cancelButton animated:YES];
        UIBarButtonItem *downloadButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0107"] style:UIBarButtonItemStylePlain target:self action:@selector(_downloadSelectedItems)];
        [self.navigationItem setLeftBarButtonItem:downloadButton animated:YES];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    }
}

#pragma mark - Download manager delegate methods
- (void)downloadManager:(PGDownloadManager *)sender didLoadDirectoryContents:(NSArray *)contents
{
    [self _showSpinner:NO];
    [self.refreshControl endRefreshing];
    self.directoryContents = contents.copy;
    [self.tableView reloadData];
}


- (void)downloadManager:(PGDownloadManager *)downloadManager failedLoadingDirectoryContents:(NSError *)error
{
    [self _showSpinner:NO];
    [self.refreshControl endRefreshing];
    //TODO: alert user
}

- (void)downloadManager:(PGDownloadManager *)downloadManager didLoadThumbnail:(DBMetadata *)metadata
{
    NSUInteger tableViewRow = [self.directoryContents indexOfObject:metadata];
    PGDropboxCell *cell = (PGDropboxCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:tableViewRow inSection:0]];
    [self _loadThumbnail:cell.folderFileImage withMetadata:metadata];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.directoryContents.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Dropbox Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [self _configureCell:cell withMetaData:self.directoryContents[indexPath.row]];
    return cell;
}


- (void)_loadThumbnail:(UIImageView *)imageView withMetadata:(DBMetadata *)metadata
{
    NSString *fileName = [NSString stringWithFormat:@"%@-%@", metadata.rev, metadata.filename];
    NSString *filePath = [CACHE_DIR stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager new];
    if ([fileManager fileExistsAtPath:filePath]) {
        imageView.image = [UIImage imageWithContentsOfFile:filePath];
    } else {
        [PGDownloadManager.sharedInstance.restClient loadThumbnail:metadata.path ofSize:@"75x75_fit_one" intoPath:filePath];
    }
}


- (void)_configureCell:(UITableViewCell *)cell withMetaData:(DBMetadata *)metadata
{
    PGDropboxCell *dropboxCell = (PGDropboxCell *)cell;
    dropboxCell.folderFileName.text = [metadata.filename fitToLength:29];
    
    if (metadata.isDirectory) {
        dropboxCell.folderFileImage.image = [UIImage imageNamed:@"folder_icon.png"];
        dropboxCell.description.hidden = YES;
    } else {
        NSString *modifiedDuration = [NSString formatInterval:-[metadata.lastModifiedDate timeIntervalSinceNow]];
        dropboxCell.description.hidden = NO;
        dropboxCell.description.text = [metadata.humanReadableSize stringByAppendingString: [@", modified " stringByAppendingString:modifiedDuration]];
        dropboxCell.folderFileImage.image = ([PGModel modelTypeForFileName:metadata.filename] == ModelTypeUnknown) ? [UIImage imageNamed:@"180-stickynote"] : [UIImage imageNamed:@"dropbox_fileitem.png"];
    }
    
    if (metadata.thumbnailExists) [self _loadThumbnail:dropboxCell.folderFileImage withMetadata:metadata];
    
    if (self.selectedItems.count == 0) {
        if (!metadata.isDirectory) {
            if ([PGModel modelTypeForFileName:metadata.filename] == ModelTypeUnknown) {
                dropboxCell.userInteractionEnabled = NO;
                dropboxCell.folderFileName.textColor = [UIColor lightGrayColor];
                dropboxCell.description.textColor = [UIColor lightGrayColor];
            }
        }
    } else {
        if ([self.selectedItems containsObject:metadata]) {
            dropboxCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        DBMetadata *primaryItem = self.selectedItems[0];
        if (primaryItem == metadata) {
            dropboxCell.userInteractionEnabled = NO;
        } else if (![PGModel canHaveSubItems:primaryItem.filename]
                   || !([PGModel modelTypeForFileName:metadata.filename] == ModelTypeUnknown)
                   || metadata.isDirectory) {
            dropboxCell.userInteractionEnabled = NO;
            dropboxCell.folderFileName.textColor = [UIColor lightGrayColor];
            dropboxCell.description.textColor = [UIColor lightGrayColor];
            dropboxCell.folderFileImage.image = [dropboxCell.folderFileImage.image imageByApplyingAlpha:0.5f];
        }
    }
}


- (void)_togglePresenceInSelectedItems:(DBMetadata *)subItem
{
    if ([self.selectedItems containsObject:subItem]) {
        [self.selectedItems removeObject:subItem];
    } else {
        [self.selectedItems addObject:subItem];
    }
}

#pragma mark - Table view delegate
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedItems.count > 0) {
        DBMetadata *primaryItem = self.selectedItems[0];
        return [PGModel canHaveSubItems:primaryItem.filename];
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBMetadata *pickedItem = self.directoryContents[indexPath.row];
    if (self.selectedItems.count == 0) {
        if (pickedItem.isDirectory) {
            [self _showSubDirectory:pickedItem];
        } else {
            [self _selectedPrimaryFile:self.directoryContents[indexPath.row] atIndexPath:indexPath];
        }
    } else {
        DBMetadata *primaryItem = self.selectedItems[0];
        switch ([PGModel modelTypeForFileName:primaryItem.filename]) {
            case ModelTypeOBJ:
            case ModelTypeDAE:
                [self _togglePresenceInSelectedItems:pickedItem];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            default:
                break;
        }
    }
}


- (void)_selectedPrimaryFile:(DBMetadata *)primaryItem atIndexPath:(NSIndexPath *)indexPath
{
    if ([PGModel modelTypeForFileName:primaryItem.filename] == ModelTypeUnknown) {
        return;
    }
    [self.selectedItems addObject:primaryItem];
    [self _setSelectSubitemsState];
    [self.tableView reloadData];
}


- (void)_downloadSelectedItems
{
    DBMetadata *rootModel = self.selectedItems[0];
    [self.selectedItems removeObjectAtIndex:0];
    [PGDownloadManager.sharedInstance downloadFilesAndDirectories:self.selectedItems.copy rootFile:rootModel];
    [self.selectedItems removeAllObjects];
    [self _setSelectSubitemsState];
    [self.tableView reloadData];
}

@end
