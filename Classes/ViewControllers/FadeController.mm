//
//  FadeController.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/15/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "FadeController.h"

enum FADESTATE 
{
    FADESTATE_HIDDEN = 0,
    FADESTATE_FADEIN,
    FADESTATE_FULLYVISIBLE,
    FADESTATE_FADEOUT,
    
    FADESTATE_NUM
};

@implementation FadeController
@synthesize alpha;
@synthesize fadeDur;
@synthesize visibleDur;

- (id) initWithFadeDur:(float)fadeDuration visibleDur:(float)visibleDuration
{
    self = [super init];
    if(self)
    {
        fadeDur = fadeDuration;
        visibleDur = visibleDuration;
        fadeAlphaIncr = 1.0f / fadeDur;
        
        fadeState = FADESTATE_HIDDEN;
        timer = 0.0f;
        fade = 0.0f;
        alpha = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

#pragma mark - controls
- (void) gotoFullyVisibleWithDuration:(float)mult
{
    alpha = 1.0f;
    fade = 0.0f;
    timer = visibleDur * mult;  // first visible longer
    fadeState = FADESTATE_FULLYVISIBLE;
}

- (void) gotoHidden
{
    fadeState = FADESTATE_HIDDEN;
    timer = 0.0f;
    fade = 0.0f;
    alpha = 0.0f;
}

- (BOOL) isFullyVisible
{
    return (fadeState == FADESTATE_FULLYVISIBLE);
}

- (BOOL) isActive
{
    return (fadeState != FADESTATE_HIDDEN);
}

- (void) triggerFade
{
    switch(fadeState)
    {
        case FADESTATE_HIDDEN:
            // fade in regularly
            fadeState = FADESTATE_FADEIN;
            timer = fadeDur;
            fade = fadeAlphaIncr;
            break;
            
        case FADESTATE_FULLYVISIBLE:
            // already visible, extend its duration
            timer =visibleDur;
            break;
            
        case FADESTATE_FADEOUT:
            // in the middle of fading out, pop back to fading in
            fadeState = FADESTATE_FADEIN;
            fade = fadeAlphaIncr;
            timer = fadeDur - timer;
            break;
            
        default:
            // do nothing
            break;
    }    
}

- (BOOL) update:(NSTimeInterval)elapsed
{
    BOOL updateAlpha = NO;
    if(fadeState != FADESTATE_HIDDEN)
    {
        switch(fadeState)
        {
            case FADESTATE_FADEIN:
            {
                alpha += (fade * elapsed);
                timer -= elapsed;
                if(timer <= 0.0f)
                {
                    alpha = 1.0f;
                    fade = 0.0f;
                    timer = visibleDur;
                    fadeState = FADESTATE_FULLYVISIBLE;
                }
                if(alpha > 1.0f)
                {
                    alpha = 1.0f;
                }
                updateAlpha = YES;
                break;
            }
                
            case FADESTATE_FULLYVISIBLE:
            {
                timer -= elapsed;
                if(timer <= 0.0f)
                {
                    fade = -fadeAlphaIncr;
                    timer = fadeDur;
                    fadeState =FADESTATE_FADEOUT;
                }
                break;
            }
                
            case FADESTATE_FADEOUT:
            {
                alpha += (fade * elapsed);
                timer -= elapsed;
                if(timer <= 0.0f)
                {
                    alpha = 0.0f;
                    fade = 0.0f;
                    timer = 0.0f;
                    fadeState = FADESTATE_HIDDEN;
                }
                if(alpha < 0.0f)
                {
                    alpha = 0.0f;
                }
                updateAlpha = YES;
                break;
            }
                
            default:
                // do nothing
                break;
        }
    }
    return updateAlpha;
}

@end
