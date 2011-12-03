//
//  RootViewController.m
//  cliplogr
//
//  Created by Matt on 6/28/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import "RootViewController.h"
#import "LoginViewController.h"
#import "TextDetailViewController.h"
#import "ImageDetailViewController.h"
#import "cliplogrAppDelegate.h"
#import "JSON.h"
#import <CFNetwork/CFNetwork.h>

@interface RootViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation RootViewController

@synthesize fetchedResultsController=__fetchedResultsController;
@synthesize managedObjectContext=__managedObjectContext;

int popOutBool = 0;
int popOutSlot = -1;
NSDictionary *asyncRow;
NSString *asyncType = @"";
NSString *asyncContent = @"";
LoginViewController *lvc;

UIImageView *imgCacheframe;
UIScrollView *imgCachescroll;
UIImageView *imgCacheimageView;     
UIView *imgCachemask;
UIView *imgCacheNib;

- (BOOL) connectedToInternet
{
    NSString *URLString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.google.com"]];
    return ( URLString != NULL ) ? YES : NO;
}

+ (void)playSoundCaf: (NSString *)name {
    NSURL *clickSound = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"delete" ofType:@"caf"]];
    SystemSoundID clickSoundID;
    //remember to add framework audiotoolbox
    
    AudioServicesCreateSystemSoundID((CFURLRef)clickSound, &clickSoundID);
    AudioServicesPlaySystemSound(clickSoundID);
    NSLog(@"Beep Bop");
    AudioServicesDisposeSystemSoundID(clickSoundID);
}

- (void)deleteDelegate {
    //Get data before delete
    NSManagedObject *mo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:popOutSlot-1 inSection:0]];
    NSString *slug = [mo valueForKey:@"slug"];
    NSString *slugCache = [NSString stringWithFormat:@"%@", slug];
    
    // Delete the managed object for the given index path
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];                
    [context deleteObject:[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:popOutSlot-1 inSection:0]]];                       
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        //TODO: Error handling, abort is quite harsh.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
        [myTableView reloadData];
    }
    
    
    //Delete from Server                               
    if( [self connectedToInternet] ) {
        if( slugCache ) {
            //Pass slug to server to delete it  
            NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/deleteSlug.php?slug=%@", slugCache];
            NSURL *urlRequest = [NSURL URLWithString:url];
            NSError *err = nil;
            NSString *html = [NSString stringWithContentsOfURL:urlRequest encoding:NSASCIIStringEncoding error:&err];
        }
    } else {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Internet!" message:@"The clip could not be deleted from the server!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
        // optional - add more buttons:
        [alert addButtonWithTitle:@"OK"];
        [alert show];
    }
    
    //Avoid weird bugs
    popOutSlot = -1;
    [myTableView reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if( buttonIndex == 0 )      
        [self deleteDelegate];
}

- (IBAction)deleteItemClick {    
    UIActionSheet *confirm = [[UIActionSheet alloc] 
                                initWithTitle:@"Are you sure you want to delete this clip?" 
                                delegate:self 
                                cancelButtonTitle:@"Cancel" 
                                destructiveButtonTitle:@"Yes, Delete" 
                                otherButtonTitles:nil];
    confirm.actionSheetStyle = UIActionSheetStyleDefault;
    [confirm showInView:self.view];
    [confirm release];
}

- (IBAction)viewItemClick {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:popOutSlot-1 inSection:0]];
    NSString *type = [[managedObject valueForKey:@"type"] description];
    NSString *contents = [[managedObject valueForKey:@"contents"] description];
    NSString *slug = [[managedObject valueForKey:@"slug"] description];
    
    if( [type isEqualToString:@"string"] ) {
        TextDetailViewController *tdvc = [[TextDetailViewController alloc]initWithNibName:@"TextDetailView" bundle:[NSBundle mainBundle]];    
        [super.navigationController pushViewController:tdvc animated:YES];
        [tdvc initWithLink:[NSString stringWithFormat:@"http://clips.cliplogr.com/%@", slug] andContents:contents];
        [tdvc release];
    }
    else {  //Image
        ImageDetailViewController *idvc = [[ImageDetailViewController alloc] initWithNibName:@"ImageDetailView" bundle:[NSBundle mainBundle]];
        [self.navigationController pushViewController:idvc animated:YES];
        [idvc initWithLink:[NSString stringWithFormat:@"http://clips.cliplogr.com/%@", slug] andContents:contents];
        [idvc release];
    }
    //TODO: recognize links and display webview
}

