//
//  PogUIPageControlDots.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogUIPageControlDots.h"

@implementation PogUIPageControlDots

#pragma mark - properties
- (unsigned int) curPage
{
    return _curPage;
}

- (void) setCurPage:(unsigned int)curPage
{
    // clear the red dot from previous curPage
    UIImageView* prevDot = [_pageDots objectAtIndex:_curPage];
    prevDot.image = _circle;
    
    // update current page
    unsigned int value = curPage;
    if(value >= _numPages)
    {
        value = _numPages - 1;
    }
    _curPage = value;
    
    // set the red dot for the new curPage
    UIImageView* newDot = [_pageDots objectAtIndex:_curPage];
    newDot.image = _circleRed;
}


#pragma mark - init / shutdown

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        _pageDots = [[NSMutableArray array] retain];
        _numPages = 3;
        _curPage = 1;
        
        // load image resources
        _circle = [[UIImage imageNamed:@"pageControl_Circle.png"] retain];
        _circleRed = [[UIImage imageNamed:@"pageControl_CircleRed.png"] retain];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        _pageDots = [[NSMutableArray array] retain];
        _numPages = 3;
        _curPage = 1;
        
        // load image resources
        _circle = [[UIImage imageNamed:@"pageControl_Circle.png"] retain];
        _circleRed = [[UIImage imageNamed:@"pageControl_CircleRed.png"] retain];
    }
    return self;
}

- (void) dealloc
{
    for(UIImageView* cur in _pageDots)
    {
        [cur removeFromSuperview];
    }
    [_pageDots release];
    
    [_circle release];
    [_circleRed release];
    [super dealloc];
}

#pragma mark - layout functions
- (void) setupWithNumPages:(unsigned int)numPages
{
    _numPages = numPages;
    for(UIImageView* cur in _pageDots)
    {
        [cur removeFromSuperview];
    }
    [_pageDots removeAllObjects];
    
    float height = self.frame.size.height;
    float width = height;
    float spacing = (self.frame.size.width - (_numPages * width)) / (_numPages + 1);
    
    float x = spacing;
    for(unsigned int i = 0; i < _numPages; ++i)
    {
        CGRect myFrame = CGRectMake(x, 0.0f, width, height);
        UIImageView* curDot = [[UIImageView alloc] initWithFrame:myFrame];
        if(i == _curPage)
        {
            curDot.image = _circleRed;
        }
        else
        {
            curDot.image = _circle;
        }
        [_pageDots addObject:curDot];
        [curDot release];
        
        x += (spacing + width);
    }
    
    // add all the dots as subviews
    for(UIImageView* cur in _pageDots)
    {
        [self addSubview:cur];
    }
}


@end
