//
//  ListZipContentViewController.m
//  FEViewer2
//
//  Created by Christian Hansen on 27/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ListZipContentViewController.h"
#import "NSString+_Format.h"
#import "ZipHelper.h"
#import "MBProgressHUD.h"
#import "PGDownloadManager.h"
#import "PGModel+Management.h"

@interface ListZipContentViewController () <MBProgressHUDDelegate, ZipHelperDelegate>

@property (nonatomic, strong) NSArray *zipFileContents;
@property (nonatomic, strong) NSMutableArray *selectedFiles;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) NSArray *validFormats;

@end

@implementation ListZipContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.filePathForZip.lastPathComponent;
    self.zipFileContents = [ZipHelper listFilesInZipFile:self.filePathForZip];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
}


- (NSMutableArray *)selectedFiles
{
    if (!_selectedFiles) {
        _selectedFiles = [NSMutableArray array];
    }
    return _selectedFiles;
}


#pragma mark - unzip from selection and save to separate folder
- (void)extractFiles:(NSArray *)fileInfoList
{
    for (FileInZipInfo *fileInfo in fileInfoList) {
        [self showUnzippingProgressHUDForFile:fileInfo.name];
        [ZipHelper unzipFile:fileInfo.name inZipFile:self.filePathForZip intoDirectory:TEMP_DIR delegate:self completion:^(NSError *error) {
            if (!error) {
                self.progressHUD.progress = 1.0;
                [self.progressHUD hide:YES];
                [[PGDownloadManager sharedInstance] importModelFileFromPath:[TEMP_DIR stringByAppendingPathComponent:fileInfo.name]];
            } else {
                self.progressHUD.labelText = [NSString stringWithFormat:@"%@ %@", fileInfo.name, NSLocalizedString(@"extraction failed", nil)];
            }
        }];
    }
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.zipFileContents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Zip Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    FileInZipInfo *zipInfo = [self.zipFileContents objectAtIndex:indexPath.row];
    cell.textLabel.text = [zipInfo.name fitToLength:50];
    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Unzipped Size", nil), [NSString humanReadableFileSize:[NSNumber numberWithInteger:zipInfo.length]]];
    cell.accessoryType = [self.selectedFiles containsObject:zipInfo] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    if ([PGModel modelTypeForFileName:zipInfo.name] != ModelTypeUnknown) {
        cell.userInteractionEnabled = YES;
        cell.textLabel.textColor = [UIColor darkTextColor];
    } else  {
        cell.userInteractionEnabled = NO;
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    
    return cell;
}


- (void)togglePresenceInSelectedItems:(id)fileInfo
{
    [self.selectedFiles containsObject:fileInfo] ? [self.selectedFiles removeObject:fileInfo] : [self.selectedFiles addObject:fileInfo];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FileInZipInfo *zipInfo = self.zipFileContents[indexPath.row];
    [self togglePresenceInSelectedItems:zipInfo];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    self.navigationItem.rightBarButtonItem.enabled = (self.selectedFiles.count > 0) ? YES : NO;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)tappedSave:(UIBarButtonItem *)sender 
{
    [sender setEnabled:NO];
    [self extractFiles:self.selectedFiles];
}


- (IBAction)tappedCancel:(UIBarButtonItem *)sender 
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - ZipHelperDelegate method
- (void)zipProgress:(float)progress forFile:(NSString *)fileName
{
    self.progressHUD.progress = progress;
}

- (void)showUnzippingProgressHUDForFile:(NSString *)fileName
{
    if (!self.progressHUD) {
        self.progressHUD = [[MBProgressHUD alloc] initWithView:self.tableView];
    }
    [self.tableView addSubview:self.progressHUD];
    
    self.progressHUD.mode = MBProgressHUDModeAnnularDeterminate;
    self.progressHUD.dimBackground = YES;
    
    self.progressHUD.delegate = self;
    self.progressHUD.labelText = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Unzipping", nil), fileName];
        
    [self.progressHUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
}


- (void)myProgressTask 
{
	while (self.progressHUD.progress < 1.0) {
		usleep(50000);
	}
}

@end
