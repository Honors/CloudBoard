//
//  LoginViewController.m
//  cliplogr
//
//  Created by Matt on 7/21/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import "LoginViewController.h"
#import "RootViewController.h"
#import "cliplogrAppDelegate.h"


@implementation LoginViewController

- (IBAction)exitTyping {
    if( username )
        [username resignFirstResponder];
    if( email)
        [email resignFirstResponder];
    if( password )
        [password resignFirstResponder];
}   

-(NSString *)read: (NSString *)key {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    NSString *credit = [documentsDirectory stringByAppendingPathComponent:@"credits.plist"];
    return [[[NSDictionary alloc] initWithContentsOfFile:credit] objectForKey:key];
}

- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood.jpeg"]];
    if( email ) {
        self.navigationItem.hidesBackButton = YES;
        self.title = @"Register";
    }
    else if( username ) {
        self.title = @"Login";
    }
    else if( nextButton ) {
        self.title = @"Getting Started";
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        self.title = @"Further Info";
        self.navigationItem.rightBarButtonItem = nil;
        [linkDisplay setText:[NSString stringWithFormat:@"Access your Web Log at http://clips.cliplogr.com/user/%@", 
                              [self read:@"user"]]];
    }
        
}

- (IBAction)finishButton {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)nextButton {
    //Move to next view
    LoginViewController *lvc = [[LoginViewController alloc]initWithNibName:@"LoginView4" bundle:[NSBundle mainBundle]];    
    [self.navigationController pushViewController:lvc animated:YES];
    [lvc release];
}

- (IBAction)LoginButton {
    NSLog(@"Username: %@, Password: %@", username.text, password.text);    
    
    NSError *err = nil;
    NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/validLogin.php?user=%@&password=%@", username.text, password.text];
    NSString *resp = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:&err];
    if( [resp isEqualToString:@"valid"] ) {
        //Write credits to disk
        [self saveLoginCreds:username.text : password.text];
    
        //Move to next view
        LoginViewController *lvc = [[LoginViewController alloc]initWithNibName:@"LoginView3" bundle:[NSBundle mainBundle]];    
        [self.navigationController pushViewController:lvc animated:YES];
        [lvc release];
    }
    else {
        [alert setText:@"Unable to Validate Login."];
    }
}

- (void)write: (NSString *)key withVal: (NSString *)value {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithCapacity:5];
       
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];        
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"credits.plist"];
    prefs = [NSDictionary dictionaryWithContentsOfFile:appFile];
            
    [prefs setObject:value forKey:key];
    [prefs writeToFile:appFile atomically:YES];
    NSLog(@"Prefs: %@ should have %@: %@", prefs, key, value);
}

- (void)saveLoginCreds: (NSString *)user : (NSString *)passwordNew {
    //Get file location
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];        
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"credits.plist"];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:appFile];
    if( fileExists ) {
        [self write:@"user" withVal:user];
        [self write:@"password" withVal:passwordNew];
    } else {
        NSDictionary *prefs = [[NSDictionary alloc] initWithObjectsAndKeys:user, @"user", passwordNew, @"password", nil];                
        
        [prefs writeToFile:appFile atomically:YES];
        NSLog(@"Prefs: %@ should have root: %@, toor: %@", prefs, user, passwordNew);
    }
}

- (IBAction)SubmitButton {    
    NSError *err = nil;
    NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/validRegister.php?user=%@&password=%@&email=%@", username.text, password.text, email.text];
    NSString *resp = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:&err];
    NSLog(@"Valid Register: %@", resp);
    if( ![resp isEqualToString:@"success"] && !err ) {
        NSLog(@"Username: %@, Password: %@, Email: %@", username.text, password.text, email.text);
        //Register online
        NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/register.php?user=%@", @"test"];                                    
        
        NSString *post = [NSString stringWithFormat:@"user=%@&email=%@&password=%@",username.text, email.text, password.text]; 
        NSMutableData *postData = [NSMutableData data];
        [postData appendData:[post dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]]; 
        NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease]; 
        [request setURL:[NSURL URLWithString:url]]; 
        [request setHTTPMethod:@"POST"]; 
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"]; 
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"]; 
        [request setValue:@"cliplogger" forHTTPHeaderField:@"User-Agent"];
        [request setHTTPBody:postData]; 
        NSError *err = nil;
        NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err]; 
        NSString *response = [[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding]; 
        
        //Save login credits
        [self saveLoginCreds:username.text : password.text];
        
        //Skip login view
        LoginViewController *lvc = [[LoginViewController alloc]initWithNibName:@"LoginView3" bundle:[NSBundle mainBundle]];    
        [self.navigationController pushViewController:lvc animated:YES];
        [lvc release];
    } else {        
        [alert setText:@"Unable to Register."];
    }
}

- (IBAction)SkipButton {        
    LoginViewController *lvc = [[LoginViewController alloc]initWithNibName:@"LoginView2" bundle:[NSBundle mainBundle]];    
    [self.navigationController pushViewController:lvc animated:YES];
    [lvc release];
}

@end
