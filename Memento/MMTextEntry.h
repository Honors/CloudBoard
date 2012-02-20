//
//  MMTextEntry.h
//  Memento
//
//  Created by Matt Neary on 2/19/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMInsertSheet.h"

@interface MMTextEntry : UIViewController {
    IBOutlet UITextView *textview;
}
    @property (strong, nonatomic) MMInsertSheet *delegate;
    - (void)exit;
@end
