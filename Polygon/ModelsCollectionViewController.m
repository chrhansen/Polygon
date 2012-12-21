//
//  ModelsCollectionViewController.m
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ModelsCollectionViewController.h"
#import "FEModel+Management.h"
#import "UIBarButtonItem+Customview.h"
#import "ModelCollectionViewCell.h"
#import "DownloadManager.h"
#import "FEViewerViewController.h"
#import "Model3DViewController.h"
#import "CHFlowLayout.h"

@interface ModelsCollectionViewController () <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, DownloadManagerProgressDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) NSMutableArray *sectionChanges;
@property (nonatomic, strong) NSMutableArray *editItems;

@end

@implementation ModelsCollectionViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    CHFlowLayout *chFlowLayout = [CHFlowLayout.alloc init];
    [self.collectionView setCollectionViewLayout:chFlowLayout animated:NO];
    [self _configureBarButtonItemsForEditing:NO];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSError *error = nil;
    BOOL success = [self.fetchedResultsController performFetch:&error];
    
    if(!success) {
        NSLog(@"Error = %@", error);
    }
    [self.collectionView reloadData];
    DownloadManager.sharedInstance.progressDelegate = self;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.fetchedResultsController = nil;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    FEModel *model = [self.fetchedResultsController objectAtIndexPath:self.collectionView.indexPathsForSelectedItems.lastObject];

    if ([segue.identifier isEqualToString:@"Show FE Model"])
    {
        [(FEViewerViewController *)[(UINavigationController *)segue.destinationViewController topViewController] setFeModel:model];
    } else if ([segue.identifier isEqualToString:@"Show 3D Model"])
    {
        [(Model3DViewController *)[(UINavigationController *)segue.destinationViewController topViewController] setFeModel:model];
    }
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self _configureBarButtonItemsForEditing:editing];
    if (!editing) [self _discardEditItems];
    [self _updateVisibilityForInfobuttons];
}

#pragma mark - Save changes from other contexts
- (void)handleDidSaveNotification:(NSNotification *)notification
{
    [[NSManagedObjectContext MR_defaultContext] mergeChangesFromContextDidSaveNotification:notification];
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    FEModel *aModel = [self.fetchedResultsController objectAtIndexPath:indexPath];
    ModelCollectionViewCell *modelCell = (ModelCollectionViewCell *)cell;
    modelCell.nameLabel.text = aModel.modelName;
    modelCell.modelImageView.image = aModel.modelImage;
    modelCell.infoButton.hidden = self.isEditing;
    modelCell.checkMarkImageView.hidden = ![self.editItems containsObject:aModel];
    if (aModel.dateAdded.unsignedLongLongValue > 0) {
        modelCell.downloadProgressView.hidden = YES;
    } else {
        modelCell.downloadProgressView.hidden = NO;
        modelCell.infoButton.hidden = YES;
    }
}


- (void)uploadTapped:(UIBarButtonItem *)button
{
    NSLog(@"action tapped: %@", self.editItems);
}


- (void)deleteTapped:(UIButton *)deleteButton
{
    NSString *deleteString = nil;
    if (self.editItems.count == 1) {
        deleteString = NSLocalizedString(@"Are you sure you want to delete selected item?", nil);
    } else {
        deleteString = NSLocalizedString(@"Are you sure you want to delete selected items?", nil);
    }
    UIActionSheet *actionSheet = [UIActionSheet.alloc initWithTitle:deleteString
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Delete", nil)
                                                  otherButtonTitles: nil];
    [actionSheet showFromRect:deleteButton.frame inView:self.navigationController.navigationBar animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        return;
    }
    NSArray *deleteItems = [self.editItems copy];
    [self.editItems removeAllObjects];
    [self _toggleBarButtonStateOnChangedEditItems];
    [FEModel deleteModels:deleteItems completion:^(NSError *error) {
        if (error) NSLog(@"Error: %@", error.localizedDescription);
    }];
}


- (void)addFilesFromDropbox
{
    [self performSegueWithIdentifier:@"Show Dropbox" sender:self];
}


#pragma mark - Download Manager delegate
- (void)downloadManager:(DownloadManager *)sender loadProgress:(CGFloat)progress forModel:(FEModel *)model
{
    NSIndexPath *downloadIndex = [self.fetchedResultsController indexPathForObject:model];
    ModelCollectionViewCell *downloadCell = (ModelCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:downloadIndex];
    [downloadCell.downloadProgressView setProgress:progress animated:YES];
}


