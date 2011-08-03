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
#import "JSON.h"

@interface RootViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation RootViewController

@synthesize fetchedResultsController=__fetchedResultsController;
@synthesize managedObjectContext=__managedObjectContext;

int popOutBool = 0;
int popOutSlot = -1;

- (void)loginSubmitButton {
    NSLog(@"RootView was reached");
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)viewItemClick {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *type = [[managedObject valueForKey:@"type"] description];
    NSString *contents = [[managedObject valueForKey:@"contents"] description];
    
    TextDetailViewController *tdvc = [[TextDetailViewController alloc]initWithNibName:@"TextDetailView" bundle:[NSBundle mainBundle]];    
    [self presentModalViewController:tdvc animated:YES];
    [tdvc initWithLink:@"google" andContents:contents];
    [tdvc release];    
}

- (IBAction)shareItemClick {
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:@"Subject Goes Here."];
        [mailViewController setMessageBody:@"Your message goes here." isHTML:NO];
        [self presentModalViewController:mailViewController animated:YES];
        [mailViewController release];
        
    }
    
    else {
        
        NSLog(@"Device is unable to send email in its current state.");
        
    }   
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void)getClip {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSString *string;
    
    if( pasteboard.string ) {
        string = pasteboard.string;
        
        [self insertNewObject:string ofType:@"string"];
    }
    else if( pasteboard.image ) {
        //UIImage *image = pasteboard.image;
        NSArray *images = pasteboard.images;
        int count = 0;
        for( UIImage *image in images ) {
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
}

-(NSString *)urlencode: (NSString *)url {
    NSArray *escapeChars  = [NSArray arrayWithObjects:
                             @";" , @"/" , @"?" , @":" ,
                             @"@" , @"&" , @"=" , @"+" ,
                             @"$" , @"," , @"[" , @"]" ,
                             @"#" , @"!" , @"'" , @"(" , 
                             @")" , @"*" , @" ", @"\"", nil];
    
    NSArray *replaceChars = [NSArray arrayWithObjects:
                             @"%3B" , @"%2F" , @"%3F" ,
                             @"%3A" , @"%40" , @"%26" ,
                             @"%3D" , @"%2B" , @"%24" ,
                             @"%2C" , @"%5B" , @"%5D" , 
                             @"%23" , @"%21" , @"%27" ,
                             @"%28" , @"%29" , @"%2A" ,
                             @"%20" , @"%22" , nil];    
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
                             options:nil
                               range:NSMakeRange(0, [temp length])];
    
    NSString *out = [NSString stringWithString: temp];    
    [temp release];
    //NSLog(@"Encoded Clip: %@", out);
    return out;
}

-(BOOL)retreiveDataviaPredicate: (long long)timePassed withContent:(NSString *)contentSend
{
    NSFetchRequest *fetchReq = [[NSFetchRequest alloc]init];
    
    //setting the predicate format so that we can get the child name by supplying the mother name
    
    NSDate *matchDate = [NSDate dateWithTimeIntervalSince1970:timePassed];
    NSPredicate *query = [NSPredicate predicateWithFormat:@"(timeStamp = %@) AND (contents CONTAINS[cd] %@)", matchDate, contentSend];
    
    //setting the predicate to the fetch request 
    [fetchReq setPredicate:query];
    
    [fetchReq setEntity:[NSEntityDescription entityForName:@"Clips" inManagedObjectContext:self.managedObjectContext]];
    
    NSError *err = nil;
    NSArray *resp = [self.managedObjectContext executeFetchRequest:fetchReq error:&err];   
    NSMutableArray *resultArray = [[NSMutableArray alloc]initWithArray:resp];
    
    return [resultArray count] > 0 && !err ? YES : NO;
}

-(void)downloadClips {
    //This needs a revamp. What if I make a new clip without syncing? Instead loop through newest ten (on server) and see if you need em.
    //Make it similar to uploadClips        
    NSLog(@"It's me");
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    
    //Get newest 10 time from php file
    NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/whatsnew.php?user=%@", @"test"];    
    NSURL *urlRequest = [NSURL URLWithString:url];
    NSError *err = nil;
    
    NSString *html = [NSString stringWithContentsOfURL:urlRequest encoding:NSUTF8StringEncoding error:&err];          
    NSLog(@"HTML: %@", html);
    
    if(err || !html)   
        return;
    
    //Cycle through the newest clips
    NSArray *data = [parser objectWithString:html];        
    for( int i = 0; i < [data count]; i++ ) {
        NSDictionary *row = [data objectAtIndex:i];            
        NSString *timeRead = [row objectForKey:@"timestamp"];
        NSString *contentRead = [row objectForKey:@"content"];
        long long timePassed = [timeRead longLongValue];            
        NSDate *timeStamepDate = [NSDate dateWithTimeIntervalSince1970:timePassed];
        
        //On server-side make content slug
        //Make the content a full url string (If image)                
        
        BOOL doContain = [self retreiveDataviaPredicate:timePassed withContent:contentRead];
        NSLog(@"I have it: %u", doContain);
        if  ( !doContain )
            [self insertNewObject:[row objectForKey:@"content"] ofType:[row objectForKey:@"type"] withTime:timeStamepDate];
    } 
    
    //Download the Image
    //save image with slug name
    
    //[parser release];
}

-(void)uploadClips {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
    int count = [sectionInfo numberOfObjects];
    
    //SBJsonWriter *encoder = [[SBJsonWriter alloc] init];
    
    for( int i = 0; i < (count>10?10:count); i++ ) {
        
        SBJsonWriter *encoder = [[SBJsonWriter alloc] init];
        
        //Prepare time
        NSManagedObject *mo = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        
        //Prepare data
        NSString *type = [[mo valueForKey:@"type"] description];
        NSString *contents = [[mo valueForKey:@"contents"] description];     
        NSString *time = [[mo valueForKey:@"timeStamp"] description];
        
        //Prepare timestamp for comparison
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];        
        
        NSDate *theDate = nil;
        NSError *error = nil;         
        if (![df getObjectValue:&theDate forString:time range:nil error:&error]) {
            NSLog(@"Date '%@' could not be parsed: %@", time, error);
        }[df release];
        
        NSTimeInterval oldTime = [theDate timeIntervalSince1970];
        NSString *unixTime = [[NSString alloc] initWithFormat:@"%0.0f", oldTime];
        
        NSLog(@"Time: %@ aka %@", time, unixTime);
        
        //Prep contents for GET transfer
        NSString *verify = @"";
        if( [contents length]-1>15 )
            verify = [contents substringToIndex:15];
        else
            verify = contents;
        
        //Check if it's needed
        NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/didYouGetThis.php?user=%@&time=%@&content=%@", @"test", unixTime, [self urlencode:verify]];
        NSURL *urlRequest = [NSURL URLWithString:url];
        NSError *err = nil;
        
        NSString *html = [NSString stringWithContentsOfURL:urlRequest encoding:NSUTF8StringEncoding error:&err];          
        
        NSLog(@"HTML (needed): %@", html);
        //[urlRequest release];
        
        if( [html isEqualToString:@"NeedIt"] && [self validateLoginSubmit] ) {                          
            NSDictionary *row = [[NSDictionary alloc] initWithObjectsAndKeys:type, @"type", contents, @"contents", unixTime, @"timeStamp", nil];
            NSString *jsonData = [encoder stringWithObject:row];            
            NSString *jsonDataE = [self urlencode:jsonData];
            NSMutableString *jsonMute = [jsonDataE mutableCopy];
            //[jsonMute replaceOccurrencesOfString:@"{" withString:@"" options:nil range:NSMakeRange(0, [jsonMute length])];
            //[jsonMute replaceOccurrencesOfString:@"}" withString:@"" options:nil range:NSMakeRange(0, [jsonMute length])];
            
            //Upload Image 
            /*
             ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:url] autorelease];
             [request setPostValue:@"Ben" forKey:@"first_name"];
             [request setPostValue:@"Copsey" forKey:@"last_name"];
             [request setFile:@"/Users/ben/Desktop/ben.jpg" forKey:@"photo"];
             
             http://stackoverflow.com/questions/936855/file-upload-to-http-server-in-iphone-programming
             */
            
            //Upload Data (with slug from image upload)
            NSString *url = [NSString stringWithFormat:@"http://mneary.info/APIs/u/submitJSON.php?user=%@", @"test"];
            //NSLog(@"URL for Upload: %@", url);
            
            //[[NSURLDownload alloc] initWithRequest:request delegate:self];
            
            /*NSString *testPart = [url substringToIndex:[url length]>40?40:[url length]];
             NSURL *urlRequest = [NSURL URLWithString:testPart];
             [testPart release];
             NSLog(@"URL (truncate?): %@", urlRequest);
             NSError *err = nil;*/
            
            NSString *post = [NSString stringWithFormat:@"jdata=%@",jsonMute]; 
            //NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
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
            
            //NSString *html = [NSString stringWithContentsOfURL:urlRequest encoding:NSUTF8StringEncoding error:&err]; 
            NSString *html = response;
            //NSLog(@"Post: %@", post);
            //NSString *html = [NSString stringWithContentsOfURL:[request] encoding:NSUTF8StringEncoding error:&err];
            /*[jsonData release];
             [jsonDataE release];
             [jsonMute release];
             [unixTime release];
             [encoder release];*/
            if( err )
                NSLog(@"FAIL!!!!! %@ (%@)", err, [err userInfo]);
            //else
            //NSLog(@"HTML (upload): %@", html);                       
        }
        /*else {
         break;
         } */  
        [unixTime release];       
    }    
}

