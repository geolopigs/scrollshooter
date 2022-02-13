//
//  FadeController.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/15/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FadeController : NSObject
{
    unsigned int fadeState;
    float timer;
    float fade;
    float alpha;
    float fadeDur;
    float fadeAlphaIncr;
    float visibleDur;
}
@property (nonatomic,readonly) float alpha;
@property (nonatomic,readonly) float fadeDur;
@property (nonatomic,readonly) float visibleDur;
- (id) initWithFadeDur:(float)fadeDuration visibleDur:(float)visibleDuration;
- (BOOL) update:(NSTimeInterval)elapsed;
- (void) gotoFullyVisibleWithDuration:(float)mult;
- (void) gotoHidden;
- (void) triggerFade;
- (BOOL) isFullyVisible;
- (BOOL) isActive;
@end
