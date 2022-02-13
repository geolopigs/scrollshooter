//
//  PanController.mm
//  Curry
//
//  Created by Shu Chiun Cheah on 6/27/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "PanController.h"
#import "GameManager.h"
#include "MathUtils.h"


@interface PanController(PanControllerPrivate)
- (CGPoint) calcTranslationPointA:(CGPoint)pointA pointB:(CGPoint)pointB;
@end

@implementation PanController
// multiply this with view-width to get max pan displacement
// this is based on a max of 40 for view-width 320
static const float PAN_DISPLACEMENT_FACTOR = (40.0f/320.0f);

@synthesize curTranslation;
@synthesize isPanning;
@synthesize justStartedPan;
@synthesize panPosition;
@synthesize panTouch = _panTouch;
@synthesize frameSize = _frameSize;
@synthesize enabled = _enabled;

- (id) initWithFrameSize:(CGSize)initFrameSize target:(id)target action:(SEL)action
{
    self = [super init];
    if(self)
    {
        prevPoint = CGPointMake(0.0f, 0.0f);
        curPoint = CGPointMake(0.0f, 0.0f); 
        curTranslation = CGPointMake(0.0f, 0.0f);
        panOrigin = CGPointMake(0.0f, 0.0f);
        isPanning = NO;
        justStartedPan = NO;
        _panTouch = nil;
        _frameSize = initFrameSize;
        _enabled = YES;
    }
    return self;
}

- (void) dealloc
{
    [_panTouch release];
    [super dealloc];
}

- (void) resetPanOrigin
{
    panOrigin = curPoint;
}
#pragma mark -
#pragma mark touch event functions
- (void)reset
{
    prevPoint = CGPointMake(0.0f, 0.0f);
    curPoint = CGPointMake(0.0f, 0.0f);
    curTranslation = CGPointMake(0.0f, 0.0f);
    panOrigin = CGPointMake(0.0f, 0.0f);
    isPanning = NO;
    justStartedPan = NO;
    self.panTouch = nil;
}

- (void) view:(UIView*)view touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_enabled)
    {
        if(([touches count] == 1) && (![self panTouch]))
        {
            // begin pan only with single touch
            curPoint = [[touches anyObject] locationInView:view];
            prevPoint = curPoint;
            panOrigin = curPoint;
            isPanning = NO;
            curTranslation = [self calcTranslation:prevPoint :curPoint];
            
            // retain the touch even that started the pan
            self.panTouch = [touches anyObject];
        }
        else
        {
            // if more than one touch, trigger bomb
            [[GameManager getInstance] dropBomb];
        }
    }
    else
    {
        self.panTouch = nil;
    }
}

- (void)view:(UIView*)view touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // continue processing moved event if the touch event that started it is still active
    if(_enabled && [self panTouch])
    {
        BOOL moved = NO;
        for(UITouch* cur in touches)
        {
            if(cur == [self panTouch])
            {
                moved = YES;
            }
        }
        
        if(moved)
        {
            prevPoint = curPoint;
            curPoint = [[self panTouch] locationInView:view];
            curTranslation = [self calcTranslation:prevPoint :curPoint];

            if(!isPanning)
            {
                justStartedPan = YES;
                isPanning = YES;
            }
            else
            {
                justStartedPan = NO;
            }
            panPosition = CGPointMake(curPoint.x - panOrigin.x, curPoint.y - panOrigin.y);

            float panDisplacement = view.frame.size.width * PAN_DISPLACEMENT_FACTOR;
            float mag = CGPointMagnitude(curTranslation);
            if(panDisplacement < mag)
            {
                // clamp curTranslation at panDisplacement
                curTranslation.x = (curTranslation.x / mag) * panDisplacement;
                curTranslation.y = (curTranslation.y / mag) * panDisplacement;
            }

            // update player controls
            [[GameManager getInstance] handlePanControl:self];
        }
    }
}

- (void)view:(UIView*)view touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_enabled && [self panTouch])
    {
        BOOL panTouchChanged = NO;
        for(UITouch* cur in touches)
        {
            if(cur == [self panTouch])
            {
                panTouchChanged = YES;
            }
        }
        
        if(panTouchChanged)
        {
            isPanning = NO;
            justStartedPan = NO;
            
            self.panTouch = nil;
        }
    }
}

- (void)view:(UIView*)view touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_enabled && [self panTouch])
    {
        BOOL panTouchChanged = NO;
        for(UITouch* cur in touches)
        {
            if(cur == [self panTouch])
            {
                panTouchChanged = YES;
            }
        }
        
        if(panTouchChanged)
        {
            isPanning = NO;
            justStartedPan = NO;
            
            self.panTouch = nil;
        }
    }
}



#pragma mark -
#pragma mark Private Methods
- (CGPoint) calcTranslation:(CGPoint)pointA :(CGPoint)pointB
{
    CGPoint result = CGPointMake(pointB.x - pointA.x,
                                 pointB.y - pointA.y);
    return result;
}

@end
