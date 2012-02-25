//
//  MMLoginViewController.h
//  Memento
//
//  Created by Matt Neary on 2/22/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMRegisterViewController.h"

@interface MMLoginViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UITextField *username;
    IBOutlet UITextField *password;
    IBOutlet UILabel *errorLabel;
}
    - (IBAction)loginClick;
    @property (strong, nonatomic) MMRegisterViewController *delegate;
@end
