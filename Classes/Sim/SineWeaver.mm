//
//  SineWeaver.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/13/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "SineWeaver.h"
#include "MathUtils.h"

@implementation SineWeaver
@synthesize base;
@synthesize curParam;

// initVel is a fraction of 180-degrees (M_PI)
- (id) initWithRange:(float)initRange vel:(float)initVel
{
    self = [super init];
    if(self)
    {
        range = initRange;
        vel = initVel * M_PI;
        base = 0.0f;
        curParam = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) reset
{
    base = 0.0f;
    curParam = 0.0f;
}

- (void) resetRandomWithBase:(float)baseline
{
    curParam = randomFrac() * M_PI * 0.75f;
    base = baseline - (sinf(curParam) * range);
}

- (float) update:(NSTimeInterval)elapsed
{
    float newParam = curParam + (elapsed * vel);
    if(newParam > (M_PI * 2.0f))
    {
        newParam = newParam - (M_PI * 2.0f);
    }        
    curParam = newParam;
    
    return [self eval];
}

- (float) eval
{
    float newPos = base + (sinf(curParam) * range);
    return newPos;
}

- (BOOL) willCrossThreshold:(float)threshold afterElapsed:(NSTimeInterval)elapsed
{
    BOOL result = NO;
    float newParam = curParam + (elapsed * vel);
    if(newParam >= threshold)
    {
        result = YES;
    }
    return result;
}



@end
