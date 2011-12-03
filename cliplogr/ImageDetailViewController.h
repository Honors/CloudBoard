//
//  TextDetailViewController.h
//  cliplogr
//
//  Created by Matt on 7/27/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ImageDetailViewController : UIViewController {
    IBOutlet UIImageView *imageContents;
    IBOutlet UITextField *imageLink;
    IBOutlet UIScrollView *imageScroll;
}

- (void)initWithLink: (NSString*)link andContents: (NSString*)content;
- (IBAction)editCloseButton;

@end
