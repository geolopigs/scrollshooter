//
//  MovieWebView.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/23/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "MovieWebView.h"
#import <QuartzCore/QuartzCore.h>

@interface MovieWebView()
- (void) createComponents;
@end

@implementation MovieWebView
@synthesize indicator = _indicator;

- (void) createComponents
{
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    float indicatorW = _indicator.frame.size.width;
    float indicatorH = _indicator.frame.size.height;
    float indicatorX = 0.5f * (self.frame.size.width - indicatorW);
    float indicatorY = 0.5f * (self.frame.size.height - indicatorH);
    [_indicator setFrame:CGRectMake(indicatorX, indicatorY, indicatorW, indicatorH)];
    [_indicator setHidesWhenStopped:YES];
    [_indicator setOpaque:NO];
    [_indicator setBackgroundColor:[UIColor clearColor]];
    [self addSubview:_indicator];
    
    [[self layer] setCornerRadius:8.0f];
    [[self layer] setMasksToBounds:YES];
    //[[self layer] setBorderWidth:3.0f];
    //[[self layer] setBorderColor:[[UIColor whiteColor] CGColor]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self createComponents];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        [self createComponents];
    }
    return self;
}

- (void) dealloc
{
    [_indicator removeFromSuperview];
    [_indicator release];
    [super dealloc];
}

- (void) loadYouTubeURLString:(NSString *)urlString
{
    float frameWidth = self.frame.size.width;
    float frameHeight = self.frame.size.height;
/*    
    NSString* embedHTML = @"<html><head>\
        <body bgcolor=\"#000000\" style=\"margin:0\">\
        <iframe width=\"%0.0f\" height=\"%0.0f\" src=\"%@?rel=0\" frameborder=\"0\" allowfullscreen></iframe>\
        </body></html>";
 */

    NSString* embedHTML = @"<html><head>\
    <body style=\"margin:0\">\
    <embed id=\"yt\" src=\"%@\" \
    width=\"%0.0f\" height=\"%0.0f\" type=\"application/x-shockwave-flash\"></embed>\
    </body></html>";

//    NSString* html = [NSString stringWithFormat:embedHTML, frameWidth, frameHeight, urlString];
    NSString* html = [NSString stringWithFormat:embedHTML, urlString, frameWidth, frameHeight];
    
    [self loadHTMLString:html baseURL:nil];
    //[self setOpaque:NO];
    //[self setBackgroundColor:[UIColor blackColor]];
}


@end
