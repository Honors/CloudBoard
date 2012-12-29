//
//  JSGitSetup.m
//  JS Builder
//
//  Created by Matt Neary on 12/31/11.
//  Copyright (c) 2011 OmniVerse. All rights reserved.
//

#import "JSGitSetup.h"
#import "SBJson.h"
#import "JSViewController.h"

NSArray *gists;

@implementation JSGitSetup
@synthesize delegate;
@synthesize mode;

- (IBAction)dismissModal {
    [delegate dismissModalViewControllerAnimated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *newURL = webView.request.URL.absoluteString;
    NSLog(@"New Location: %@", newURL);
    
    
    NSRange textRange =[newURL rangeOfString:@"json.php"];
    
    if(textRange.location != NSNotFound) {        
        //Does contain the substring
        NSString *json = [web stringByEvaluatingJavaScriptFromString:@"document.getElementById('json').innerHTML"];
        SBJsonParser *parse = [[SBJsonParser alloc] init];
        gists = [parse objectWithString:json];
        NSLog(@"JSON present: %@", gists);
        
        NSString *username = [web stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('button')[0].innerHTML"];
        NSLog(@"USERNAME: %@", username);
        ((JSViewController *)delegate).username = username;
        /*
        NSString *url = @"about:blank";
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        [web loadRequest:req];*/
    }     
    
    textRange =[newURL rangeOfString:@"view.php"];
    
    if(textRange.location != NSNotFound) {        
        //Selected specific gist
        NSArray *parts = [newURL componentsSeparatedByString:@"?id="];
        NSString *idS = [parts objectAtIndex:1];
        NSLog(@"ID: %@", idS);        
        
        //Exit
        ((JSViewController *)delegate).idString = idS;
        
        if( [self.mode isEqualToString:@"push"] ) {
            //Push mode
            [((JSViewController *)delegate) pushCode];
        } else {                        
            NSString *resp = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('links').innerHTML"];
            NSLog(@"Links: %@", resp);
            
            NSArray *parts = [resp componentsSeparatedByString:@"|"];
            //Download HTML
            NSString *part1 = [NSString stringWithContentsOfURL:[NSURL URLWithString:[parts objectAtIndex:0]]];        
            //Download JS
            NSString *part2 = [NSString stringWithContentsOfURL:[NSURL URLWithString:[parts objectAtIndex:1]]];
            
            [((JSViewController *)delegate) pullCodeWithHTML:part1 andJS:part2];
            
            NSLog(@"PartsL %@; %@", part1, part2);
        }
        
        [delegate dismissModalViewControllerAnimated:YES];
    }
    
    textRange =[newURL rangeOfString:@"?code="];
    
    if(textRange.location != NSNotFound) {        
        //Selected specific gist
        NSArray *parts = [newURL componentsSeparatedByString:@"?code="];
        NSString *code = [parts objectAtIndex:1];
        NSLog(@"CODE: %@", code);        
        
        ((JSViewController *)delegate).secretCode = code;
    }
}

- (void)viewDidLoad {
    [web setDelegate:self];
    
    NSString *url = @"http://omniverseapps.com/code";
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [web loadRequest:req];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
