//
//  LoginViewController.h
//  cliplogr
//
//  Created by Matt on 7/21/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LoginViewController : UIViewController <UITextViewDelegate> {
    IBOutlet UITextField *username;
    IBOutlet UITextField *email;
    IBOutlet UITextField *password; 
    IBOutlet UILabel *alert; 
    IBOutlet UILabel *linkDisplay;
    
    IBOutlet UIButton *nextButton;
    IBOutlet UIButton *finButton;
}

- (IBAction)SubmitButton;
- (IBAction)SkipButton;
- (IBAction)LoginButton;
- (IBAction)finishButton;
- (IBAction)nextButton;
- (IBAction)exitTyping;

- (void)saveLoginCreds: (NSString *)user : (NSString *)passwordNew;

@end
