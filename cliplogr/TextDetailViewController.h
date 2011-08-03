//
//  TextDetailViewController.h
//  cliplogr
//
//  Created by Matt on 7/27/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TextDetailViewController : UIViewController {
    IBOutlet UITextView *textContents;
    IBOutlet UITextField *textLink;
}

- (void)initWithLink: (NSString*)link andContents: (NSString*)content;
- (IBAction)editCloseButton;

@end
