//
//  AnimLinearController.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "AnimLinearController.h"
#import "AnimProcessor.h"
#import "AnimFrame.h"
#import "AnimClipData.h"

@implementation AnimLinearController
@synthesize speed;
@synthesize animFrames;
@synthesize interval;
@synthesize cur;

static const float RANGE_MIN = -1.0f;
static const float RANGE_MAX = 1.0f;
static const float DEFAULT_SPEED = 5.0f;

- (id) initFromAnimClipData:(AnimClipData *)clipData
{
    self = [super init];
    if(self)
    {
        self.animFrames = clipData.animFrames;
        self.speed = clipData.framesPerSec;
        self.interval = ((RANGE_MAX - RANGE_MIN) / [self.animFrames count]);
        self.cur = 0.0f;
        self.target = 0.0f;
    }
    return self;
}

- (id) initWithAnimFrames:(NSArray*)framesArray
{
    self = [super init];
    if (self) 
    {
        self.animFrames = framesArray;
        self.speed = DEFAULT_SPEED;
        self.interval = ((RANGE_MAX - RANGE_MIN) / [self.animFrames count]);
    }
    
    return self;
}

- (void) dealloc
{
    self.animFrames = nil;
    [super dealloc];
}

- (float) getRangeMax
{
    return RANGE_MAX;
}

- (float) getRangeMin
{
    return RANGE_MIN;
}

- (float) getRangeMedian
{
    return ((RANGE_MAX - RANGE_MIN) * 0.5f) + RANGE_MIN;
}

#pragma mark -
#pragma mark Controls
- (void) setTarget:(float)newTarget
{
    if(newTarget < RANGE_MIN)
    {
        newTarget = RANGE_MIN;
    }
    if(newTarget > RANGE_MAX)
    {
        newTarget = RANGE_MAX;
    }
    target = newTarget;
}

- (float) target
{
    return target;
}

- (void) targetRangeMin
{
    self.target = [self getRangeMin];
}

- (void) targetRangeMax
{
    self.target = [self getRangeMax];
}

- (void) targetRangeMedian
{
    self.target = [self getRangeMedian];
}

#pragma mark -
#pragma mark AnimProcDelegate
- (BOOL) advanceAnim:(NSTimeInterval)elapsed
{
    float diff = target - cur;
    if(fabsf(diff) > 0.0001f)
    {
        float direction = 1.0f;
        if(target < cur)
        {
            direction = -1.0f;
        }
        float newPos = cur + (direction * elapsed * speed);
        
        // if new pos crosses target, then just snap it to target
        float newDiff = target - newPos;
        if(((0.0f <= newDiff) && (diff < 0.0f)) ||
           ((0.0f <= diff) && (newDiff < 0.0f)))
        {
            cur = target;
        }
        else
        {
            cur = newPos;
        }
    }
    
    return YES;
}

- (AnimFrame*) currentFrame
{
    int index = [self currentFrameIndex];
    return [self currentFrameAtIndex:index];
}

- (int) currentFrameIndex
{
    float absoluteCur = cur - RANGE_MIN;
    int index = static_cast<int>(absoluteCur / interval);
    if(index < 0)
    {
        index = 0;
    }
    else if([self.animFrames count] <= index)
    {
        index = [self.animFrames count] - 1;
    }
    return index;
}

- (AnimFrame*) currentFrameAtIndex:(int)index
{    
    return [animFrames objectAtIndex:index];
}

@end
