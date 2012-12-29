//
//  MMDetailViewController.h
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMDetailViewController : UIViewController {
    IBOutlet UIScrollView *sv;
}

@property (strong, nonatomic) NSDictionary *detailItem;

@property (strong, nonatomic) IBOutlet UITextView *detailText;
@property (strong, nonatomic) IBOutlet UIImageView *detailImg;

@end
