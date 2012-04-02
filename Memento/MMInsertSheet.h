//
//  MMInsertSheet.h
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMasterViewController.h"

@interface MMInsertSheet : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    IBOutlet UIImageView *img;
    NSString *imagePushed;    
    IBOutlet UITextView *textview;
    IBOutlet UITextField *titleText;
}
    @property (strong, nonatomic) MMMasterViewController *delegate;
    - (IBAction)dismissInsertSheet:(id)sender;
    - (IBAction)saveInsertSheet:(id)sender;    
    - (void)pushImage: (NSData *)data withSmall: (UIImage *)small;
    - (IBAction)pickImage;
    - (IBAction)textEntry;
    - (void)setTextViewContent: (NSString *)text;
    - (void)clearImage;
@end
