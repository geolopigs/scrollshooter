//
//  MovieWebView.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/23/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MovieWebView : UIWebView
{
    UIActivityIndicatorView* _indicator;
}
@property (nonatomic,retain) UIActivityIndicatorView* indicator;
- (void) loadYouTubeURLString:(NSString*)urlString;
@end
