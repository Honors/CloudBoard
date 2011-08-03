//
//  FileUploadController.m
//  cliplogr
//
//  Created by Matt on 7/30/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import "FileUploadController.h"


@implementation FileUploadController

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
 	NSLog(@"Response Recieved");
	//NSLog(@"Response Code: %d",[response sta]);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"Data Recieved");
	NSString *content = [NSString stringWithUTF8String:[data bytes]];
    NSLog(@"DATA: %@",content);
}

@end