- (IBAction)shareItemClick {
    if ([MFMailComposeViewController canSendMail]) {        
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:popOutSlot-1 inSection:0]];
        NSString *type = [[managedObject valueForKey:@"type"] description];
        NSString *contents = [[managedObject valueForKey:@"contents"] description];
        NSString *slug = [[managedObject valueForKey:@"slug"] description];
        NSString *signature = @"<br><br>Sent from <a href='http://cliplogr.com'>Clip Logger</a>";
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;  //Technically incompatible delegate
        [mailViewController setSubject:@"Clip Logger"];
        NSString *body = [NSString stringWithFormat:@"Hey,<br>Checkout this %@ of mine <a href='http://clips.cliplogr.com/%@'>Here</a>.", ([type isEqualToString:@"image"]?@"Picture":@"Clip"), slug];
        if( [type isEqualToString:@"image"] )
            body = [body stringByAppendingFormat:@"\n<img width=280 src='http://files.cliplogr.com/%@'>", slug];
        [mailViewController setMessageBody:[body stringByAppendingString:signature] isHTML:YES];
        [self presentModalViewController:mailViewController animated:YES];
        [mailViewController release];        
    }    
    else {        
        NSLog(@"Device is unable to send email in its current state.");        
    }   
}

- (IBAction)copyItemClick {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:popOutSlot-1 inSection:0]];
    NSString *type = [[managedObject valueForKey:@"type"] description];
    NSString *contents = [[managedObject valueForKey:@"contents"] description];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if( [type isEqualToString:@"string"] )
        [pasteboard setString:contents];
    else {  //Handle image       
        UIImage *clip = [UIImage imageWithContentsOfFile:contents];
        [pasteboard setImage:clip];
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self dismissModalViewControllerAnimated:YES];
    
}

-(NSString *)urlencode: (NSString *)url {
    NSArray *escapeChars  = [NSArray arrayWithObjects:
                             @";" , @"/" , @"?" , @":" ,
                             @"@" , @"&" , @"=" , @"+" ,
                             @"$" , @"," , @"[" , @"]" ,
                             @"#" , @"!" , @"'" , @"(" , 
                             @")" , @"*" , @" ",  @"\"",
                             @"\n", nil];
    
    NSArray *replaceChars = [NSArray arrayWithObjects:
                             @"%3B" , @"%2F" , @"%3F" ,
                             @"%3A" , @"%40" , @"%26" ,
                             @"%3D" , @"%2B" , @"%24" ,
                             @"%2C" , @"%5B" , @"%5D" , 
                             @"%23" , @"%21" , @"%27" ,
                             @"%28" , @"%29" , @"%2A" ,
                             @"%20" , @"%22" , @"" , nil];    
    int len = [escapeChars count];    
    NSMutableString *temp = [url mutableCopy];    
    
    for(int i = 0; i < len-1; i++) {        
        [temp replaceOccurrencesOfString:[escapeChars objectAtIndex:i]
                              withString:[replaceChars objectAtIndex:i]
                                 options:NSLiteralSearch
                                   range:NSMakeRange(0, [temp length])];
    }
    [temp replaceOccurrencesOfString:[escapeChars objectAtIndex:len-1]
                          withString:[replaceChars objectAtIndex:len-1]
                             options:0
                               range:NSMakeRange(0, [temp length])];
    
    NSString *out = [NSString stringWithString: temp];    
    [temp release];

    return out;
}

-(BOOL)retreiveDataviaPredicate: (long long)timePassed withContent:(NSString *)contentSend andSlug:(NSString *)slug
{
    NSFetchRequest *fetchReq = [[NSFetchRequest alloc]init];
    
    NSPredicate *query = [NSPredicate predicateWithFormat:@"(contents CONTAINS[cd] %@) OR (slug CONTAINS[cd] %@)", [contentSend lastPathComponent], slug];
    
    //setting the predicate to the fetch request 
    [fetchReq setPredicate:query];
    
    [fetchReq setEntity:[NSEntityDescription entityForName:@"Clips" inManagedObjectContext:self.managedObjectContext]];
    
    NSError *err = nil;
    NSArray *resp = [self.managedObjectContext executeFetchRequest:fetchReq error:&err];   
    NSMutableArray *resultArray = [[NSMutableArray alloc]initWithArray:resp];
    
    return [resultArray count] > 0 && !err ? YES : NO;
}

- (void) grabImage:(NSString*)urlString withSlug:(NSString*)slug andTime:(NSDate*)timeStampDate {
    
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage *download = nil; 
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *responseData = [NSData dataWithContentsOfURL:url];
        download = [UIImage imageWithData:responseData];
        
        if (download) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //Download the Image with slug for name                                
                NSData *imageData = UIImagePNGRepresentation(download);
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0]; 
                NSString *picFile = [documentsDirectory stringByAppendingPathComponent:                                                     
                                            [slug stringByReplacingOccurrencesOfString:@" " withString:@""]];
                                
                [imageData writeToFile:picFile atomically:YES];
                [self insertNewObject:picFile ofType:@"image" withTime:timeStampDate andSlug:slug];
            });
            //dispatch_async(dispatch_get_main_queue(), completion);
        }
        else {
            NSLog(@"-- impossible download: %@", urlString);
        }
	});   
}

-(NSString *)read: (NSString *)key {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    NSString *credit = [documentsDirectory stringByAppendingPathComponent:@"credits.plist"];
    return [[[NSDictionary alloc] initWithContentsOfFile:credit] objectForKey:key];
}

