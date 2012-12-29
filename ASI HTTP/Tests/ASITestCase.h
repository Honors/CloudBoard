//
//  ASITestCase.h
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 26/07/2009.
//  Copyright 2009 All-Seeing Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GHUnitIOS/GHUnit.h>

@interface ASITestCase : NSObject {
}
- (NSString *)filePathForTemporaryTestFiles;
@end
