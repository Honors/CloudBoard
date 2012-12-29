//
//  MMDetailViewController.m
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMDetailViewController.h"

@interface MMDetailViewController ()
- (void)configureView;
@end

@implementation MMDetailViewController

@synthesize detailItem = _detailItem;
@synthesize detailText;
@synthesize detailImg;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return [sv.subviews objectAtIndex:0];
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem && self.detailText) {
        self.detailText.text = [self.detailItem valueForKey:@"content"];
    } else if(self.detailItem && self.detailImg) {
        NSArray *sysPaths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
        NSString *docDirectory = [sysPaths objectAtIndex:0];
        
        //File path is slug
        NSString *slug = [self.detailItem valueForKey:@"link"];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.png", docDirectory, slug];    
        [self.detailImg setImage:[UIImage imageWithContentsOfFile:filePath]];
    }
    
    if( self.detailItem ) {
        self.navigationItem.title = [self.detailItem valueForKey:@"title"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
