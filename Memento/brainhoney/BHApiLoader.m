//
//  MMApiLoader.m
//  Brainhoney
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "BHApiLoader.h"

@implementation BHApiLoader
@synthesize delegate;
- (BHApiLoader *)init {
    respData = [[NSMutableData alloc] initWithCapacity:1024*1024*5];
    return self;
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [respData appendData:data];    
    NSLog(@"Fetching...");
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [delegate parseData:respData];
}
@end