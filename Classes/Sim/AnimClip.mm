//
//  AnimClip.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "AnimClip.h"
#import "AnimClipData.h"
#import "AnimFrame.h"
#import "AnimProcessor.h"
#include "MathUtils.h"

@implementation AnimClip
@synthesize clipData;
@synthesize curFrame;
@synthesize curFrameFrac;
@synthesize isForwardPlayback;
@synthesize playbackState;

- (id)initWithClipData:(AnimClipData *)data
{
    self = [super init];
    if (self) 
    {
        assert(data);
        self.clipData = data;
        self.curFrame = 0;
        self.curFrameFrac = 0.0f;
        self.isForwardPlayback = YES;
        self.playbackState = ANIMCLIP_STATE_IDLE;
    }
    return self;
}

- (void) dealloc
{
    self.clipData = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Playback Controls

- (void) playClipForward:(BOOL)isForward
{
    self.isForwardPlayback = isForward;
    if((ANIMCLIP_STATE_IDLE == self.playbackState) ||
       (ANIMCLIP_STATE_DONE == self.playbackState))
    {
        self.curFrameFrac = 0.0f;
        if(isForward)
        {
            self.curFrame = 0;
        }
        else
        {
            // backward
            self.curFrame = [self.clipData.animFrames count]-1;
        }
        self.playbackState = ANIMCLIP_STATE_PLAYING;
    }
    else if(ANIMCLIP_STATE_PLAYING == self.playbackState)
    {
        // do nothing
    }
    else    // ANIMCLIP_STATE_PAUSED
    {
        self.playbackState = ANIMCLIP_STATE_PLAYING;
    }
}

- (void) playClipRandomForward:(BOOL)isForward
{
    self.isForwardPlayback = isForward;
    if((ANIMCLIP_STATE_IDLE == self.playbackState) ||
       (ANIMCLIP_STATE_DONE == self.playbackState))
    {
        int numFrames = [self.clipData.animFrames count]-1;
        float initFrame = floorf(randomFrac() * numFrames);
        self.curFrame = static_cast<int>(initFrame);
        self.curFrameFrac = 0.0f;
        self.playbackState = ANIMCLIP_STATE_PLAYING;
    }
    else if(ANIMCLIP_STATE_PLAYING == self.playbackState)
    {
        // do nothing
    }
    else    // ANIMCLIP_STATE_PAUSED
    {
        self.playbackState = ANIMCLIP_STATE_PLAYING;
    }
}


- (void) pauseClip
{
    if(ANIMCLIP_STATE_PLAYING == self.playbackState)
    {
        self.playbackState = ANIMCLIP_STATE_PAUSED;
    }
}

- (void) stopClip
{
    self.playbackState = ANIMCLIP_STATE_IDLE;
    [self resetToFirstFrame];
}

- (void) resetToFirstFrame
{
    self.curFrame = 0;
    self.curFrameFrac = 0.0f;    
}

- (void) resetToLastFrame
{
    self.curFrame = [self.clipData.animFrames count] - 1;
    self.curFrameFrac = 0.0f;        
}

- (unsigned int) numFrames
{
    unsigned int result = [clipData.animFrames count];
    return result;
}

#pragma mark -
#pragma mark AnimProcDelegate
// returns YES if anim is still in progress
// NO if anim is done; state is ANIMCLIP_STATE_DONE;
- (BOOL) advanceAnim:(NSTimeInterval)elapsed
{
    BOOL result = YES;
    if(self.playbackState == ANIMCLIP_STATE_PLAYING)
    {
        float curFrac = self.curFrameFrac + (elapsed * self.clipData.framesPerSec);
        float curFracFloor = floorf(curFrac);
        int frameElapsed = static_cast<unsigned int>(curFracFloor);
        if(1 <= frameElapsed)
        {
            int numFrames = [self.clipData.animFrames count];
            int newFrame = self.curFrame;
            if(self.isForwardPlayback)
            {
                // forward
                newFrame += frameElapsed;
                if(numFrames <= newFrame)
                {
                    // done
                    // if looping, go to the first frame
                    if(clipData.isLooping)
                    {
                        newFrame = 0;
                    }
                    else
                    {
                        // done done
                        self.playbackState = ANIMCLIP_STATE_DONE;
                        result = NO;
                        newFrame = numFrames - 1;
                    }
                }
            }
            else
            {
                // backward
                newFrame -= frameElapsed;
                if(newFrame < 0)
                {
                    // done
                    // if looping, go to the first frame
                    if(clipData.isLooping)
                    {
                        newFrame = (numFrames - 1);
                    }
                    else
                    {
                        self.playbackState = ANIMCLIP_STATE_DONE;
                        result = NO;
                        newFrame = 0;
                    }
                }
            }
            self.curFrame = newFrame;
        }
        self.curFrameFrac = curFrac - curFracFloor;
        result = YES;
    }
    return result;
}

- (AnimFrame*) currentFrame
{
    assert((0 <= curFrame) && (curFrame < [self.clipData.animFrames count]));
    AnimFrame* result = [self currentFrameAtIndex:curFrame];
    return result;
}

- (int) currentFrameIndex
{
    assert((0 <= curFrame) && (curFrame < [self.clipData.animFrames count]));
    return curFrame;
}

- (AnimFrame*) currentFrameAtIndex:(int)index
{
    AnimFrame* result = [clipData.animFrames objectAtIndex:index];
    return result;
}
@end
