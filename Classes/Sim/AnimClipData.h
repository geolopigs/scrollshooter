//
//  AnimClipData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AnimFrame;
@interface AnimClipData : NSObject
{
    NSMutableArray* animFrames;
    float framesPerSec;
    float secsPerFrame;
    BOOL isLooping;
}
@property (nonatomic,retain) NSMutableArray* animFrames;
@property (nonatomic,assign) float framesPerSec;
@property (nonatomic,assign) float secsPerFrame;
@property (nonatomic,assign) BOOL isLooping;
- (id) initWithFrameRate:(float)fps isLooping:(BOOL)isLoopingAnim;
- (void) addFrame:(AnimFrame*)newFrame;
@end
