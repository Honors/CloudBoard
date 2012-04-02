//
//  MMApiWrapper.h
//  Memento
//
//  Created by Matt Neary on 2/22/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMasterViewController.h"
#import "ASIHTTPRequest.h"

@interface MMApiWrapper : NSObject
- (void)handleImage: (NSDictionary *)item inTable: (UITableView *)table forImage: (UIImageView *)imageview;
- (void)uploadImageWithData: (NSData *)data to: (NSString *)slug;
- (NSURLConnection *)performPostWithParams: (NSString *)params to: (NSString *)path forDelegate: (MMMasterViewController *)delegate andReadData: (BOOL)read;
- (void)writeUsername: (NSString *)username andPassword: (NSString *)password;
@end