-(void)downloadClips {    
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    
    //Get newest 10 times from php file
    NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/whatsnew.php?user=%@", [self read:@"user"]];    
    NSURL *urlRequest = [NSURL URLWithString:url];
    NSError *err = nil;
    
    NSString *html = [NSString stringWithContentsOfURL:urlRequest encoding:NSUTF8StringEncoding error:&err];          
    
    if(err || !html)   
        return;
    
    //Cycle through the newest clips
    NSArray *data = [parser objectWithString:html];        
    for( int i = 0; i < [data count]; i++ ) {                
        UIApplication* app = [UIApplication sharedApplication];
        //[app setNetworkActivityIndicatorVisible:YES];
        
        NSDictionary *row = [data objectAtIndex:i];            
        NSString *timeRead = [row objectForKey:@"timeStamp"];
        NSString *slugRead = [row objectForKey:@"slug"];
        NSString *contentRead = [row objectForKey:@"content"];
        long long timePassed = [timeRead longLongValue];            
        NSDate *timeStampDate = [NSDate dateWithTimeIntervalSince1970:timePassed];            
        
        BOOL doContain = [self retreiveDataviaPredicate:timePassed withContent:contentRead andSlug:slugRead];
        if  ( !doContain && ![slugRead isEqualToString:@"abcd"] ) {            
            if( [[row objectForKey:@"type"] isEqualToString:@"image"] ) {                
                NSString *downloadURL = [NSString stringWithFormat:@"http://mneary.info/APIs/upload/files/%@.png", slugRead];
                [self grabImage:downloadURL withSlug:slugRead andTime:timeStampDate];
                UIApplication* app = [UIApplication sharedApplication];
                app.networkActivityIndicatorVisible = NO;
            }
            else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self insertNewObject:[row objectForKey:@"content"] ofType:[row objectForKey:@"type"] withTime:timeStampDate andSlug:slugRead]; 
                });                
                //UIApplication* app = [UIApplication sharedApplication];
                //app.networkActivityIndicatorVisible = NO;
            }
        }
        [app setNetworkActivityIndicatorVisible:NO];
    }       
    //[parser release];
}

- (void)uploadAsyncRequest:(NSString *)filename 
                  fromTime:(NSString *)argTime
             success:(void(^)(NSData *,NSString *,NSURLResponse *))successBlock_ 
             failure:(void(^)(NSData *,NSString *,NSError *))failureBlock_ {        
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{                
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        //[[Preparation]]
        // create the URL
        NSURL *postURL = [NSURL URLWithString:@"http://mneary.info/APIs/upload/upload.php"];        
        // create the connection
        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:postURL
                                                                   cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                               timeoutInterval:30.0];   
        //[[Settings]]
        // change type to POST (default is GET)
        [postRequest setHTTPMethod:@"POST"];           
        // just some random text that will never occur in the body
        NSString *stringBoundary = @"0xKhTmLbOuNdArY---This_Is_ThE_BoUnDaRyy---pqo";        
        // header value
        NSString *headerBoundary = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];        
        // set header
        [postRequest addValue:headerBoundary forHTTPHeaderField:@"Content-Type"];
        //[[Data]]        
        // create data
        NSMutableData *postBody = [NSMutableData data];
        // media part
        [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", [filename lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Type: image/png\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];        
        //[[Data Read]]
        NSString *imagePath = filename;
        NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
        UIImage *imageRead = [UIImage imageWithData:imageData];
        NSData *convert = UIImagePNGRepresentation(imageRead);
        //[[Append to Body]]
        [postBody appendData:convert];
        [postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];        
        //[[Close it]]
        [postBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        //[[Add to request]]
        [postRequest setHTTPBody:postBody];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&response error:&error];
        if (error) {
            failureBlock_(data,argTime,error);
        } else {
            successBlock_(data,argTime,response);
        }
        
        [pool release];
    });
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (void)delegateSync {
    if( [self connectedToInternet] ) {
        //Avoid weird bugs
        popOutSlot = -1;
        [myTableView reloadData];
        
        UIImageView *loading = [[UIImageView alloc] initWithFrame:CGRectMake(47, 160, 226, 178)];
        [loading setImage:[UIImage imageNamed:@"loading.png"]];
        UIApplication* app = [UIApplication sharedApplication];
        [[app.windows objectAtIndex:0] addSubview:loading];
        
        //Spin status indicator        
        [app setNetworkActivityIndicatorVisible:YES];

        //Perform sync
        //(No Longer Used) [self uploadClips];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self downloadClips];
        });
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:2];
        [loading setAlpha:0];
        [UIView commitAnimations];
        
        [app setNetworkActivityIndicatorVisible:NO];
        
    }
    else {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Internet!" message:@"The sync failed due to lack of internet!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
        // optional - add more buttons:
        [alert addButtonWithTitle:@"OK"];
        [alert show];
    }
}

