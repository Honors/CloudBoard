//
//  TextDetailViewController.m
//  cliplogr
//
//  Created by Matt on 7/27/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import "TextDetailViewController.h"


@implementation TextDetailViewController
    
    - (void)viewDidLoad { 
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood.jpeg"]];
    }

    - (void)initWithLink: (NSString*)link andContents: (NSString*)content {
        [textContents setText:content];
        [textLink setText:link];
    }
    - (IBAction)editCloseButton {        
        [self dismissModalViewControllerAnimated:YES];
    }
    - (IBAction)editSaveButton {
        
    }

@end
