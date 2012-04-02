//
//  MMSplashScreenViewController.m
//  Memento
//
//  Created by Matt Neary on 2/25/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMSplashScreenViewController.h"

@implementation MMSplashScreenViewController
@synthesize delegate;
- (void)popSelf {
    [delegate dismissModalViewControllerAnimated:NO];
}
- (void)bumpProgress {
    [load setProgress:[load progress]+.04];
}
- (void)recurseLoad {
    NSLog(@"Progress: %f", [load progress]);
    if( [load progress] >= .98 ) {
        [self popSelf];
    } else {
        [self bumpProgress];
        [self performSelector:@selector(recurseLoad) withObject:nil afterDelay:.04];
    }
}
- (void)viewDidLoad {
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];    
    [load setProgress:0];
    [self recurseLoad];
}
@end
