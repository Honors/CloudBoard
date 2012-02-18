//
//  MMDetailViewController.h
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
