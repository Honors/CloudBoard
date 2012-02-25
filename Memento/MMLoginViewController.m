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
- (void)parseData: (NSData *)data {
    [errorLabel setHidden:YES];
    
    NSString *resp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    BOOL userExists = ([resp rangeOfString:@"false"].location == NSNotFound);
    NSLog(@"%@ -> %u", resp, userExists);
    if( !userExists ) {        
        [errorLabel setText:@"Username or Password Incorrect"];
        [errorLabel setHidden:NO];
        
        return;
    }
    
    //Handle Login
    MMApiWrapper *mmaw = [[MMApiWrapper alloc] init];
    [mmaw writeUsername:username.text andPassword:password.text];
    [delegate delegate].username = username.text;
    [delegate delegate].password = password.text;
    
    [[delegate delegate] fetchMoments:username.text];
    [[delegate delegate].navigationController popToViewController:[delegate delegate] animated:YES];
}
- (IBAction)loginClick {
    //Save credentials
    MMApiWrapper *mmaw = [[MMApiWrapper alloc] init];
    [mmaw performPostWithParams:[NSString stringWithFormat:@"username=%@&password=%@", username.text, password.text] to:@"http://mneary.info:3001/api/load/is_user_key_pair/" forDelegate:self andReadData:YES];
}
@end
