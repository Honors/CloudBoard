//
//  MMRegisterViewController.m
//  Memento
//
//  Created by Matt Neary on 2/22/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMLoginViewController.h"
#import "MMSplashScreenViewController.h"
#import "MMApiWrapper.h"

@implementation MMRegisterViewController
@synthesize delegate;
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if( [string isEqualToString:@"\n"] ) {
        if( [username isFirstResponder] ) {
            [password becomeFirstResponder];
        } else if( [password isFirstResponder] ) {
            [email becomeFirstResponder];
        } else {
            [self registerClick];
        }
    }
    return YES;
}
- (void)viewDidLoad {
    username.delegate = self;
    password.delegate = self;
    email.delegate = self;
    
    [username becomeFirstResponder];
    
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];
    [self.navigationItem setHidesBackButton:YES];
    
    MMSplashScreenViewController *mmssvc = [[delegate storyboard] instantiateViewControllerWithIdentifier:@"splashScreen"];
    mmssvc.delegate = self;
    
    [self presentModalViewController:mmssvc animated:NO];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Already User?" style:UIBarButtonItemStylePlain target:self action:@selector(loginClick)]];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Register" style:UIBarButtonItemStyleDone target:self action:@selector(registerClick)]];
}
- (IBAction)loginClick {
    //Move to login view
    MMLoginViewController *mmlvc = [[delegate storyboard] instantiateViewControllerWithIdentifier:@"loginView"];
    mmlvc.delegate = self;
    [delegate.navigationController pushViewController:mmlvc animated:YES];
}
- (IBAction)registerClick { 
    [errorLabel setHidden:YES];
    [mementoInfo setHidden:YES];
    
    //Check data entry
    
    //Check name availability
    NSString *isUser = [NSString stringWithContentsOfURL:[NSURL URLWithString:[@"http://mneary.info:3001/api/load/is_user/" stringByAppendingString:username.text]]];
    NSLog(@"is user: %@", isUser);
    BOOL userExists = ([isUser rangeOfString:@"false"].location == NSNotFound);
    if( userExists || [username.text isEqualToString:@""] ) {
        //throw error
        [errorLabel setText:[username.text isEqualToString:@""]?@"A username is required":@"Sorry, that username is taken"];
        [errorLabel setHidden:NO];
        
        return;
    }
    
    //Check email availability
    NSString *isUserEmail = [NSString stringWithContentsOfURL:[NSURL URLWithString:[@"http://mneary.info:3001/api/load/is_user_email/" stringByAppendingString:email.text]]];
    BOOL userEmailExists = ([isUserEmail rangeOfString:@"false"].location == NSNotFound);
    if( userEmailExists || [email.text isEqualToString:@""] ) {
        //throw error
        [errorLabel setText:[email.text isEqualToString:@""]?@"An email address is required":@"Sorry, that email is already in use"];
        [errorLabel setHidden:NO];
        
        return;
    }
    
    //Communicate with API
    MMApiWrapper *mmaw = [[MMApiWrapper alloc] init];
    [mmaw performPostWithParams:[NSString stringWithFormat:@"password=%@&email=%@", password.text, email.text] to:[NSString stringWithFormat:@"http://mneary.info:3001/api/new_user/%@", username.text] forDelegate:nil andReadData:NO];
    
    //Save credentials    
    [mmaw writeUsername:username.text andPassword:password.text];
    delegate.username = username.text;
    delegate.password = password.text;
    
    [delegate.navigationController popToViewController:delegate animated:YES];        
}
@end
