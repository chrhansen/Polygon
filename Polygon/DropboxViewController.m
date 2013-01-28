//
//  DropboxViewController.m
//  Flow2Go
//
//  Created by Christian Hansen on 02/08/12.
//  Copyright (c) 2012 Christian Hansen. All rights reserved.
//

#import "DropboxViewController.h"
#import "DownloadManager.h"
#import "DropboxCell.h"
#import "NSString+_Format.h"
#import "PGModel+Management.h"
#import "UIBarButtonItem+Customview.h"

@interface DropboxViewController () <DownloadManagerDelegate>

@property (nonatomic, strong) NSArray *directoryContents;
@property (nonatomic, strong) NSMutableArray *selectedItems;

@end

@implementation DropboxViewController

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
    
    self.directoryContents = @[];
    
    if (!self.subPath) {
        self.subPath = @"";
        self.title = @"Dropbox";
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!DBSession.sharedSession.isLinked)
    {
        [DBSession.sharedSession linkFromController:self];
    }
    else
    {
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
    self.tableView.allowsMultipleSelection = NO;
    [self _setSelectSubitemsState];
    [self.tableView reloadData];
}


- (void)_addObservers
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_requestFolderList)
                                               name:DropboxLinkedNotification
                                             object:nil];
}


- (void)_requestFolderList
{
    if (DBSession.sharedSession.isLinked) {
        DownloadManager.sharedInstance.delegate = self;
        [DownloadManager.sharedInstance.restClient loadMetadata:[DropboxBaseURL stringByAppendingPathComponent:self.subPath]];
    } else {
        NSLog(@"not linked");
    }
}


