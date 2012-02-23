//
//  MMLoginViewController.m
//  Memento
//
//  Created by Matt Neary on 2/22/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMLoginViewController.h"
#import "MMRegisterViewController.h"
#import "MMApiWrapper.h"

@implementation MMLoginViewController
@synthesize delegate;
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if( [string isEqualToString:@"\n"] ) {
        [textField resignFirstResponder];
    }
    return YES;
}
- (void)viewDidLoad {
    username.delegate = self;
    password.delegate = self;
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];
}
- (IBAction)loginClick {
    //Save credentials
    MMApiWrapper *mmaw = [[MMApiWrapper alloc] init];
    [mmaw writeUsername:username.text andPassword:password.text];
    [delegate delegate].username = username.text;
    [delegate delegate].password = password.text;
    
    [[delegate delegate].navigationController popToViewController:[delegate delegate] animated:YES];
}
@end
