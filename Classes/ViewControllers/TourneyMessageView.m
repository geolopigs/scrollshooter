//
//  TourneyMessageView.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TourneyMessageView.h"
#import <QuartzCore/QuartzCore.h>

@interface TourneyMessageView (PrivateMethods)
- (void) setupFrame;
- (void) setupContent;
@end

@implementation TourneyMessageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        [self setupFrame];
        [self setupContent];
    }
    return self;
}

- (void) dealloc
{
    [_icon removeFromSuperview];
    [_icon release];
    [_message removeFromSuperview];
    [_message release];
    [_backScrim removeFromSuperview];
    [_backScrim release];
    [super dealloc];
}

#pragma mark - layout
- (void) setupFrame
{
    // set my background
    [self setBackgroundColor:[UIColor clearColor]];
    
    // setup background scrim
    CGRect scrimFrame = CGRectInset([self bounds], 0.9f, 0.9f);
    _backScrim = [[UIView alloc] initWithFrame:scrimFrame];
    [[_backScrim layer] setCornerRadius:1.0f];
    [[_backScrim layer] setMasksToBounds:YES];
    [[_backScrim layer] setBorderWidth:0.5f];
    [[_backScrim layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [_backScrim setBackgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f]];
    [self addSubview:_backScrim];
    
    // setup my border
    [[self layer] setCornerRadius:4.0f];
    [[self layer] setMasksToBounds:YES];
    [[self layer] setBorderWidth:1.5f];
    [[self layer] setBorderColor:[[UIColor whiteColor] CGColor]];
}

- (void) setupContent
{
    CGFloat fontSize = 16.0f;
    CGFloat iconX = 0.013f * [self bounds].size.width;
    CGFloat iconY = 0.018f * [self bounds].size.width;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        fontSize =24.0f;
        iconY = 0.008f * [self bounds].size.width;
    }

    CGFloat iconWidth = 0.15f * [self bounds].size.width;
    CGFloat iconHeight = iconWidth;
    _icon = [[UIImageView alloc] initWithFrame:CGRectMake(iconX, iconY, iconWidth, iconHeight)];
    [self addSubview:_icon];
    CGRect labelFrame = CGRectInset([self bounds], 2.0f, 0.0f);
    CGFloat labelX = iconX + (1.05f * iconWidth);
    CGFloat labelWidth = labelFrame.size.width - iconWidth;
    labelFrame.origin.x = labelX;
    labelFrame.size.width = labelWidth;
    _message = [[UILabel alloc] initWithFrame:labelFrame];
    [_message setNumberOfLines:2];
    [_message setFont:[UIFont fontWithName:@"Helvetica" size:fontSize]];
    
    [_message setTextColor:[UIColor whiteColor]];
    [_message setBackgroundColor:[UIColor clearColor]];
    [_message setTextAlignment:NSTextAlignmentLeft];
    [self addSubview:_message];
}

#pragma mark - accessors
- (void) setMessageText:(NSString *)text
{
    [_message setText:text];
}

- (void) setIconImage:(UIImage *)image
{
    [_icon setImage:image];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