- (void)_setSelectSubitemsState
{
    if (self.tableView.allowsMultipleSelection)
    {
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
- (void)downloadManager:(DownloadManager *)sender didLoadDirectoryContents:(NSArray *)contents
{
    self.directoryContents = contents.copy;
    [self.tableView reloadData];
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
    if (self.tableView.allowsMultipleSelection) {
        [self _selectSubitemsStateConfigureCell:cell withMetaData:self.directoryContents[indexPath.row]];
    } else {
        [self _configureCell:cell withMetaData:self.directoryContents[indexPath.row]];
    }
    return cell;
}


- (void)_configureCell:(UITableViewCell *)cell withMetaData:(DBMetadata *)metadata
{
    DropboxCell *dropboxCell = (DropboxCell *)cell;
    CGRect cellRect = dropboxCell.folderFileName.frame;
    
    dropboxCell.folderFileName.textColor = [UIColor blackColor];
    dropboxCell.description.textColor = [UIColor darkGrayColor];
    dropboxCell.userInteractionEnabled = YES;
    dropboxCell.accessoryType = UITableViewCellAccessoryNone;

    dropboxCell.folderFileName.text = [metadata.filename fitToLength:29];
    if (metadata.isDirectory)
    {
        dropboxCell.folderFileImage.image = [UIImage imageNamed:@"folder_icon.png"];
        dropboxCell.folderFileName.frame = CGRectMake(cellRect.origin.x, 11, cellRect.size.width, cellRect.size.height);
        dropboxCell.description.hidden = YES;
    }
    else
    {
        // is a file (not directory)
        if ([PGModel modelTypeForFileName:metadata.filename] == ModelTypeUnknown)
        {
            dropboxCell.userInteractionEnabled = NO;
            dropboxCell.folderFileName.textColor = [UIColor lightGrayColor];
            dropboxCell.description.textColor = [UIColor lightGrayColor];
            dropboxCell.folderFileImage.image = nil;
        }
        else
        {
            dropboxCell.folderFileImage.image = [UIImage imageNamed:@"dropbox_fileitem.png"];
        }
        
        NSString *modifiedDuration = [NSString formatInterval:-[metadata.lastModifiedDate timeIntervalSinceNow]];
        dropboxCell.description.hidden = NO;
        dropboxCell.folderFileName.frame = CGRectMake(cellRect.origin.x, 5, cellRect.size.width, cellRect.size.height);
        dropboxCell.description.text = [metadata.humanReadableSize stringByAppendingString: [@", modified " stringByAppendingString:modifiedDuration]];
    }
}


- (void)_selectSubitemsStateConfigureCell:(UITableViewCell *)cell withMetaData:(DBMetadata *)metadata
{
    DropboxCell *dropboxCell = (DropboxCell *)cell;
    CGRect cellRect = dropboxCell.folderFileName.frame;
    
    dropboxCell.folderFileName.textColor = [UIColor blackColor];
    dropboxCell.description.textColor = [UIColor darkGrayColor];
    dropboxCell.userInteractionEnabled = YES;
    dropboxCell.accessoryType = UITableViewCellAccessoryNone;
    dropboxCell.folderFileName.text = [metadata.filename fitToLength:29];
    if (metadata.isDirectory)
    {
        dropboxCell.folderFileImage.image = [UIImage imageNamed:@"folder_icon.png"];
        dropboxCell.folderFileName.frame = CGRectMake(cellRect.origin.x, 11, cellRect.size.width, cellRect.size.height);
        dropboxCell.description.hidden = YES;
    }
    else
    {
        // is a file (not directory)
        if ([PGModel modelTypeForFileName:metadata.filename] == ModelTypeUnknown)
        {
            dropboxCell.folderFileImage.image = nil;
        }
        else
        {
            dropboxCell.folderFileImage.image = [UIImage imageNamed:@"dropbox_fileitem.png"];
        }
        
        NSString *modifiedDuration = [NSString formatInterval:-[metadata.lastModifiedDate timeIntervalSinceNow]];
        dropboxCell.description.hidden = NO;
        dropboxCell.folderFileName.frame = CGRectMake(cellRect.origin.x, 5, cellRect.size.width, cellRect.size.height);
        dropboxCell.description.text = [metadata.humanReadableSize stringByAppendingString: [@", modified " stringByAppendingString:modifiedDuration]];
    }
    if ([self.selectedItems containsObject:metadata]) {
        dropboxCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    if (self.selectedItems[0] == metadata) {
        dropboxCell.userInteractionEnabled = NO;
        dropboxCell.folderFileName.textColor = [UIColor lightGrayColor];
        dropboxCell.description.textColor = [UIColor lightGrayColor];
        dropboxCell.folderFileImage.image = nil;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBMetadata *pickedItem = self.directoryContents[indexPath.row];
    // Select subitems state
    if (self.tableView.allowsMultipleSelection) {
        [self _togglePresenceInSelectedItems:pickedItem];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        return;
    }
    
    // Normal selection state
    if (pickedItem.isDirectory)
    {
        DropboxViewController *nextLevelViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"dropboxViewController"];
        nextLevelViewController.subPath = [self.subPath stringByAppendingPathComponent:pickedItem.filename];
        nextLevelViewController.title = pickedItem.filename;
        [self.navigationController pushViewController:nextLevelViewController animated:YES];
    }
    else
    {
        [self _handleSelectedModelFile:self.directoryContents[indexPath.row] atIndexPath:indexPath];
    }
}


- (void)_handleSelectedModelFile:(DBMetadata *)metadata atIndexPath:(NSIndexPath *)indexPath
{
    switch ([PGModel modelTypeForFileName:metadata.filename ])
    {
        case ModelTypeAnsys:
        case ModelTypeNastran:
        case ModelTypeLSPrePost:
            [DownloadManager.sharedInstance downloadFile:metadata];
            break;
            
        case ModelTypeOBJ:
        case ModelTypeDAE:
        {
            [self.selectedItems addObject:metadata];
            self.tableView.allowsMultipleSelection = YES;
            [self _setSelectSubitemsState];
            [self.tableView reloadData];
        }
            break;
        default:
            break;
    }
}


- (void)_downloadSelectedItems
{
    DBMetadata *rootModel = self.selectedItems[0];
    [self.selectedItems removeObjectAtIndex:0];
    [DownloadManager.sharedInstance downloadFilesAndDirectories:self.selectedItems.copy rootFile:rootModel];
    [self.selectedItems removeAllObjects];
    self.tableView.allowsMultipleSelection = NO;
    [self _setSelectSubitemsState];
    [self.tableView reloadData];
}

@end
