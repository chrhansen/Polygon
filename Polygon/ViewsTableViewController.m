//
//  ViewsTableViewController.m
//  Polygon
//
//  Created by Christian Hansen on 6/27/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ViewsTableViewController.h"
#import "NSString+_Format.h"
#import "UIImage+Resize.h"
#import "PGModel+Management.h"
#import "PGView+Management.h"

@interface ViewsTableViewController ()

@property (nonatomic, strong) NSIndexPath *indexPathForSelectedAccessoryView;

@end

@implementation ViewsTableViewController

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.rois) 
    {
        self.roisFilePath = [[self.delegate directoryForROIList:self] stringByAppendingPathComponent:PolygonROIs];
        [self readStoredROIsFromFile:self.roisFilePath];
    }
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Add ROI"]) 
    {
        ROIDetailTableViewController *roiDetailTableViewController = segue.destinationViewController;
        roiDetailTableViewController.delegate = self;
        roiDetailTableViewController.roi = [self.delegate currentROI:self];
        roiDetailTableViewController.showKeyboard = YES;
    }
    else if ([segue.identifier isEqualToString:@"Show ROI"]) 
    {
        ROIDetailTableViewController *roiDetailTableViewController = segue.destinationViewController;
        roiDetailTableViewController.delegate = self;
        NSDictionary *roiAsDictionary = [self.rois objectAtIndex:self.indexPathForSelectedAccessoryView.row];
        roiDetailTableViewController.roi = [ROI3D createFromDictionary:roiAsDictionary];
    }
}


- (void)readStoredROIsFromFile:(NSString *)roisFile
{
    self.rois = [NSMutableArray arrayWithContentsOfFile:roisFile];
    if (!self.rois)
    {
        self.rois = [NSMutableArray array];
    }
}


- (void)storeROIs:(NSMutableArray *)rois toFile:(NSString *)filePath
{
    [rois writeToFile:filePath atomically:NO];
}


- (void)setRois:(NSMutableArray *)rois
{
    if (_rois != rois) 
    {
        _rois = rois;
        [self.tableView reloadData];
    }
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.addButtonItem setEnabled:!editing];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rois.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ROI Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
    UILabel *descriptionLabel = (UILabel *)[cell viewWithTag:2];
    UIImageView *snapshotImageView = (UIImageView *)[cell viewWithTag:3];
    snapshotImageView.clipsToBounds = YES;
    
    titleLabel.text = [[self.rois objectAtIndex:indexPath.row] objectForKey:@"title"];
    descriptionLabel.text = [[self.rois objectAtIndex:indexPath.row] objectForKey:@"description"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fileName = [[self.rois objectAtIndex:indexPath.row] objectForKey:@"snapshotFileName"];
        NSString *imagePath = [[[self currentFolder] stringByAppendingPathComponent:fileName] stringByAppendingString:@".png"];
        UIImage *snapshot = [UIImage imageWithData:[NSData dataWithContentsOfFile:imagePath]];
        dispatch_async(dispatch_get_main_queue(), ^{
            snapshotImageView.image = snapshot;
        });
    });    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ROI3D *deletedROI =  [ROI3D createFromDictionary:[self.rois objectAtIndex:indexPath.row]];
        [self deleteSnapshotWithFileName:[deletedROI.snapshotFileName stringByAppendingString:@".png"]];
        [self.rois removeObjectAtIndex:indexPath.row];
        [self storeROIs:_rois toFile:_roisFilePath];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    id object1 = [self.rois objectAtIndex:fromIndexPath.row];
    id object2 = [self.rois objectAtIndex:toIndexPath.row];
    [self.rois replaceObjectAtIndex:toIndexPath.row withObject:object1];
    [self.rois replaceObjectAtIndex:fromIndexPath.row withObject:object2];
    [self storeROIs:_rois toFile:_roisFilePath];
}



- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (NSString *)currentFolder
{
    return [self.roisFilePath stringByDeletingLastPathComponent];
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.indexPathForSelectedAccessoryView = indexPath;
    [self performSegueWithIdentifier:@"Show ROI" sender:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *aRoi = [self.rois objectAtIndex:indexPath.row];
    ROI3D *theROI = [ROI3D createFromDictionary:aRoi];
    [self.delegate didSelectROI:theROI];
}


- (NSString *)objectCountAsString
{
    if (self.rois.count < 9) 
    {
        return [NSString stringWithFormat:@"0%i", self.rois.count+1];
    }
    return [NSString stringWithFormat:@"%i", self.rois.count+1];
}


- (void)saveROISnapshot:(UIImage *)snapshot toFileAtPath:(NSString *)filePath
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Write image to PNG
        UIImage *thumbNail = [snapshot thumbnailImage:102.0 transparentBorder:0 cornerRadius:5 interpolationQuality:0];
        [UIImagePNGRepresentation(thumbNail) writeToFile:[filePath stringByAppendingString:@".png"] atomically:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadCellsWithNoImage];
        });
    });   
     
}


- (void)reloadCellsWithNoImage
{
    for (UITableViewCell *aCell in self.tableView.visibleCells) 
    {
        UIImageView *imageView = (UIImageView *)[aCell viewWithTag:3];
        if (imageView.image == nil) {
           // NSLog(@"a cell had no image");
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[self.tableView indexPathForCell:aCell]] 
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)deleteSnapshotWithFileName:(NSString *)fileName
{
    [[NSFileManager defaultManager] removeItemAtPath:[[self currentFolder] stringByAppendingPathComponent:fileName] error:nil];
}

#pragma mark - ROI Detail Table View Controller delegate methods
- (void)didSaveROI:(ROI3D *)aROI sender:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];

    aROI.snapshotFileName = [NSString stringWithFormat:@"%@_%@",[self objectCountAsString], aROI.title];
    [self saveROISnapshot:[self.delegate currentSnapshot:self] 
             toFileAtPath:[[self.roisFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:aROI.snapshotFileName]];
    [self.rois addObject:[ROI3D dictionaryRepresenation:aROI]];
    [self storeROIs:_rois toFile:_roisFilePath];
    [self.tableView reloadData];
}

- (void)didEditROI:(ROI3D *)updatedROI sender:(id)sender
{
    NSDictionary *updatedROIDictionary = [ROI3D dictionaryRepresenation:updatedROI];
    [self.rois replaceObjectAtIndex:self.tableView.indexPathForSelectedRow.row withObject:updatedROIDictionary];
    [self storeROIs:_rois toFile:_roisFilePath];
    [self.tableView reloadData];
}

- (IBAction)addROI:(UIBarButtonItem *)sender
{
    PGView *newView = [PGView createEntity];
    
    NSLog(@"add roi");
}
@end
