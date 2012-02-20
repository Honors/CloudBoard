//
//  MMTextEntry.m
//  Memento
//
//  Created by Matt Neary on 2/19/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMTextEntry.h"

@implementation MMTextEntry
@synthesize delegate;
- (void)resignTextView {
    [self.navigationItem setRightBarButtonItem:nil];
    [textview resignFirstResponder];
    [self exit];
}
- (void)viewDidLoad {
    textview.delegate = self;    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(resignTextView)]];
    [textview becomeFirstResponder];
}
- (void)exit {
    [delegate setTextViewContent:[textview text]];
    [delegate clearImage];
    [delegate.navigationController popViewControllerAnimated:YES];
}
@end
