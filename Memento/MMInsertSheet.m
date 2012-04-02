//
//  MMInsertSheet.m
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMInsertSheet.h"
#import "MMMasterViewController.h"
#import "MMTextEntry.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation MMInsertSheet   
@synthesize delegate;
    - (void)viewDidLoad {
        [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];        
        imagePushed = @"";
        [img setImage:[UIImage imageNamed:@"dragNdrop.png"]];
        titleText.delegate = self;                    
    }
    - (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
        if( [string isEqualToString:@"\n"] ) {
            [titleText resignFirstResponder];
            return NO;
        }
        return YES;
    }
    - (void)setTextViewContent: (NSString *)text {
        [textview setText:text];
    }
    - (void)clearImage {
        [img setImage:nil];
    }
    - (IBAction)getClipboard {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        
        [self clearImage];
        if( pasteboard.string ) {
            NSString *string = pasteboard.string;
            [textview setText:string];
        } else if( pasteboard.image ) {
            UIImage *image = [pasteboard.images objectAtIndex:0];
            [img setImage:image];
        } else if( pasteboard.URL ) {
            NSURL *url = [NSString stringWithFormat:@"%@",pasteboard.URL];
            [textview setText:url];
        } else {
            return;
        }
    }
    - (IBAction)pickImage {
        UIImagePickerController *uiipc = [[UIImagePickerController alloc] init];
        uiipc.delegate = self;
        uiipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentModalViewController:uiipc animated:YES];
    }
    - (IBAction)dismissInsertSheet:(id)sender {
        //Exit
        [delegate.navigationController popViewControllerAnimated:YES];
    }
    - (IBAction)textEntry {
        //Display text entry
        MMTextEntry *mmte = [[delegate storyboard] instantiateViewControllerWithIdentifier:@"textEntry"];
        mmte.delegate = self;
        //[self presentModalViewController:mmte animated:YES];
        [self.navigationController pushViewController:mmte animated:YES];
    }
    - (void)pushImage: (NSData *)data {
        //Upload image before data is entered
        [img setImage:[UIImage imageWithData:data]];
        imagePushed = [delegate uploadImageWithData:data];
    }
    - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
        NSURL *referenceURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
            // code to handle the asset here
            NSLog(@"Success %@", referenceURL);
            ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
            [assetLibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
                
                ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
                {
                    ALAssetRepresentation *rep = [myasset defaultRepresentation];

                    uint8_t* buffer = malloc([rep size]);
                    NSError* error = NULL;
                    NSUInteger bytes = [rep getBytes:buffer fromOffset:0 length:[rep size] error:&error];
                    
                    NSData *defaultRepresentationData;
                    if (bytes == [rep size]) {
                        //NSData will be used in uploading
                        defaultRepresentationData = [NSData dataWithBytes:buffer length:bytes];
                        [self pushImage:defaultRepresentationData];
                    } else {
                        //handle error in data writing
                    }

                };                                
                ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
                {
                    //handle error in data reading
                };
                
                ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
                
                //Once url is checked, open asset
                [assetslibrary assetForURL:referenceURL resultBlock:resultblock failureBlock:failureblock];
                
            } failureBlock:^(NSError *err) {
                NSLog(@"Error: %@",[err localizedDescription]);
            }];
        } failureBlock:^(NSError *err){
            //handle error
        }];
        [self dismissModalViewControllerAnimated:YES];
    }
    - (IBAction)saveInsertSheet:(id)sender {                
        //Save item
        //This is not the same controller so it cant update the table 
        [delegate saveMomentAtLocation:imagePushed withTitle:titleText.text andContent:textview.text];
        
        //Exit
        [delegate.navigationController popViewControllerAnimated:YES];
    }
@end
