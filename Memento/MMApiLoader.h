//
//  MMApiLoader.h
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMMasterViewController.h"

@interface MMApiLoader : NSObject {
    NSMutableData *respData;
}
    @property (strong, nonatomic) MMMasterViewController *delegate;
    @property (strong, nonatomic) NSString *_mode;

    - (MMApiLoader *)initWithMode: (NSString *)mode;
@end
