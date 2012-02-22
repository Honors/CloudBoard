//
//  MMAppDelegate.m
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMAppDelegate.h"
#import "MMApiLoader.h"
#import "SBJson.h"

@implementation MMAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Check for login
    NSArray *sysPaths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *docDirectory = [sysPaths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.plist", docDirectory, @"user_credits"];    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if( fileExists ) {
        NSLog(@"Reading credits from disk");
    } else {
        NSLog(@"Prompting user for credentials");
    }
        
    
    // Override point for customization after application launch.    
    return YES;
}

@end
