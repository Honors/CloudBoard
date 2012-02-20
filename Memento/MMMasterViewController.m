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

@implementation MMMasterViewController
@synthesize _items;

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
    
    NSURL *mneary = [[NSURL alloc] initWithString:@"http://mneary.info:3001/api/save/"];
    NSMutableURLRequest *putJSON = [[NSMutableURLRequest alloc] initWithURL:mneary];
    NSString *params = @"title=%@&username=%@&content=%@&timestamp=%@&link=%@&type=%@";
    NSString *myParameters = [[NSString alloc] initWithFormat:params, 
                                    title, 
                                    @"matt", 
                                    content, 
                                    @"18-2-12", 
                                    slug, 
                                    type];
    
    [putJSON setHTTPMethod:@"POST"];
    [putJSON setHTTPBody:[myParameters dataUsingEncoding:NSUTF8StringEncoding]];
    MMApiLoader *mmal = [[MMApiLoader alloc] initWithMode: @"PUT"];
    mmal.delegate = self;
    
    NSURLConnection *api_load = [[NSURLConnection alloc] initWithRequest:putJSON delegate:mmal];            
    if( !api_load ) {
        //throw error
    }
}
- (void)fetchMoments {
    //Fetch JSON
    NSURL *mneary = [[NSURL alloc] initWithString:@"http://mneary.info:3001/api/load/"];
    NSMutableURLRequest *getJSON = [[NSMutableURLRequest alloc] initWithURL:mneary];
    
    [getJSON setHTTPMethod:@"GET"];
    MMApiLoader *mmal = [[MMApiLoader alloc] initWithMode:@"GET"];
    mmal.delegate = self;
    
    NSURLConnection *api_load = [[NSURLConnection alloc] initWithRequest:getJSON delegate:mmal]; 
    if( !api_load ) {
        //throw error
    }
}
- (void)displayInsert {
    //Display Modal insert form
    MMInsertSheet *mmis = [[self storyboard] instantiateViewControllerWithIdentifier:@"InsertSheet"];
    mmis.delegate = self;
    [self.navigationController pushViewController:mmis animated:YES];
//    [self.navigationController presentModalViewController:mmis animated:YES]; //Modal
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
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"Error %@", error);
}

- (NSString *)uploadImageWithData: (NSData *)data {
    NSURL *url = [NSURL URLWithString:@"http://mneary.info:3008/api/upload/"];
    NSString *slug = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://mneary.info:3001/api/load/nextslug"]];

    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setData:data withFileName:[slug stringByAppendingString:@".png"] andContentType:@"image/png" forKey:@"photo"];    
    [request setDelegate:self];
    [request startAsynchronous];
    
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
    [self fetchMoments];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.tableView.tableFooterView = view;
    [self.tableView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]]];
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
    } else {          
        cell = [tableView dequeueReusableCellWithIdentifier:@"textCell"];                
        UIView *rect;
        if( _items ) {
            NSString *type = [[_items objectAtIndex:row] valueForKey:@"type"];
            if( [type isEqualToString:@"image"] ) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell"];
                NSArray *subviews = cell.contentView.subviews;
                
                NSArray *sysPaths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
                NSString *docDirectory = [sysPaths objectAtIndex:0];
                
                //File path is slug
                NSString *slug = [[_items objectAtIndex:row] valueForKey:@"link"];
                NSString *filePath = [NSString stringWithFormat:@"%@/%@.png", docDirectory, slug];    
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];                
                if( fileExists )
                    [[subviews objectAtIndex:0] setImage:[[UIImage alloc] initWithContentsOfFile:filePath]];
                else {
                    //download file
                    ASIHTTPRequest *request;
                    request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://mneary.info:3001/public/%@.png", slug]]];
                    [request setDownloadDestinationPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", slug]]];

                    NSLog(@"Downloading %@", slug);
                    [request setCompletionBlock:^{
                        NSLog(@"File Downloaded");
                        [self.tableView reloadData];
                    }];
                    [request startAsynchronous];
                }
                
                rect = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 280, 202)];
            }
            else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"textCell"];
                NSArray *subviews = cell.contentView.subviews;
                [[subviews objectAtIndex:0] setText:[[_items objectAtIndex:row] valueForKey:@"content"]];
                [[subviews objectAtIndex:1] setText:[[_items objectAtIndex:row] valueForKey:@"title"]];
                
                rect = [[UIView alloc] initWithFrame:CGRectMake(40, 0, 280, 102)];
            }
        }  
        [rect setBackgroundColor:[UIColor whiteColor]];
        [cell insertSubview:rect atIndex:0];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end
