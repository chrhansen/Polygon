//
//  ROIDetalTableViewController.m
//  Polygon
//
//  Created by Christian Hansen on 28/06/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGViewDetailTableViewController.h"
#import "PGView+Management.h"

@implementation PGViewDetailTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _configureViews];
    
    [self configureBarButtonsForState:self.isEditing];
    if (self.isEditing) [self.titleTextView becomeFirstResponder];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)_configureViews
{
    if (self.savedView) {
        self.title = self.savedView.title;
        self.titleTextView.text = self.savedView.title;
        self.screenshotImageView.image = self.savedView.image;
    } 
}

- (void)configureBarButtonsForState:(BOOL)isEditing
{
    if (isEditing) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelTapped:)];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(_saveTapped:)];
    } else {
        [self.navigationItem setHidesBackButton:!isEditing animated:YES];
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self configureBarButtonsForState:editing];
    self.titleTextView.editable = editing;
    if (editing) {
        [self.titleTextView becomeFirstResponder];
    } else {
        [self.titleTextView resignFirstResponder];
    }
}


- (void)_cancelTapped:(id)sender
{
    if (!self.isEditingExistingViewViewController) {
        [PGView deleteView:self.savedView completion:nil];
//        [self.savedView deleteInContext:[NSManagedObjectContext defaultContext]];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)_saveTapped:(id)sender
{
    self.savedView.dateModified = [NSDate date];
    self.savedView.title = self.titleTextView.text;
    [self.delegate viewDetailTableViewController:self didSaveView:self.savedView];
}


#pragma mark - Text View Delegate
- (void)textViewDidChange:(UITextView *)textView
{
    self.title = textView.text;
    self.savedView.title = textView.text;
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
