//
//  PogUISlotBar.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/27/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogUISlotBar.h"

static const CGFloat SLOTSPACING = 1.0f;

@interface PogUISlotBar (PrivateMethods)
- (void) initWithNumSlots:(unsigned int)numSlots;
- (void) setColors;
@end

@implementation PogUISlotBar
@synthesize fillColor = _fillColor;
@synthesize outlineColor = _outlineColor;
@synthesize slotSpacing = _slotSpacing;
@synthesize outFrameInset = _outFrameInset;
@synthesize fillFrameInset = _fillFrameInset;
@synthesize outlineWidth = _outlineWidth;

#pragma mark - properties
@synthesize numFilled = _numFilled;

- (unsigned int) numSlots
{
    return _numSlots;
}

- (void) setNumSlots:(unsigned int)numSlots
{
    unsigned int newNum = numSlots;
    if(newNum == 0)
    {
        // at least one slot
        newNum = 1;
    }
    
    if(_numFilled > newNum)
    {
        // clamp numFilled to max at the new number of slots
        _numFilled = newNum;
    }
    _numSlots = newNum;
}

#pragma mark - private methods
- (void) initWithNumSlots:(unsigned int)numSlots
{
    _numSlots = numSlots;
    _numFilled = 0;
    
    // default colors
    _fillColor = [[UIColor colorWithRed:(212.0f/255.0f) green:(12.0f/255.0f) blue:(12.0f/255.0f) alpha:1.0f] retain];
    _outlineColor = [[UIColor colorWithRed:(147.0f/255.0f) green:(158.0f/255.0f) blue:(158.0f/255.0f) alpha:0.5f] retain];
    _slotSpacing = SLOTSPACING;
    _outFrameInset = 0.5f;
    _fillFrameInset = 1.75f;
    _outlineWidth = 1.5f;
}

- (void) setColors
{
    [_outlineColor setStroke];
    [_fillColor setFill];
}


#pragma mark - public methods

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self initWithNumSlots:1];
        _orientation = PogUISlotBarOrientationHorizontal;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame numSlots:(unsigned int)numSlots
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        [self initWithNumSlots:numSlots];
        _orientation = PogUISlotBarOrientationHorizontal;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame numSlots:(unsigned int)numSlots orientation:(PogUISlotBarOrientation)orientation
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        [self initWithNumSlots:numSlots];
        _orientation = orientation;
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self initWithNumSlots:3];
        
        // make some guesses here; if the width is longer than the height, it's horizontal;
        // otherwise, it's vertical
        if(self.bounds.size.width > self.bounds.size.height)
        {
            _orientation = PogUISlotBarOrientationHorizontal;
        }
        else
        {
            _orientation = PogUISlotBarOrientationVertical;
        }
    }
    return self;
}


- (void) dealloc
{
    [_fillColor release];
    [_outlineColor release];
    [super dealloc];
}

- (void) drawSlotWithRect:(CGRect)rect isFilled:(BOOL)isFilled
{
    CGRect curOutFrame = CGRectInset(rect, _outFrameInset, _outFrameInset);
    CGRect curFill = CGRectInset(rect, _fillFrameInset, _fillFrameInset);
    UIRectFrame(curOutFrame);
    if(isFilled)
    {
        UIRectFill(curFill);
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    // frame for slot filler
    CGContextSetLineWidth(context, _outlineWidth);
    
    // set color
    [self setColors];

    // draw the slots
    CGRect myFrame = [self bounds];
    
    if(PogUISlotBarOrientationVertical == _orientation)
    {
        // vertical
        CGFloat slotWidth = myFrame.size.width;
        CGFloat slotHeight = floorf((myFrame.size.height - ((_numSlots+1) * _slotSpacing)) / _numSlots);
        for(unsigned int i = 0; i < _numSlots; ++i)
        {
            float curOffset = _slotSpacing + ((_numSlots-i-1) * (_slotSpacing + slotHeight));
            CGRect curFrame = CGRectMake(0.0f, curOffset, slotWidth, slotHeight);
            BOOL isFilled = (i < _numFilled);
            [self drawSlotWithRect:curFrame isFilled:isFilled];
        }
    }
    else
    {
        // default horizontal
        CGFloat slotWidth = floorf((myFrame.size.width - ((_numSlots+1) * _slotSpacing)) / _numSlots);
        CGFloat slotHeight = myFrame.size.height;
        
        for(unsigned int i = 0; i < _numSlots; ++i)
        {
            float curOffset = _slotSpacing + (i * (_slotSpacing + slotWidth));
            CGRect curFrame = CGRectMake(curOffset, 0.0f, slotWidth, slotHeight);
            BOOL isFilled = (i < _numFilled);
            [self drawSlotWithRect:curFrame isFilled:isFilled];
        }
    }
}

#pragma mark - public accessors
- (void) setFillColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    self.fillColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (void) setOutlineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    self.outlineColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}


@end
