//
//  DropboxViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "PGDropboxViewController.h"
#import "PGDownloadManager.h"
#import "PGUploadManager.h"
#import "PGDropboxCell.h"
#import "NSString+_Format.h"
#import "PGModel+Management.h"
#import "UIBarButtonItem+Customview.h"
#import "UIImage+Alpha.h"

@interface PGDropboxViewController () <DownloadManagerDelegate, UploadManagerProgressDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) NSArray *directoryContents;
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) UIBarButtonItem *tempBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *tempLeftBarButtonItem;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end

@implementation PGDropboxViewController


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
    [self _toggleSelectSubitemsState];
    if (DBSession.sharedSession.isLinked) {
        [self _requestFolderList];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.dropboxViewControllerType == PGDropboxViewControllerTypeUpload) [self showUploadInterface];
    if (!DBSession.sharedSession.isLinked) {
        [DBSession.sharedSession linkFromController:self];
    }
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

-(NSUInteger)supportedInterfaceOrientations
{
    if (IS_IPAD) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)showUploadInterface
{
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (NSMutableArray *)selectedItems
{
    if (!_selectedItems) _selectedItems = [NSMutableArray new];
    return _selectedItems;
}

- (void)doneTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)_cancelTapped
{
    [self.selectedItems removeAllObjects];
    [self _toggleSelectSubitemsState];
    if (self.dropboxViewControllerType == PGDropboxViewControllerTypeAddTo) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.tableView reloadData];
    }
}


- (IBAction)newFolderTapped:(id)sender
{
    UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Folder Name", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Add", nil), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}


- (IBAction)chooseFolderTapped:(id)sender
{
    [self _showSpinner:YES];
    [self.progressHUD show:YES];
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [[PGUploadManager sharedInstance] uploadModel:self.uploadModel toPath:[DropboxBaseURL stringByAppendingPathComponent:self.subPath] progressDelegate:self completion:^(NSError *error) {
        [self _showSpinner:NO];
        if (!error) {
            self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
            self.progressHUD.mode = MBProgressHUDModeCustomView;
            self.progressHUD.labelText = NSLocalizedString(@"Uploaded!", nil);
            [self.progressHUD hide:YES afterDelay:2.0f];
        } else {
            [self showHUDMessage:error.userInfo[@"error"]];
        }
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];
        [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
        [self _requestFolderList];
    }];
}


- (void)_addObservers
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_requestFolderList) name:DropboxLinkStateChangedNotification object:nil];
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
    nextLevelViewController.dropboxViewControllerType = self.dropboxViewControllerType;
    nextLevelViewController.uploadModel = self.uploadModel;
    nextLevelViewController.addToModel = self.addToModel;
    [self.navigationController pushViewController:nextLevelViewController animated:YES];
}


- (void)_toggleSelectSubitemsState
{
    if ([self.selectedItems count]) {
        UIBarButtonItem *cancelButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelTapped)];
        [self.navigationItem setRightBarButtonItem:cancelButton animated:YES];
        UIBarButtonItem *downloadButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0107"] style:UIBarButtonItemStylePlain target:self action:@selector(_downloadSelectedItems)];
        [self.navigationItem setLeftBarButtonItem:downloadButton animated:YES];
    } else {
        if (self.dropboxViewControllerType == PGDropboxViewControllerTypeAddTo) {
            UIBarButtonItem *cancelButton = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelTapped)];
            [self.navigationItem setRightBarButtonItem:cancelButton animated:YES];
        } else {
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
            if ([self.subPath isEqualToString:@""]) {
                if (!self.tempLeftBarButtonItem) {
                    self.tempLeftBarButtonItem = self.navigationItem.leftBarButtonItem;
                }
                [self.navigationItem setLeftBarButtonItem:self.tempLeftBarButtonItem animated:YES];
            } else {
                [self.navigationItem setLeftBarButtonItem:nil animated:YES];
            }
        }
    }
}

#pragma mark - UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self _showSpinner:YES];
        NSString *folderName = [alertView textFieldAtIndex:0].text;
        [[PGUploadManager sharedInstance] createDropboxFolder:folderName atPath:self.subPath completion:^(NSError *error) {
            [self _showSpinner:NO];
            if (!error) {
                [self _requestFolderList];
            } else {
                [self showHUDMessage:error.userInfo[@"error"]];
            }
        }];
    }
}