- (void)downloadManager:(DownloadManager *)sender finishedDownloadingModel:(FEModel *)model
{
    NSIndexPath *downloadIndex = [self.fetchedResultsController indexPathForObject:model];
    ModelCollectionViewCell *downloadCell = (ModelCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:downloadIndex];
    [downloadCell.downloadProgressView removeFromSuperview];
    downloadCell.downloadProgressView = nil;
}


- (void)downloadManager:(DownloadManager *)sender failedDownloadingModel:(FEModel *)model
{
    NSString *message = [model.modelName stringByAppendingFormat:@" %@", NSLocalizedString(@"could not be downloaded", nil)];
    UIAlertView *alertView = [UIAlertView.alloc initWithTitle:NSLocalizedString(@"Failed downloading", nil) message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
    [alertView show];
}



#pragma mark - Editing state
- (void)_configureBarButtonItemsForEditing:(BOOL)editing
{
    if (editing)
    {
        UIBarButtonItem *uploadButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"0108"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadTapped:)];
        UIBarButtonItem *deleteItem = [UIBarButtonItem deleteButtonWithTarget:self action:@selector(deleteTapped:)];
        uploadButton.enabled = NO;
        deleteItem.enabled = NO;
        [self.navigationItem setLeftBarButtonItems:@[uploadButton, deleteItem] animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem] animated:YES];
    }
    else
    {
        UIBarButtonItem *addFilesBarButton = [UIBarButtonItem barButtonWithImage:[UIImage imageNamed:@"dropbox_logo"] style:UIBarButtonItemStylePlain target:self action:@selector(addFilesFromDropbox)];
        [self.navigationItem setLeftBarButtonItems:@[addFilesBarButton] animated:YES];
        [self.navigationItem setRightBarButtonItems:@[self.editButtonItem] animated:YES];
    }
}


- (void)_toggleVisibleCheckmarkForCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    id anObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [(ModelCollectionViewCell *)cell checkMarkImageView].hidden = ![self.editItems containsObject:anObject];
}


- (void)_togglePresenceInEditItems:(id)anObject
{
    if (!self.editItems) self.editItems = NSMutableArray.array;
    if ([self.editItems containsObject:anObject])
    {
        [self.editItems removeObject:anObject];
    }
    else
    {
        [self.editItems addObject:anObject];
    }
}

- (void)_toggleBarButtonStateOnChangedEditItems
{
    [self.navigationItem.leftBarButtonItems[0] setEnabled:(self.editItems.count > 0)];
    [self.navigationItem.leftBarButtonItems[1] setEnabled:(self.editItems.count > 0)];
}

- (void)_discardEditItems
{
    [self.editItems removeAllObjects];
    self.editItems = nil;
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems)
    {
        ModelCollectionViewCell *cell = (ModelCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self configureCell:cell atIndexPath:indexPath];
    }
}

- (void)_updateVisibilityForInfobuttons
{
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems)
    {
        ModelCollectionViewCell *cell = (ModelCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [self configureCell:cell atIndexPath:indexPath];
    }
}



#pragma mark - UICollectionView Datasource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Model Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell) [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


#pragma mark UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FEModel *selectedModel = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];

    switch (self.isEditing)
    {
        case YES:
            [self _togglePresenceInEditItems:selectedModel];
            [self _toggleVisibleCheckmarkForCell:cell atIndexPath:indexPath];
            [self _toggleBarButtonStateOnChangedEditItems];
            break;
            
        case NO:
            [self _presentModel:selectedModel sender:cell];
            break;
    }
}


- (void)_presentModel:(FEModel *)model sender:(id)sender
{
    if (!model.isDownloaded) {
        return;
    }
    switch (model.modelType)
    {
        case ModelTypeAnsys:
        case ModelTypeNastran:
        case ModelTypeLSPrePost:
            [self performSegueWithIdentifier:@"Show FE Model" sender:sender];
            break;
            
        case ModelTypeOBJ:
        case ModelTypeDAE:
            [self performSegueWithIdentifier:@"Show 3D Model" sender:sender];
            break;
            
        default:
            break;
    }
}

#pragma mark - Fetched Results Controller
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"FEModel" inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]]];
    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateAdded" ascending:NO]]];
    
    NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                    managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                                      sectionNameKeyPath:nil
                                                                                               cacheName:nil];
    newController.delegate = self;
    self.fetchedResultsController = newController;
    
    return _fetchedResultsController;
}


#pragma mark Fetched Results Controller Delegate methods

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @[@(sectionIndex)];
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @[@(sectionIndex)];
            break;
    }
    [_sectionChanges addObject:change];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([_sectionChanges count] > 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _sectionChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[[obj lastObject] unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[[obj lastObject] unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[[obj lastObject] unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _objectChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeMove:
                            [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}

@end