- (void)delegateSync {
    [self uploadClips];
    [self downloadClips];
}

- (BOOL)validateLoginSubmit {
    
    NSURL *url = [NSURL URLWithString:  
                  [NSString stringWithFormat:@"http://mneary.info/u/validLogin.php?user=%@&password=%@", @"test", @"dr0wssap"               
                   ]];
    
    NSError *err = nil;    
    NSString *html = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
    
    NSLog(@"Response: %@", html);
    
    if ([html isEqualToString:@"valid"])        
        return true;    
    return false;                
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    LoginViewController *lvc = [[LoginViewController alloc]initWithNibName:@"LoginView" bundle:[NSBundle mainBundle]];    
    [self presentModalViewController:lvc animated:YES];
    
    [lvc release];
    
    // Set up the edit and add buttons.
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(getClip)];
    
    UIBarButtonItem *syncButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(delegateSync)];
    self.navigationItem.leftBarButtonItem = syncButton;
    
    self.navigationItem.rightBarButtonItem = addButton;
    myTableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"noise.png"]];
    
    [addButton release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 //return (interfaceOrientation == UIInterfaceOrientationPortrait);
     return YES;
 }
 

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count] ;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects] + (popOutSlot != -1 ? 1 : 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [indexPath row] == popOutSlot ? 70 : 140;
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

/*
 - (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
 // return ;
 }*/

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    //}
    
    // Configure the cell.
    //[self configureCell:cell atIndexPath:indexPath];        
    
    NSString *contents = @"";
    NSString *type = @"";
    int row = [indexPath row];
    
    //Choose appropriate item from array
    if( row < popOutSlot || popOutSlot == -1 ) {
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
        type = [[managedObject valueForKey:@"type"] description];
        contents = [[managedObject valueForKey:@"contents"] description];
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
    }
    
    if( [type isEqualToString:@"string"] && row != popOutSlot ) {
        /*UILabel *myLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 38, 198, 44)];            
         [myLabel setText:contents];*/        
        UIView *temp = [[[NSBundle mainBundle] loadNibNamed:@"textView" owner:nil options:nil] objectAtIndex:0];
        UITextView *textView = [[temp subviews] objectAtIndex:0];
        //UITextView *tempText = notePadTextView;
        
        [textView setText:contents];
        [temp setBounds:CGRectMake(-15, -10, 267, 120)];        
        [cell.contentView addSubview:temp]; 
        
        //notePad = temp;
        //notePadTextView = tempText;
        
        UIView *mask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 267, 120)];
        [cell.contentView addSubview:mask];
        //cell.textLabel.text = contents;
    }       
    else if( contents && row != popOutSlot ) {    //if( [type isEqualToString:@"image"] )                
        NSString *path = contents;
        UIImage *thePic = [UIImage imageWithContentsOfFile:path];
        CGSize picSize = [thePic size];
        
        CGFloat scaleWidth = picSize.width/237;
        CGFloat scaleHeight = picSize.height/94;
        CGFloat scale = scaleHeight < scaleWidth ? scaleHeight : scaleWidth;   
        
        UIView *backer = [[UIView alloc] initWithFrame:CGRectMake(15, 20, 267, 100)];
        [backer setBackgroundColor:[UIColor blackColor]];
        [cell.contentView addSubview:backer];
        
        UIImageView *imageViewForCell;
        UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(26, 24, 237, 94)];
        if(scaleWidth && scaleHeight) {
            imageViewForCell = [[UIImageView alloc] initWithFrame:CGRectMake((267-1/scale*picSize.width)/2, -6, 1/scale*picSize.width, 1/scale*picSize.height)];
            [scroll addSubview:imageViewForCell];            
            scroll.contentSize = CGSizeMake(1/scale*picSize.width, 1/scale*picSize.height);
            /*scroll.minimumZoomScale = 247 / (218-1/scale*picSize.width)/2 + 21;
             scroll.maximumZoomScale = 2.0;
             [scroll setZoomScale:scroll.minimumZoomScale];*/
            scroll.scrollEnabled = NO;
        }
        else 
            imageViewForCell = [[UIImageView alloc] initWithFrame:CGRectMake(26, 24, 198, 94)];
        [imageViewForCell setBackgroundColor:[UIColor blackColor]];
        
        [imageViewForCell setImage:thePic];
        
        UIImageView *frame = [[UIImageView alloc] initWithFrame:CGRectMake( 15, 13, 267, 120)];        
        [frame setImage:[UIImage imageNamed:@"polaroidFrame.png"]];        
        //dataCellFrame.png
        
        UIView *mask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 140)];
        
        //[imageCell insertSubview:imageViewForCell belowSubview:imageTriangle];
        [cell.contentView addSubview:scroll];            //imageViewForCell
        [cell.contentView addSubview:frame];
        [cell.contentView addSubview:mask];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    /*
     UIImageView *bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 120)];
     [bg  setImage:[UIImage imageNamed:@"backgroundCell.png"]];
     [cell setBackgroundView:bg];
     */
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone; 
    
    return cell;
}


// Override to support conditional editing of the table view.
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
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    if( popOutSlot-1 != indexPath.row ) {
        int rowSlot = indexPath.row+1;        
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
    else {
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

- (void)insertNewObject: (NSString *)contents ofType:(NSString *)type withTime:(NSDate *)timestamp
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
	    /*
	     Replace this implementation with code to handle the error appropriately.
         
	     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
	     */
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
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

@end
