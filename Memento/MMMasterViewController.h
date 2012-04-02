//
//  MMMasterViewController.h
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMMasterViewController : UITableViewController
    @property (strong, nonatomic) NSMutableArray *_items;
    @property (strong, nonatomic) NSString *username;
    @property (strong, nonatomic) NSString *password;
    - (void)parseData: (NSData *)data;
    - (void)displayInsert;
    - (void)fetchMoments: (NSString *)username;
    - (void)saveMomentAtLocation: (NSString *)link withTitle: (NSString *)title andContent: (NSString *)content;
- (void)checkLogin;
- (NSString *)uploadImageWithData: (NSData *)data;
@end
