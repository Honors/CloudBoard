//
//  MMRegisterViewController.m
//  Memento
//
//  Created by Matt Neary on 2/22/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMLoginViewController.h"
#import "MMApiWrapper.h"

@implementation MMRegisterViewController
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
    email.delegate = self;
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];
}
- (IBAction)loginClick {
    //Move to login view
    MMLoginViewController *mmlvc = [[delegate storyboard] instantiateViewControllerWithIdentifier:@"loginView"];
    mmlvc.delegate = self;
    [delegate.navigationController pushViewController:mmlvc animated:YES];
}
- (IBAction)registerClick {
    //Communicate with API
    
    //Save credentials
    MMApiWrapper *mmaw = [[MMApiWrapper alloc] init];
    [mmaw writeUsername:username.text andPassword:password.text];
    delegate.username = username.text;
    delegate.password = password.text;
    
    [delegate.navigationController popToViewController:delegate animated:YES];        
}
@end
