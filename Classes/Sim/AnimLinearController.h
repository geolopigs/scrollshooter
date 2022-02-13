//
//  AnimLinearController.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnimProcDelegate.h"

@class AnimFrame;
@class AnimClipData;
@interface AnimLinearController : NSObject<AnimProcDelegate>
{
    // config
    float speed;
    NSArray* animFrames;
    float interval;
    
    // params
    float cur;
    float target;
}
@property (nonatomic,assign) float speed;
@property (nonatomic,retain) NSArray* animFrames;
@property (nonatomic,assign) float interval;
@property (nonatomic,assign) float cur;
@property (nonatomic,assign) float target;

- (id) initFromAnimClipData:(AnimClipData*)clipData;
- (id) initWithAnimFrames:(NSArray*)framesArray;

- (void) targetRangeMin;
- (void) targetRangeMax;
- (void) targetRangeMedian;

- (float) getRangeMin;
- (float) getRangeMax;
- (float) getRangeMedian;
@end
