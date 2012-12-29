//
//  MMMasterViewController.h
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefreshTableViewController.h"

@interface MMMasterViewController : PullRefreshTableViewController <UIDocumentInteractionControllerDelegate> {
    UIViewController *qlvc;
}

@property (strong, nonatomic) NSMutableArray *_items;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property UIDocumentInteractionController *UIDIC;

- (void)parseData: (NSData *)data;
- (void)displayInsert;
- (void)fetchMoments: (NSString *)username;
- (void)saveMomentAtLocation: (NSString *)link withTitle: (NSString *)title andContent: (NSString *)content withExtension: (NSString *)ext;
- (void)checkLogin;
- (NSString *)uploadImageWithData: (NSData *)data ofType: (NSString *)type;
@end
