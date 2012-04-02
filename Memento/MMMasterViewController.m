//
//  MMMasterViewController.m
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import "MMMasterViewController.h"
#import "MMApiLoader.h"
#import "MMInsertSheet.h"
#import "MMDetailViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"
#import "MMApiWrapper.h"
#import "MMRegisterViewController.h"

@implementation MMMasterViewController
@synthesize _items;
@synthesize username;
@synthesize password;

- (void)checkLogin {
    NSArray *sysPaths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *docDirectory = [sysPaths objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.plist", docDirectory, @"user_credits"];    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if( fileExists ) {
        NSDictionary *credits = [NSDictionary dictionaryWithContentsOfFile:filePath];        
        
        NSLog(@"Reading credits from disk (%@,%@)", [credits objectForKey:@"username"], [credits objectForKey:@"password"]);
        self.username = [credits objectForKey:@"username"];
        self.password = [credits objectForKey:@"password"];
    } else {
        NSLog(@"Prompting user for credentials");
        MMRegisterViewController *mmrvc = [[self storyboard] instantiateViewControllerWithIdentifier:@"registerView"];
        mmrvc.delegate = self;
        [self.navigationController pushViewController:mmrvc animated:YES];
    } 
}

//JSON Handling
- (void)parseData: (NSData *)data {
    SBJsonParser *parse = [[SBJsonParser alloc] init];
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableArray *items = [parse objectWithString:json];
    _items = [NSMutableArray arrayWithArray:[[items reverseObjectEnumerator] allObjects]];
    
    [self.tableView reloadData];
}
- (void)saveMomentAtLocation: (NSString *)link withTitle: (NSString *)title andContent: (NSString *)content {
    NSString *slug = link;
    NSString *type = @"image";
    if( [slug isEqualToString:@""] ) {
        slug = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://mneary.info:3001/api/load/nextslug"]];
        type = @"text";
    }        
    
    MMApiWrapper *mmaw = [[MMApiWrapper alloc] init];
    
    NSDate *now = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    long long newPassed = [now timeIntervalSince1970];
    NSString *params = [NSString stringWithFormat:@"title=%@&username=%@&content=%@&timestamp=%@&link=%@&type=%@", title, username, content, [NSString stringWithFormat:@"%lld",newPassed], slug, type];
    
    if( ![mmaw performPostWithParams:params to:@"http://mneary.info:3001/api/save/" forDelegate:self andReadData:NO] ) {
        //handle error
    }
}
- (void)fetchMoments: (NSString *)username {
    //Fetch JSON
    NSLog(@"Fetching...");
    NSURL *mneary = [[NSURL alloc] initWithString:[@"http://mneary.info:3001/api/load/" stringByAppendingString:username]];
    NSMutableURLRequest *getJSON = [[NSMutableURLRequest alloc] initWithURL:mneary];
    
    [getJSON setHTTPMethod:@"GET"];
    MMApiLoader *mmal = [[MMApiLoader alloc] initWithMode:@"GET"];
    mmal.delegate = self;
    
    NSURLConnection *api_load = [[NSURLConnection alloc] initWithRequest:getJSON delegate:mmal]; 
    if( !api_load ) {
        //handle error
    }
}
- (void)displayInsert {
    //Display Modal insert form
    MMInsertSheet *mmis = [[self storyboard] instantiateViewControllerWithIdentifier:@"InsertSheet"];
    mmis.delegate = self;
    [self.navigationController pushViewController:mmis animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if( _items && [indexPath row] == [_items count] ) {
        return;
    } else if( !_items ) {
        return;
    }
    
    int row = [indexPath row];    
    if( [[[_items objectAtIndex:row] valueForKey:@"type"] isEqualToString:@"image"] ) {
        MMDetailViewController *mmdvc = [[self storyboard] instantiateViewControllerWithIdentifier:@"imageDetail"];            
        mmdvc.detailItem = [_items objectAtIndex:row];
        [self.navigationController pushViewController:mmdvc animated:YES];
    } else {
        MMDetailViewController *mmdvc = [[self storyboard] instantiateViewControllerWithIdentifier:@"DetailView"];            
        mmdvc.detailItem = [_items objectAtIndex:row];
        [self.navigationController pushViewController:mmdvc animated:YES];          
    }
}

#pragma mark - View lifecycle

- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
    NSString *responseString = [request responseString];
    if( !responseString ) {
        //handle error
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"Error %@", error);
}

