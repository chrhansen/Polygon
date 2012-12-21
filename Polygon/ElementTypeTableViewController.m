//
//  ElementTypeTableViewController.m
//  FEViewer2
//
//  Created by Christian Hansen on 23/05/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ElementTypeTableViewController.h"

@implementation ElementTypeTableViewController

@synthesize solidElements = _solidElements;
@synthesize shellElements = _shellElements;
@synthesize beamElements = _beamElements;
@synthesize nodes = _nodes;
@synthesize edges = _edges;

@synthesize delegate = _delegate;

- (void)viewDidUnload
{
    [self setEdges:nil];
    [super viewDidUnload];
    self.solidElements = nil;
    self.shellElements = nil;
    self.beamElements = nil;
    self.nodes = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



- (IBAction)solidAction:(id)sender 
{
    [self.delegate solidTypeWasChanged:sender];
}

- (IBAction)shellAction:(id)sender 
{
    [self.delegate shellTypeWasChanged:sender];
}

- (IBAction)beamAction:(id)sender 
{
    [self.delegate beamTypeWasChanged:sender];
}

- (IBAction)edgeAction:(id)sender 
{
    [self.delegate edgesWasChanged:sender];
}

- (IBAction)nodeAction:(id)sender 
{
    [self.delegate nodeWasChanged:sender];
}
@end
