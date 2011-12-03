//
//  TextDetailViewController.m
//  cliplogr
//
//  Created by Matt on 7/27/11.
//  Copyright 2011 St. Timothy. All rights reserved.
//

#import "ImageDetailViewController.h"

UIImageView *image;

@implementation ImageDetailViewController
    
    - (void)viewDidLoad {        
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood.jpeg"]];
    }

    - (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
        return image;
    }

    - (void)initWithLink: (NSString*)link andContents: (NSString*)content {
        //[textContents setText:content];
        //[textLink setText:link];
        UIImage *read = [UIImage imageWithContentsOfFile:content];
        //[imageContents setImage:read];
        [imageLink setText:link];
                   
        UIScrollView *scroll = imageScroll;
        //scroll.backgroundColor = [UIColor blackColor];
        scroll.backgroundColor = [UIColor colorWithRed:.69 green:.84 blue:.89 alpha:1];
        scroll.delegate = self;
        image = [[UIImageView alloc] initWithImage:read];        
        scroll.contentSize = image.frame.size;
        [scroll addSubview:image];
        scroll.minimumZoomScale = scroll.frame.size.width / image.frame.size.width;
        scroll.maximumZoomScale = 2.0;
        if((scroll.frame.size.height / image.frame.size.height)>(scroll.frame.size.width / image.frame.size.width)) {
            [scroll setZoomScale:(scroll.frame.size.width / image.frame.size.width)];
            //NOTE: this is center not top right
            [image setCenter:CGPointMake(image.frame.size.width/2, (scroll.frame.size.height-image.frame.size.height)/2+image.frame.size.height/2)];
        }
        else {
            [scroll setZoomScale:(scroll.frame.size.height / image.frame.size.height)];
            [image setCenter:CGPointMake((scroll.frame.size.width-image.frame.size.width)/2+image.frame.size.width/2, image.frame.size.height/2)];
        }
        //self.view = scroll;
        [scroll release];
    }
    - (IBAction)editCloseButton {        
        [self dismissModalViewControllerAnimated:YES];
    }
    - (IBAction)editSaveButton {
        
    }

@end
