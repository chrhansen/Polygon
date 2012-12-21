//
//  ROIDetalTableViewController.m
//  Polygon
//
//  Created by Christian Hansen on 28/06/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ROIDetailTableViewController.h"

@interface ROIDetailTableViewController ()

@end

@implementation ROIDetailTableViewController
@synthesize roi = _roi;
@synthesize titleTextView = _titleTextView;
@synthesize descriptionTextView = _textView;
@synthesize delegate = _delegate;
@synthesize showKeyboard = _showKeyboard;
@synthesize addROINavigationBar = _addROINavigationBar;

#define TITLE_TEXTVIEW_TAG 1
#define DESCRIPTION_TEXTVIEW_TAG 2

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = self.roi.title;
    self.titleTextView.text = self.roi.title;
    self.descriptionTextView.text = self.roi.description;
    if (self.showKeyboard)
    {
        [self.titleTextView becomeFirstResponder];
    }
    else
    {
        self.titleTextView.editable = NO;
        self.descriptionTextView.editable = NO;
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
}


- (void)viewDidUnload
{
    [self setDescriptionTextView:nil];
    [self setTitleTextView:nil];
    [self setAddROINavigationBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.navigationItem setHidesBackButton:editing animated:YES];
    self.titleTextView.editable = editing;
    self.descriptionTextView.editable = editing;
    if (editing)
    {
        [self.descriptionTextView becomeFirstResponder];
    }
    else 
    {
        [self.titleTextView resignFirstResponder];
        [self.descriptionTextView resignFirstResponder];
        [self.delegate didEditROI:self.roi sender:self];
    }
}

- (IBAction)saveTapped:(id)sender 
{
    self.roi.description = [(UITextView *)[self.view viewWithTag:DESCRIPTION_TEXTVIEW_TAG] text];
    self.roi.title = [(UITextView *)[self.view viewWithTag:TITLE_TEXTVIEW_TAG] text];
    [self.delegate didSaveROI:self.roi sender:self];
}


- (IBAction)cancelTapped:(id)sender 
{
    [(UIViewController *)self.delegate dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - Text View Delegate
- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.tag == TITLE_TEXTVIEW_TAG) 
    {
        self.title = textView.text;
        self.roi.title = textView.text;
        if (self.addROINavigationBar) 
        {
            self.addROINavigationBar.topItem.title = textView.text;
        }
    }
    else if (textView.tag == DESCRIPTION_TEXTVIEW_TAG)
    {
        self.roi.description = textView.text;
    }
}


#pragma mark Table view delegate methods
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleNone; 
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end
