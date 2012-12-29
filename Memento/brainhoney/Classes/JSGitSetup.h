//
//  JSGitSetup.h
//  JS Builder
//
//  Created by Matt Neary on 12/31/11.
//  Copyright (c) 2011 OmniVerse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JSGitSetup : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView *web;
    IBOutlet UITextView *output;
}

- (IBAction)dismissModal;

@property(nonatomic, assign) UIViewController *delegate;
@property(nonatomic, assign) NSString *mode;

@end