- (void)getClip {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *string;
    
    //Avoid weird bugs
    popOutSlot = -1;
    [myTableView reloadData];
    
    if( pasteboard.string ) {
        string = pasteboard.string;        
        [self insertNewObject:string ofType:@"string"];
    }
    else if( pasteboard.image ) {
        NSArray *images = pasteboard.images;
        int count = 0;
        for( UIImage *image in images ) {    
            //Allow handling of multiple copied images
            NSData *imageData = UIImagePNGRepresentation(image);      
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];        
            NSString *appFile = [documentsDirectory stringByAppendingPathComponent:                                                     
                                 [[NSString stringWithFormat:@"%@(%d).png",[NSDate date], count] stringByReplacingOccurrencesOfString:@" " withString:@""]];
            
            [imageData writeToFile:appFile atomically:YES];                
            string = appFile;        
            [self insertNewObject:string ofType:@"image"];
            count++;
        }
    }
    else if( pasteboard.URL ) {
        NSURL *url = pasteboard.URL;
        string = [url absoluteString];        
        [self insertNewObject:string ofType:@"url"];
    }
    else if( pasteboard.color ) {
        UIColor *color = pasteboard.color;
        string = [color description];        
        [self insertNewObject:string ofType:@"color"];
    } 
    
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Upload
        SBJsonWriter *encoder = [[SBJsonWriter alloc] init];
        
        NSManagedObject *mo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSString *type = [mo valueForKey:@"type"];
        NSString *contents = [mo valueForKey:@"contents"];
        NSDate *theDate = [mo valueForKey:@"timeStamp"];                
        
        NSTimeInterval oldTime = [theDate timeIntervalSince1970];
        NSString *unixTime = [NSString stringWithFormat:@"%f", oldTime];
        
        if( [self connectedToInternet] ) {          
            NSDictionary *row;
            
            //Image upload/slug fetch
            if( [type isEqualToString:@"image"] ) {
                asyncContent = contents;
                asyncType = type;
                asyncUnixTime = unixTime;
                
                UIApplication* app = [UIApplication sharedApplication];
                app.networkActivityIndicatorVisible = YES;
                
                [self uploadAsyncRequest:asyncContent fromTime:asyncUnixTime success:^(NSData *data, NSString *argTime, NSURLResponse *resp){
                    
                    NSString *tempType = asyncType;
                    NSString *tempContent = asyncContent;
                    NSString *tempTime = argTime;       //Had trouble doing a global, hence the argument                
                    NSString *tempData = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
                    NSDictionary *newRow = [[NSDictionary alloc] initWithObjectsAndKeys:tempType, @"type", tempContent, @"content", tempTime, @"timeStamp", tempData, @"slug", nil]; 
                    
                    //TODO: Move this crap to a function
                    NSString *jsonData = [encoder stringWithObject:newRow];            
                    NSString *jsonDataE = [self urlencode:jsonData];
                    NSMutableString *jsonMute = [jsonDataE mutableCopy];
                    
                    NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/submitJSON.php?user=%@", [self read:@"user"]];                                    
                    
                    NSString *post = [NSString stringWithFormat:@"jdata=%@",jsonMute]; 
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
                    
                    if( err )
                        NSLog(@"FAIL!!!!! %@ (%@)", err, [err userInfo]);
                    
                    //Modify local copy
                    [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] setValue:tempData forKey:@"slug"];
                    err = nil;
                    [self saveContext];               
                }failure:^(NSData *data, NSString *argTime, NSError *error){
                    asyncRow = [[NSDictionary alloc] initWithObjectsAndKeys:asyncType, @"type", asyncContent, @"contents", asyncUnixTime, @"timeStamp", @"", @"slug", nil];                     
                }];
                row = asyncRow;                                
            }    
            else {         
                //Get next text slug
                NSString *url = @"http://mneary.info/APIs/u/getStringClipSlug.php";    
                NSURL *urlRequest = [NSURL URLWithString:url];
                NSError *err = nil;
                
                NSString *html = [NSString stringWithContentsOfURL:urlRequest encoding:NSUTF8StringEncoding error:&err];          
                NSString *slugViaUpload = html;
                
                //Prep data for upload
                row = [[NSDictionary alloc] initWithObjectsAndKeys:type, @"type", contents, @"content", unixTime, @"timeStamp", html, @"slug", nil];
                NSString *jsonData = [encoder stringWithObject:row];  
                NSString *jsonDataE = [self urlencode:jsonData];
                NSMutableString *jsonMute = [jsonDataE mutableCopy];                           
                
                //Upload Data (with slug from PHP fetch)
                url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/submitJSON.php?user=%@", [self read:@"user"]];
                
                NSString *post = [NSString stringWithFormat:@"jdata=%@",jsonMute]; 
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
                NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err]; 
                NSString *response = [[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding]; 
                
                if( err )
                    NSLog(@"FAIL!!!!! %@ (%@)", err, [err userInfo]);
                
                //Modify local copy
                [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] setValue:slugViaUpload forKey:@"slug"];
                err = nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self saveContext]; 
                });               
            }
        }
        else {                       
            //Modify local copy
            [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] setValue:@"9999" forKey:@"slug"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self saveContext]; 
            });                          
        }
        
        UIApplication* app = [UIApplication sharedApplication];
        app.networkActivityIndicatorVisible = NO;
    }); //End ginormous lambda
}

