//
//  AnimProcDelegate.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnimFrame;
@protocol AnimProcDelegate <NSObject>
- (BOOL) advanceAnim:(NSTimeInterval)elapsed;
- (AnimFrame*) currentFrame;
- (int) currentFrameIndex;
- (AnimFrame*) currentFrameAtIndex:(int)index;
@end