- (void)showHUDMessage:(NSString *)message
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:3];
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
    [self showHUDMessage:NSLocalizedString(@"Oops! Couldn't load the folder.", nil)];
}

- (void)downloadManager:(PGDownloadManager *)downloadManager didLoadThumbnail:(DBMetadata *)metadata
{
    NSUInteger tableViewRow = [self.directoryContents indexOfObject:metadata];
    PGDropboxCell *cell = (PGDropboxCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:tableViewRow inSection:0]];
    [self _loadThumbnail:cell.folderFileImage withMetadata:metadata];
}


#pragma mark - Upload manager delegate methods
- (void)uploadManager:(PGUploadManager *)uploadManager uploadProgress:(CGFloat)progress forModel:(PGModel *)model
{
    self.progressHUD.mode = MBProgressHUDModeAnnularDeterminate;
    self.progressHUD.progress = progress;
}

- (void)uploadManager:(PGUploadManager *)uploadManager finishedUploadingModel:(PGModel *)model
{
    self.progressHUD.progress = 1.0f;
}

- (void)uploadManager:(PGUploadManager *)uploadManager failedUploadingModel:(PGModel *)model
{
    [self.progressHUD hide:YES];
}


- (MBProgressHUD *)progressHUD
{
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.view addSubview:_progressHUD];
        _progressHUD.mode = MBProgressHUDModeIndeterminate;
        _progressHUD.delegate = self;
        _progressHUD.labelText = NSLocalizedString(@"Uploading", nil);
        _progressHUD.removeFromSuperViewOnHide = YES;
    }
    return _progressHUD;
}


#pragma mark - Table view data source

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
    switch (self.dropboxViewControllerType) {
        case PGDropboxViewControllerTypeDownload:
            
            if (self.selectedItems.count == 0) {
                if (!metadata.isDirectory) {
                    if ([PGModel modelTypeForFileName:metadata.filename] == ModelTypeUnknown) {
                        [dropboxCell setUnselectable];
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
                    [dropboxCell setUnselectable];
                }
            }
            break;
        case PGDropboxViewControllerTypeUpload:
            if (!metadata.isDirectory) {
                [dropboxCell setUnselectable];
            }
            break;
        case PGDropboxViewControllerTypeAddTo:
            if ([self.selectedItems containsObject:metadata]) dropboxCell.accessoryType = UITableViewCellAccessoryCheckmark;
        
            if (![PGModel modelTypeForFileName:metadata.filename] == ModelTypeUnknown) {
                [dropboxCell setUnselectable];
            }
            break;
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
    if ([self.selectedItems count]) {
        NSString *fileName = self.addToModel.filePath.lastPathComponent;
        if (!fileName) {
            DBMetadata *primaryItem = self.selectedItems[0];
            fileName = primaryItem.filename;
        }
        return [PGModel canHaveSubItems:fileName];
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
            if (self.addToModel) {
                [self _togglePresenceInSelectedItems:pickedItem];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self _toggleSelectSubitemsState];
            } else {
                [self _selectedPrimaryFile:self.directoryContents[indexPath.row] atIndexPath:indexPath];
            }
        }
    } else {
        NSString *fileName = self.addToModel.filePath.lastPathComponent;
        if (!fileName) {
            DBMetadata *primaryItem = self.selectedItems[0];
            fileName = primaryItem.filename;
        }
        switch ([PGModel modelTypeForFileName:fileName]) {
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
    [self _toggleSelectSubitemsState];
    [self.tableView reloadData];
}


- (void)_downloadSelectedItems
{
    if (self.addToModel) {
        [PGDownloadManager.sharedInstance downloadFilesAndDirectories:self.selectedItems.copy toModel:self.addToModel];
        [self.selectedItems removeAllObjects];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        DBMetadata *rootModel = self.selectedItems[0];
        [self.selectedItems removeObjectAtIndex:0];
        [PGDownloadManager.sharedInstance downloadFilesAndDirectories:self.selectedItems.copy rootFile:rootModel];
        [self.selectedItems removeAllObjects];
        [self _toggleSelectSubitemsState];
        [self.tableView reloadData];
    }
}

@end
