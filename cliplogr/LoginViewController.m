//
//  LoginViewController.m
//  cliplogr
//
//  Created by Matt on 7/21/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import "LoginViewController.h"
#import "RootViewController.h"


@implementation LoginViewController

- (IBAction)loginSubmitButton {
    NSLog(@"LVC.m was reached");
    [self dismissModalViewControllerAnimated:YES];
    //[[RootViewController new] loginSubmitButton];
}

@end
