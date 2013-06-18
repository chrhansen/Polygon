//
//  ViewsTableViewController.m
//  Polygon
//
//  Created by Christian Hansen on 6/27/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGViewsTableViewController.h"
#import "NSString+_Format.h"
#import "UIImage+Resize.h"
#import "PGModel+Management.h"
#import "PGView+Management.h"

@interface PGViewsTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSIndexPath *indexPathForSelectedAccessoryView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableDictionary *images;
@property (nonatomic, strong) PGView *currentView;

@end

@implementation PGViewsTableViewController
- (void)awakeFromNib
{
    [super awakeFromNib];
    self.images = [NSMutableDictionary new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (!IS_IPAD) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _getCurrentView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Add View"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        PGViewDetailTableViewController *viewDetailTableViewController = (PGViewDetailTableViewController *)navigationController.topViewController;
        viewDetailTableViewController.delegate = self;
        viewDetailTableViewController.editing = YES;
        viewDetailTableViewController.savedView = self.currentView;
        viewDetailTableViewController.isEditingExistingViewViewController = NO;
    } else if ([segue.identifier isEqualToString:@"Show View"]) {
        PGViewDetailTableViewController *viewDetailTableViewController = segue.destinationViewController;
        viewDetailTableViewController.savedView = [self.fetchedResultsController objectAtIndexPath:self.indexPathForSelectedAccessoryView];
        viewDetailTableViewController.delegate = self;
    }
}


- (IBAction)doneTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)_getCurrentView
{
    if (!self.currentView) {
        if ([self.delegate respondsToSelector:@selector(viewsTableViewController:currentViewForModel:)]) {
            self.currentView = [self.delegate viewsTableViewController:self currentViewForModel:self.model];
            NSError *permanentIDError;
            [self.currentView.managedObjectContext obtainPermanentIDsForObjects:@[self.currentView] error:&permanentIDError];
            if (permanentIDError) NSLog(@"Error: Couldn't obtain permanent ID for view: %@", self.currentView);
        } else if ([self.delegate respondsToSelector:@selector(viewsTableViewController:currentViewForModel:completion:)]) {
            [self.delegate viewsTableViewController:self currentViewForModel:self.model completion:^(PGView *currentView) {
                self.currentView = currentView;
                NSError *permanentIDError;
                [self.currentView.managedObjectContext obtainPermanentIDsForObjects:@[self.currentView] error:&permanentIDError];
                if (permanentIDError) NSLog(@"Error: Couldn't obtain permanent ID for view: %@", self.currentView);
            }];
        }
    }
}


#pragma mark - PGViewDetailTableViewController delegate
- (void)viewDetailTableViewController:(PGViewDetailTableViewController *)viewDetailTableViewController didSaveView:(PGView *)savedView
{
    savedView.viewOf = self.model;
    [savedView.managedObjectContext save:NULL];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    PGView *savedView = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
    UIImageView *snapshotImageView = (UIImageView *)[cell viewWithTag:3];
    
    titleLabel.text = savedView.title;
    snapshotImageView.image = savedView.image;
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return sectionInfo.numberOfObjects;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ROI Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell) {
        [self configureCell:cell atIndexPath:indexPath];
    } else
    {
        NSLog(@"cell for indexpath %@ is nil", indexPath);
    }
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate viewsTableViewController:self didSelectView:[self.fetchedResultsController objectAtIndexPath:indexPath]];
}




#pragma mark - Fetched Results Controller
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"viewOf == %@", self.model];
    NSFetchedResultsController *newController = [PGView fetchAllSortedBy:@"dateModified" ascending:NO withPredicate:predicate groupBy:nil delegate:self];
    self.fetchedResultsController = newController;
    return _fetchedResultsController;
}


#pragma mark Fetched Results Controller Delegate methods
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PGView *savedView = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [PGView deleteView:savedView completion:nil];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.indexPathForSelectedAccessoryView = indexPath;
    [self performSegueWithIdentifier:@"Show View" sender:self];
}

@end