- (BOOL)validateLoginSubmit {
    
    NSURL *url = [NSURL URLWithString:  
           [NSString stringWithFormat:@"http://mneary.info/APIs/u/validLogin.php?user=%@&password=%@", [self read:@"user"], [self read:@"password"]]];
    
    NSError *err = nil;    
    NSString *html = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    
    if ([html isEqualToString:@"valid"])        
        return true;    
    return false;                
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    if( ![self connectedToInternet] ) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Internet!" message:@"You are not connected to the internet!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
        // optional - add more buttons:
        [alert addButtonWithTitle:@"OK"];
        [alert show];
    }        
    
    //Get file location for credentials
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];        
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"credits.plist"];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:appFile];
    if( !fileExists ) {
        //Display login view as Child (semantic?).    
        lvc = [[LoginViewController alloc]initWithNibName:@"LoginView" bundle:[NSBundle mainBundle]];    
        //[self presentModalViewController:lvc animated:YES];
        [self.navigationController pushViewController:lvc animated:YES];
    
        [lvc release];
    }
    
    [RootViewController playSoundCaf:@"startup"];        
    
    //Set title for use with Back button
    self.title = @"Log";
    
    // Set up the edit / add buttons.
    // For an edit button: self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(getClip)];    
    
    UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(delegateSync)];    
    
    self.navigationItem.leftBarButtonItem = syncButton;
    
    self.navigationItem.rightBarButtonItem = addButton;
    myTableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood.jpeg"]];        
    
    [addButton release];        
    
}

- (void)viewWillAppear:(BOOL)animated
{
    //Load cell content
    imgCacheNib = [[[NSBundle mainBundle] loadNibNamed:@"imageView" owner:nil options:nil] objectAtIndex:0];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];  
    
    /*
    //Custom Bar
    UIView *top = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 49)];
    [top setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"instagram.png"]]];
    [self.navigationController.navigationBar insertSubview:top atIndex:0];
     */
    
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [[[self.navigationController.navigationBar subviews] objectAtIndex:0] removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
     // Return YES for supported orientations.
     return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects] + (popOutSlot != -1 ? 1 : 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int count = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];    
    if( [indexPath row]>(count-2) && [indexPath row] < popOutSlot )
        return 20; 
    else if( [indexPath row]>(count-1) && [indexPath row] > popOutSlot )
        return 25; 
    return [indexPath row] == popOutSlot ? 50 : 120;
}

- (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    
	CGImageRef maskRef = maskImage.CGImage; 
    
	CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
	CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
	return [UIImage imageWithCGImage:masked];
    
}