- (NSString *)uploadImageWithData: (NSData *)data {
    NSString *slug = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://mneary.info:3001/api/load/nextslug"]];

    MMApiWrapper *mmaw = [[MMApiWrapper alloc] init];
    [mmaw uploadImageWithData:data to:slug];
    
    //Save locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:[slug stringByAppendingString:@".png"]];
    [data writeToFile:savedImagePath atomically:YES];      
    
    //Save thumbnail
    
    return slug;
}
- (void)logout {
    NSLog(@"Logging Out");
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"user_credits.plist"];
    
    //Delete credits
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:path error:NULL];
    
    //Check login
    [self checkLogin];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(displayInsert)]];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(logout)]];
    [self fetchMoments: @"matt"];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.tableView.tableFooterView = view;
    [self.tableView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];

    [self checkLogin];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if( _items && [indexPath row] < [_items count] ) {
        NSString *type = [[_items objectAtIndex:[indexPath row]] valueForKey:@"type"];
        return [type isEqualToString:@"image"] ? 202 : 102;
    }
    return 40;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {    
    return _items ? [_items count]+1 : 1;
}
- (NSString *)monthAbbr: (NSInteger)integer {
    if( integer == 1 ) return @"JAN";
    if( integer == 2 ) return @"FEB";
    if( integer == 3 ) return @"MAR";
    if( integer == 4 ) return @"APR";
    if( integer == 5 ) return @"MAY";
    if( integer == 6 ) return @"JUN";
    if( integer == 7 ) return @"JUL";
    if( integer == 8 ) return @"AUG";
    if( integer == 9 ) return @"SEP";
    if( integer == 10 ) return @"OCT";
    if( integer == 11 ) return @"NOV";
    if( integer == 12 ) return @"DEC";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {           
    int row = [indexPath row];          
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    
    if( row == (_items ? [_items count] : 0) ) {
        UIImageView *rect = [[UIImageView alloc] initWithFrame:CGRectMake(40, 0, 280, 40)];
        [rect setImage:[UIImage imageNamed:@"corners.png"]];
        [cell insertSubview:rect atIndex:0];   
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }  
    
    //Only runs if if-statement is false
    cell = [tableView dequeueReusableCellWithIdentifier:@"textCell"];                
    UIView *rect;
    NSString *type = [[_items objectAtIndex:row] valueForKey:@"type"];
    if( [type isEqualToString:@"image"] ) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell"];
        NSArray *subviews = cell.contentView.subviews;
        
        //Handle image
        MMApiWrapper *mmaw = [[MMApiWrapper alloc] init];
        [mmaw handleImage:[_items objectAtIndex:row] inTable:self.tableView forImage:[subviews objectAtIndex:0]];
        
        NSString *timestamp = [[_items objectAtIndex:row] valueForKey:@"timestamp"];
        
        //Date handling
        long long oldPassed = [timestamp longLongValue];            
        NSDate *oldTimeStamp = [NSDate dateWithTimeIntervalSince1970:oldPassed];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:oldTimeStamp];        
        
        //Set Date
        [[subviews objectAtIndex:3] setText:[self monthAbbr:[components month]]];
        [[subviews objectAtIndex:4] setText:[NSString stringWithFormat:@"%d",[components day]]];
        
        rect = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 280, 202)];
    }
    else {
        NSArray *subviews = cell.contentView.subviews;
        [[subviews objectAtIndex:0] setText:[[_items objectAtIndex:row] valueForKey:@"content"]];
        [[subviews objectAtIndex:1] setText:[[_items objectAtIndex:row] valueForKey:@"title"]];
        
        NSString *timestamp = [[_items objectAtIndex:row] valueForKey:@"timestamp"];
        
        //Date handling
        long long oldPassed = [timestamp longLongValue];            
        NSDate *oldTimeStamp = [NSDate dateWithTimeIntervalSince1970:oldPassed];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:oldTimeStamp];        
        
        //Set Date
        [[subviews objectAtIndex:4] setText:[self monthAbbr:[components month]]];
        [[subviews objectAtIndex:5] setText:[NSString stringWithFormat:@"%d",[components day]]];
        
        rect = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 280, 102)];
    }
    [rect setBackgroundColor:[UIColor whiteColor]];
    [cell insertSubview:rect atIndex:0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end
