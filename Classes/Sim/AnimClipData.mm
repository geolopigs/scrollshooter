//
//  AnimClipData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "AnimClipData.h"
#import "AnimFrame.h"

@implementation AnimClipData
@synthesize animFrames;
@synthesize framesPerSec;
@synthesize secsPerFrame;
@synthesize isLooping;
- (id)initWithFrameRate:(float)fps isLooping:(BOOL)isLoopingAnim
{
    self = [super init];
    if (self) 
    {
        self.animFrames = [NSMutableArray array];
        self.framesPerSec = fps;
        self.secsPerFrame = 1.0f / fps;
        self.isLooping = isLoopingAnim;
    }    
    return self;
}

- (void) dealloc
{
    self.animFrames = nil;
    [super dealloc];
}

- (void) addFrame:(AnimFrame*)newFrame
{
    [self.animFrames addObject:newFrame];
}

@end