- (NSString*)formatPassedTime: (NSTimeInterval)seconds {
    int unit;
    if( seconds / (unit = 60*60*24*365) > 1 )
        return [NSString stringWithFormat:@"%@ years ago",[NSNumber numberWithDouble:floor(seconds/unit)]];
    else if( seconds / (unit = 60*60*24*30) > 1 )
        return [NSString stringWithFormat:@"%@ months ago",[NSNumber numberWithDouble:floor(seconds/unit)]];
    else if( seconds / (unit = 60*60*24*7) > 1 )
        return [NSString stringWithFormat:@"%@ weeks ago",[NSNumber numberWithDouble:floor(seconds/unit)]];
    else if( seconds / (unit = 60*60*24) > 1 )
        return [NSString stringWithFormat:@"%@ days ago",[NSNumber numberWithDouble:floor(seconds/unit)]];
    else if( seconds / (unit = 60*60) > 1 )
        return [NSString stringWithFormat:@"%@ hours ago",[NSNumber numberWithDouble:floor(seconds/unit)]];
    else if( seconds / (unit = 60) > 1 )
        return [NSString stringWithFormat:@"%@ minutes ago",[NSNumber numberWithDouble:floor(seconds/unit)]];
    else if( seconds / (unit = 1) > 1 )
        return [NSString stringWithFormat:@"%@ seconds ago",[NSNumber numberWithDouble:floor(seconds/unit)]];
    else
        return @"just now";
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSString *contents = @"";
    NSString *type = @"";
    NSString *author = @"";
    NSString *timeStamp = @"";
    NSString *slug = @"";
    int row = [indexPath row];
    
    //Choose appropriate item from array
    if( row < popOutSlot || popOutSlot == -1 ) {
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
        type = [[managedObject valueForKey:@"type"] description];
        contents = [[managedObject valueForKey:@"contents"] description];
        author = [[managedObject valueForKey:@"author"] description];
        timeStamp = [[managedObject valueForKey:@"timeStamp"] description];
        slug = [[managedObject valueForKey:@"slug"] description];
    }
    else if( row == popOutSlot ) {       
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"popout"] autorelease];        
        [cell.contentView addSubview:editPane];
    }
    else {    //row > popOutSlot                
        int limit = [myTableView numberOfRowsInSection:0]-1;
        int intention = [indexPath row];
        int lengthOfSection =  intention < limit ? intention : limit;
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:lengthOfSection-1 inSection:0]];
        type = [[managedObject valueForKey:@"type"] description];
        contents = [[managedObject valueForKey:@"contents"] description];  
        author = [[managedObject valueForKey:@"author"] description];
        timeStamp = [[managedObject valueForKey:@"timeStamp"] description];
        slug = [[managedObject valueForKey:@"slug"] description];
    }
    
    if( [type isEqualToString:@"string"] && row != popOutSlot ) { 
        //UIView *temp = [[[NSBundle mainBundle] loadNibNamed:@"textView" owner:nil options:nil] objectAtIndex:0];
        //**UIView *temp = cell.contentView;
        UIView *temp = [[cell.contentView subviews] objectAtIndex:0];
        UITextView *textView = [[temp subviews] objectAtIndex:0];
        UILabel *authorLabel = [[temp subviews] objectAtIndex:2];
        UILabel *dateLabel = [[temp subviews] objectAtIndex:1];        
        //UITextView *tempText = notePadTextView;
        
        //Prepare timestamp for passed time label
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];        
        
        NSDate *theDate = nil;
        NSError *error = nil;    
        NSString *timePassed = @"";
        if (![df getObjectValue:&theDate forString:timeStamp range:nil error:&error]) {
            NSLog(@"Date '%@' could not be parsed: %@", timeStamp, error);
        }[df release];
        if( !error && timeStamp && theDate ) {
            NSTimeInterval old1970 = [[[NSDate alloc] init] timeIntervalSinceDate:theDate];       
            timePassed = [self formatPassedTime:old1970];
        }
        
        [textView setText:contents];
        [authorLabel setText:[NSString stringWithFormat:@"via %@", author]];
        [dateLabel setText:timePassed];
        [temp setBounds:CGRectMake(-24, 0, 267, 120)];        
        //[cell.contentView addSubview:temp];         
        
        UIView *mask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 267, 120)];
        [cell.contentView addSubview:mask];
    }       
    else if( contents && row != popOutSlot ) {    //if( [type isEqualToString:@"image"] )                
        NSString *path = contents;
        UIImage *thePic = [UIImage imageWithContentsOfFile:path];
        CGSize picSize = [thePic size];        
        
        //UIView *temp = [[[NSBundle mainBundle] loadNibNamed:@"imageView" owner:nil options:nil] objectAtIndex:0];
        //UIView *temp = [[cell.contentView subviews] objectAtIndex:0];
        UIView *temp = cell.contentView;
        UIScrollView *scrollView = [[temp subviews] objectAtIndex:0];
        UIImageView *imageView = [[scrollView subviews] objectAtIndex:0];         
        
        CGFloat scaleWidth = picSize.width/237;
        CGFloat scaleHeight = picSize.height/94;
        CGFloat scale = scaleHeight < scaleWidth ? scaleHeight : scaleWidth;   
                       
        if(scaleWidth && scaleHeight) {           
            [imageView setFrame:CGRectMake((267-1/scale*picSize.width)/2, -6, 1/scale*picSize.width, 1/scale*picSize.height)];          
            scrollView.contentSize = CGSizeMake(1/scale*picSize.width, 1/scale*picSize.height);
            scrollView.scrollEnabled = NO;
        }
        else {            
            [imageView setFrame:CGRectMake(46, 14, 198, 94)];   
        }
        [imageView setBackgroundColor:[UIColor blackColor]];        
        [imageView setImage:thePic];                
        
        [cell setEditingAccessoryType:UITableViewCellEditingStyleInsert];
    }        
    
    UIView *errorPane = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 43, 100)];    
    
    if( [slug isEqualToString:@"9999"] ) {
        [errorPane setBackgroundColor:[UIColor redColor]];
    }
    else {
        [errorPane setBackgroundColor:[UIColor whiteColor]];
    }
    [cell.contentView addSubview:errorPane];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone; 
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int count = [[[self.fetchedResultsController sections] objectAtIndex:0] numberOfObjects];    
    if( [indexPath row]>(count-2) && [indexPath row] < popOutSlot )
        return [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"image"] autorelease];   
    else if( [indexPath row]>(count-1) && [indexPath row] > popOutSlot )
        return [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"image"] autorelease];  
    NSManagedObject *managedObject = nil;    
    if( [indexPath row] > popOutSlot ) {
        managedObject = [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row]-1 inSection:0 ]] retain];
    }
    else if( [indexPath row] < popOutSlot ) {
         managedObject = [[self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row] inSection:0 ]] retain];
    }
    NSString *type;
    if( managedObject )
        type = [[managedObject valueForKey:@"type"] description];
    else
        type = @"popout";
    
    static NSString *CellIdentifier;
    if( [type isEqualToString:@"image"] ) {
        CellIdentifier = @"imageCell";    
    }
    else if( [type isEqualToString:@"string"] ) {
        CellIdentifier = @"textCell";
    }
    else {
        CellIdentifier = @"popOut";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( !cell ) {        
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        if( [type isEqualToString:@"image"] ) {
            NSLog(@"Creating new image...");
            /*
             Option Nib:   *//* 
             UIView *temp = [[[NSBundle mainBundle] loadNibNamed:@"imageView" owner:nil options:nil] objectAtIndex:1];
            [cell.contentView addSubview:temp];       /*
            *//*
             Option Hard Code: */            
            UIScrollView *imgCachescroll = [[UIScrollView alloc] initWithFrame:CGRectMake(43, 12, 247, 84)];
            [imgCachescroll setUserInteractionEnabled:NO];
            UIImageView *imgCacheimageView = [[UIImageView alloc] initWithFrame:CGRectMake(43, 12, 247, 84)];  
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(45, 0, 1, 120)];
            [line setBackgroundColor:[UIColor grayColor]];
            
            [imgCachescroll addSubview:imgCacheimageView];                      
            [cell.contentView addSubview:imgCachescroll];            
            [cell.contentView addSubview:line];
        } else {
            NSLog(@"Creating new text...");
            UIView *temp = [[[NSBundle mainBundle] loadNibNamed:@"textView" owner:nil options:nil] objectAtIndex:0];
            [cell.contentView addSubview:temp];
        }
    } else {
        //...
    }

    //Configuration
    if( [indexPath row] == popOutSlot ) {   
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"popout"] autorelease];        
        [cell.contentView addSubview:editPane];
        [cell setSelectionStyle:UITableViewCellEditingStyleNone];
    } else {
        [self configureCell:cell atIndexPath:indexPath];
    }            
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return [indexPath row] == popOutSlot ? NO : YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            //TODO: Error handling, abort is quite harsh.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *slug = @"";    
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    slug = [managedObject valueForKey:@"slug"];
    
    if( popOutSlot-1 != indexPath.row && popOutSlot != [indexPath row] ) {
        if( [slug isEqualToString:@"9999"] ) {
            
            UIApplication *app = [UIApplication sharedApplication];
            [app setNetworkActivityIndicatorVisible:YES];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //Upload
                SBJsonWriter *encoder = [[SBJsonWriter alloc] init];
                
                NSManagedObject *mo = [self.fetchedResultsController objectAtIndexPath:indexPath];
                NSString *type = [mo valueForKey:@"type"];
                NSString *contents = [mo valueForKey:@"contents"];
                NSDate *theDate = [mo valueForKey:@"timeStamp"];                
                
                NSTimeInterval oldTime = [theDate timeIntervalSince1970];
                NSString *unixTime = [NSString stringWithFormat:@"%f", oldTime];
                
                if( [self connectedToInternet] ) {          
                    NSDictionary *row;
                    
                    //Image upload/slug fetch
                    if( [type isEqualToString:@"image"] ) {
                        asyncContent = contents;
                        asyncType = type;
                        asyncUnixTime = unixTime;
                        
                        UIApplication* app = [UIApplication sharedApplication];
                        app.networkActivityIndicatorVisible = YES;
                        
                        [self uploadAsyncRequest:asyncContent fromTime:asyncUnixTime success:^(NSData *data, NSString *argTime, NSURLResponse *resp){
                            
                            NSString *tempType = asyncType;
                            NSString *tempContent = asyncContent;
                            NSString *tempTime = argTime;       //Had trouble doing a global, hence the argument
                 
                            NSString *tempData = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
                            
                            NSDictionary *newRow = [[NSDictionary alloc] initWithObjectsAndKeys:tempType, @"type", tempContent, @"content", tempTime, @"timeStamp", tempData, @"slug", nil]; 
                            
                            //TODO: Move this crap to a function
                            NSString *jsonData = [encoder stringWithObject:newRow];            
                            NSString *jsonDataE = [self urlencode:jsonData];
                            NSMutableString *jsonMute = [jsonDataE mutableCopy];
                            
                            NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/submitJSON.php?user=%@", [self read:@"user"]];                                    
                            
                            NSString *post = [NSString stringWithFormat:@"jdata=%@",jsonMute]; 
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
                            
                            if( err )
                                NSLog(@"FAIL!!!!! %@ (%@)", err, [err userInfo]);
                            
                            //Modify local copy
                            [[self.fetchedResultsController objectAtIndexPath:indexPath] setValue:tempData forKey:@"slug"];
                            err = nil;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self saveContext]; 
                            });                            
                        }failure:^(NSData *data, NSString *argTime, NSError *error){
                            asyncRow = [[NSDictionary alloc] initWithObjectsAndKeys:asyncType, @"type", asyncContent, @"contents", asyncUnixTime, @"timeStamp", @"", @"slug", nil];                     
                        }];
                        row = asyncRow;                                
                    }    
                    else {         
                        //Get next text slug
                        NSString *url = @"http://mneary.info/APIs/u/getStringClipSlug.php";    
                        NSURL *urlRequest = [NSURL URLWithString:url];
                        NSError *err = nil;
                        
                        NSString *html = [NSString stringWithContentsOfURL:urlRequest encoding:NSUTF8StringEncoding error:&err];          
                        NSString *slugViaUpload = html;
                        
                        //Prep data for upload
                        row = [[NSDictionary alloc] initWithObjectsAndKeys:type, @"type", contents, @"content", unixTime, @"timeStamp", html, @"slug", nil];
                        NSString *jsonData = [encoder stringWithObject:row];  
                        NSString *jsonDataE = [self urlencode:jsonData];
                        NSMutableString *jsonMute = [jsonDataE mutableCopy];                           
                        
                        //Upload Data (with slug from PHP fetch)
                        url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/submitJSON.php?user=%@", [self read:@"user"]];
                        
                        NSString *post = [NSString stringWithFormat:@"jdata=%@",jsonMute]; 
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
                        NSData *urlData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err]; 
                        NSString *response = [[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding]; 
                        
                        if( err )
                            NSLog(@"FAIL!!!!! %@ (%@)", err, [err userInfo]);
                        
                        //Modify local copy
                        [[self.fetchedResultsController objectAtIndexPath:indexPath] setValue:slugViaUpload forKey:@"slug"];
                        err = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self saveContext]; 
                        });                                       
                    }
                    
                    UIImageView *loading = [[UIImageView alloc] initWithFrame:CGRectMake(47, 160, 226, 178)];
                    [loading setImage:[UIImage imageNamed:@"loading.png"]];            
                    [[app.windows objectAtIndex:0] addSubview:loading];
                    
                    [myTableView reloadData];
                    
                    [UIView beginAnimations:nil context:NULL];
                    [UIView setAnimationDuration:2];
                    [loading setAlpha:0];
                    [UIView commitAnimations];
                }
                /*else {
                    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Internet!" message:@"The sync failed due to lack of internet!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil] autorelease];
                    // optional - add more buttons:
                    [alert addButtonWithTitle:@"OK"];
                    [alert show];                                                                  
                }
                */                
            }); //End ginormous lambda                                                
        }                
        UIApplication* app = [UIApplication sharedApplication];
        [app setNetworkActivityIndicatorVisible:NO];
        
        int rowSlot = [indexPath row]+1;        
        int aboveBool = rowSlot > popOutSlot && ~popOutSlot ? 1 : 0;
        rowSlot -= aboveBool;
        
        NSArray *rowArr = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowSlot inSection:0]];
        if( popOutSlot != -1 ) {
            //Delete current 
            NSArray *oldRowArr = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:popOutSlot inSection:0]];
            popOutSlot = -1;
            [tableView deleteRowsAtIndexPaths:oldRowArr
                             withRowAnimation:UITableViewRowAnimationBottom];
            
            popOutSlot = rowSlot;
            popOutBool = 1;
            [[self tableView] insertRowsAtIndexPaths:rowArr
                                    withRowAnimation:UITableViewRowAnimationTop];
            
            int rowCount = [self tableView:myTableView numberOfRowsInSection:0];
            
            [myTableView scrollToRowAtIndexPath:
             [NSIndexPath indexPathForRow:(popOutSlot+1 < rowCount ? (popOutSlot+1) : rowCount-1) inSection:0] 
                               atScrollPosition:UITableViewScrollPositionNone 
                                       animated:YES];
        }      
        else {
            popOutSlot = rowSlot;
            popOutBool = 1;
            [[self tableView] insertRowsAtIndexPaths:rowArr
                                    withRowAnimation:UITableViewRowAnimationTop];
            
            int rowCount = [self tableView:myTableView numberOfRowsInSection:0];
            
            [myTableView scrollToRowAtIndexPath:
             [NSIndexPath indexPathForRow:(popOutSlot+1 < rowCount ? (popOutSlot+1) : rowCount-1) inSection:0] 
                               atScrollPosition:UITableViewScrollPositionNone 
                                       animated:YES];            
        }                
        
    }
    else if( popOutSlot != indexPath.row ) {
        if( popOutBool ) {
            //Delete current 
            int tmp = popOutSlot;
            popOutSlot = -1;
            NSArray *oldRowArr = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:tmp inSection:0]];
            popOutBool = 0; 
            [[self tableView] deleteRowsAtIndexPaths:oldRowArr
                                    withRowAnimation:UITableViewRowAnimationNone];
        }               
    }    
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc
{
    [__fetchedResultsController release];
    [__managedObjectContext release];
    [super dealloc];
}
/*
 - (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
 {
 
 }
 */

- (void)insertNewObject: (NSString *)contents ofType:(NSString *)type
{
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    [newManagedObject setValue:contents forKey:@"contents"];
    [newManagedObject setValue:type forKey:@"type"];
    [newManagedObject setValue:@"Clipboard" forKey:@"author"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)insertNewObject: (NSString *)contents ofType:(NSString *)type withTime:(NSDate *)timestamp andSlug:(NSString *)slug
{
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:timestamp forKey:@"timeStamp"];
    [newManagedObject setValue:contents forKey:@"contents"];
    [newManagedObject setValue:type forKey:@"type"];
    [newManagedObject setValue:@"Sync" forKey:@"author"];
    [newManagedObject setValue:slug forKey:@"slug"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error])
    {
        //TODO: Error handling, abort is quite harsh
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil)
    {
        return __fetchedResultsController;
    }    
    /*
     Set up the fetched results controller.
     */
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Clips" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    [aFetchedResultsController release];
    [fetchRequest release];
    [sortDescriptor release];
    [sortDescriptors release];
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error])
    {
	    //TODO: Error handling, abort is quite harsh.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

#pragma mark - Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type)
    {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            //[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];    
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
 //TODO: Allows multiple changes to be processed at once.
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

@end
