//
//  SelectActionTableViewController.m
//  FEViewer2
//
//  Created by Christian Hansen on 16/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGUploadViewController.h"
#import <MessageUI/MessageUI.h>
#import "PGDropboxViewController.h"
#import "ZipHelper.h"
#import "MBProgressHUD.h"
#import "NSString+_Format.h"
#import "PGDownloadManager.h"
#import "PGModel+Management.h"

@interface PGUploadViewController () <MFMailComposeViewControllerDelegate, ZipHelperDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end

@implementation PGUploadViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Upload Dropbox"]) {
        PGDropboxViewController *dropboxViewController = segue.destinationViewController;
        dropboxViewController.dropboxViewControllerType = PGDropboxViewControllerTypeUpload;
        dropboxViewController.uploadModel = self.model;
    }
}

- (IBAction)cancelTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#define DROPBOX_ROW 0
#define EMAIL_ROW 1

#pragma mark - TableViewDelegateMethods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO animated:YES];
    
    if (indexPath.row == EMAIL_ROW) {
        Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
        if (mailClass != nil) {
            // We must always check whether the current device is configured for sending emails
            if ([mailClass canSendMail]) {
                [self displayComposerSheet];
            } else {
                [self launchMailAppOnDevice];
            }
        } else {
            [self launchMailAppOnDevice];
        }
    } else if (indexPath.row == DROPBOX_ROW) {
        // Handled in storyboard segue
    }
}



#pragma mark - TableViewDatasource
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return [NSLocalizedString(@"Uncompressed size: ", nil) stringByAppendingFormat:@" %@", [NSString humanReadableFileSize:self.model.modelSize]];
    }
    return nil;
}

#pragma mark show MFMailComposerViewController
- (void)displayComposerSheet
{
    __block NSString *attachmentPath = self.model.fullModelFilePath;
    if (self.zipSwitch.isOn) {
        [self showZippingProgressHUDForFile:[attachmentPath lastPathComponent]];
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            attachmentPath = [ZipHelper zipFileAtPath:attachmentPath withDelegate:self];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showMailComposerWithAttachment:attachmentPath];
                self.progressHUD.progress = 1.0;
            });
        });
    } else {
        [self showMailComposerWithAttachment:attachmentPath];
    }
}


- (void)showMailComposerWithAttachment:(NSString *)attachmentPath
{
    MFMailComposeViewController *mfMailComposeVC = [[MFMailComposeViewController alloc] init];
    mfMailComposeVC.mailComposeDelegate = self;
    [mfMailComposeVC setSubject:self.model.modelName];
    [mfMailComposeVC addAttachmentData:[NSData dataWithContentsOfFile:attachmentPath] mimeType:@"application/polygon" fileName:[attachmentPath lastPathComponent]];
    
    NSString *link = @"<a href=\"http://www.calcul8.it/polygon-app/\">Polygon</a>\n";;
    NSString *message = NSLocalizedString(@"Sent using ", nil);
    
    [mfMailComposeVC setMessageBody:[message stringByAppendingString:link] isHTML:YES];
    mfMailComposeVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:mfMailComposeVC animated:YES completion:nil];
}


#pragma mark - ZipHelperDelegate method
- (void)zipProgress:(float)progress forFile:(NSString *)fileName
{
    self.progressHUD.progress = progress;
}


# pragma mark - MFMailComposerViewController delegate mehods
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result == MFMailComposeResultFailed) {
        NSString *errorMessage = NSLocalizedString(@"Email failed", nil);
        UIAlertView *resultAlert = [[UIAlertView alloc] initWithTitle:errorMessage
                                                              message:[error localizedDescription]
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                    otherButtonTitles:nil];
        [resultAlert show];
    } else if (result == MFMailComposeResultSent) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
        hud.mode = MBProgressHUDModeCustomView;
        hud.labelText = NSLocalizedString(@"Email sent!", nil);
        hud.removeFromSuperViewOnHide = YES;
        [hud hide:YES afterDelay:3.0];
    } else if (result == MFMailComposeResultCancelled) {
        //TODO: do nothing
    }
    if (self.zipSwitch.isOn) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *attachmentPath = [self.model.modelName stringByAppendingString:@".zip"];
        [fileManager removeItemAtPath:attachmentPath error:nil];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}


- (void)launchMailAppOnDevice
{
    UIAlertView *resultAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                          message:NSLocalizedString(@"Your device is not able to send e-mail", nil)
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];
    [resultAlert show];
}


- (void)showZippingProgressHUDForFile:(NSString *)fileName
{
    self.progressHUD = [[MBProgressHUD alloc] initWithView:self.tableView];
    [self.tableView addSubview:self.progressHUD];
    
    // Set determinate mode
    self.progressHUD.mode = MBProgressHUDModeAnnularDeterminate;
    self.progressHUD.dimBackground = YES;
    
    self.progressHUD.delegate = self;
    self.progressHUD.labelText = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Zipping", nil), [fileName fitToLength:21]];
    
    // myProgressTask uses the HUD instance to update progress
    [self.progressHUD showWhileExecuting:@selector(myProgressTask) onTarget:self withObject:nil animated:YES];
}


- (void)myProgressTask
{
	while (self.progressHUD.progress < 1.0)
    {
		usleep(50000);
	}
}

@end
