//
//  PogUIAchievementMessage.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogUIAchievementMessage.h"
#import <QuartzCore/QuartzCore.h>

@interface PogUIAchievementMessage ()
{
    UIView* _contentView;
    UIImageView* _icon;
    UILabel* _message;
}
@end

@implementation PogUIAchievementMessage

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        // create a round border
        [[self layer] setCornerRadius:4.0f];
        [[self layer] setMasksToBounds:YES];
        [[self layer] setBorderWidth:2.0f];
        [[self layer] setBorderColor:[[UIColor whiteColor] CGColor]];
        
        CGRect contentRect = CGRectInset(CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height), 2.0f,2.0f);
        _contentView = [[UIView alloc] initWithFrame:contentRect];
        [_contentView setBackgroundColor:[UIColor colorWithRed:240.0f/255.0f green:130.0f/255.0f blue:26.0f/255.0f alpha:0.85f]];
        
        CGFloat contentWidth = contentRect.size.width;
        CGFloat contentHeight = contentRect.size.height;
        CGRect iconRect = CGRectMake(0.0f, 0.0f, contentHeight, contentHeight);
        _icon = [[UIImageView alloc] initWithFrame:CGRectInset(iconRect, 1.0f, 1.0f)];
        [_icon setBackgroundColor:[UIColor clearColor]];
        
        CGRect messageRect = CGRectMake(iconRect.origin.x + iconRect.size.width, 0.0f, 
                                        contentWidth - iconRect.size.width - iconRect.origin.x, contentHeight);
        _message = [[UILabel alloc] initWithFrame:messageRect];
        [_message setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14.0f]];
        [_message setTextColor:[UIColor colorWithRed:0.9f green:0.95f blue:1.0f alpha:1.0f]];
        [_message setBackgroundColor:[UIColor clearColor]];
        [_message setNumberOfLines:2];
        [_message setTextAlignment:NSTextAlignmentLeft];
        [_message setShadowColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.1f alpha:1.0f]];
        [_message setShadowOffset:CGSizeMake(1.0f, 1.0f)];
        
        [self addSubview:_contentView];
        [_contentView addSubview:_icon];
        [_contentView addSubview:_message];
    }
    return self;
}

- (void) dealloc
{
    [_icon removeFromSuperview];
    [_icon release];
    [_message removeFromSuperview];
    [_message release];
    [_contentView removeFromSuperview];
    [_contentView release];
    [super dealloc];
}


#pragma mark - accessors
- (void) setImage:(UIImage *)image
{
    _icon.image = image;
}

- (void) setMessageText:(NSString *)messageText
{
    [_message setText:messageText];
}

@end
