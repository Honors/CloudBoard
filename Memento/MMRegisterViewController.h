//
//  MMRegisterViewController.h
//  Memento
//
//  Created by Matt Neary on 2/22/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMasterViewController.h"

@interface MMRegisterViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UITextField *username;
    IBOutlet UITextField *password;
    IBOutlet UITextField *email;
    IBOutlet UILabel *errorLabel;
    IBOutlet UIView *mementoInfo;
}
@property (strong, nonatomic) MMMasterViewController *delegate;
- (IBAction)registerClick;
- (IBAction)loginClick;
@end
