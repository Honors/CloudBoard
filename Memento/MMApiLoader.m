//
//  MMApiLoader.m
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMApiLoader.h"

@implementation MMApiLoader
@synthesize delegate;
@synthesize _mode;
    - (MMApiLoader *)initWithMode: (NSString *)mode; {
        _mode = mode;
        respData = [[NSMutableData alloc] initWithCapacity:1024*1024*5];
        return self;
    }
    - (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
    {
        [respData appendData:data];        
    }
    - (void)connectionDidFinishLoading:(NSURLConnection *)connection {
        if( [_mode isEqualToString:@"GET"] )
            [delegate parseData:respData];
        else
            [delegate fetchMoments: @"matt"];
    }
@end
