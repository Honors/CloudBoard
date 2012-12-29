//
//  MMApiLoader.h
//  Memento
//
//  Created by Matt Neary on 2/18/12.
//  Copyright (c) 2012 OmniVerse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHGradesViewController.h"

@interface BHApiLoader : NSObject {
    NSMutableData *respData;
}
@property (strong, nonatomic) BHGradesViewController *delegate;

- (BHApiLoader *)init;
@end