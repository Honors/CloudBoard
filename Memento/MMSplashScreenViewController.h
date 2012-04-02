//
//  MMSplashScreenViewController.h
//  Memento
//
//  Created by Matt Neary on 2/25/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMRegisterViewController.h"

@interface MMSplashScreenViewController : UIViewController {
    IBOutlet UIProgressView *load;
}
@property (strong, nonatomic) MMRegisterViewController *delegate;
@end
