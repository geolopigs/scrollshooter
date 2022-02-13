//
//  AnimClip.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnimProcDelegate.h"

typedef enum
{
    ANIMCLIP_STATE_IDLE = 0,
    ANIMCLIP_STATE_PLAYING,
    ANIMCLIP_STATE_PAUSED,
    ANIMCLIP_STATE_DONE,
    
    ANIMCLIP_STATE_NUM
} AnimClipStates;

@class AnimFrame;
@class AnimClipData;
@interface AnimClip : NSObject<AnimProcDelegate>
{
    AnimClipData*   clipData;
    int             curFrame;
    float           curFrameFrac;
    BOOL            isForwardPlayback;
    unsigned int    playbackState;
}
@property (nonatomic,retain) AnimClipData* clipData;
@property (nonatomic,assign) int curFrame;
@property (nonatomic,assign) float curFrameFrac;
@property (nonatomic,assign) BOOL isForwardPlayback;
@property (nonatomic,assign) unsigned int playbackState;

- (id) initWithClipData:(AnimClipData*)data;
- (void) playClipForward:(BOOL)isForward;
- (void) playClipRandomForward:(BOOL)isForward;
- (void) pauseClip;
- (void) stopClip;
- (void) resetToFirstFrame;
- (void) resetToLastFrame;
- (unsigned int) numFrames;
@end
