//
//  MMMasterViewController.m
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

//SEE http://safe.tumblr.com/theme/preview/11655 for inspiration

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
    NSString *params = [NSString stringWithFormat:@"title=%@&username=%@&content=%@&timestamp=%@&link=%@&type=%@", title, @"matt", content, @"18-2-12", slug, type];
    
    if( ![mmaw performPostWithParams:params to:@"http://mneary.info:3001/api/save/" forDelegate:self] ) {
        //handle error
    }
}
- (void)fetchMoments: (NSString *)username {
    //Fetch JSON
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
    
    return slug;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(displayInsert)]];
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
        
        rect = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 280, 202)];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"textCell"];
        NSArray *subviews = cell.contentView.subviews;
        [[subviews objectAtIndex:0] setText:[[_items objectAtIndex:row] valueForKey:@"content"]];
        [[subviews objectAtIndex:1] setText:[[_items objectAtIndex:row] valueForKey:@"title"]];
        
        rect = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 280, 102)];
    }
    [rect setBackgroundColor:[UIColor whiteColor]];
    [cell insertSubview:rect atIndex:0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end
