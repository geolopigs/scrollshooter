//
//  EffectArchetype.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EffectProtocols.h"
@class AnimClipData;
@interface EffectArchetype : NSObject<EffectTypeDelegate>
{
    CGSize          effectSize;
    AnimClipData*   effectClipData;
}
- (id) initWithClipData:(AnimClipData*)initData andSize:(CGSize)initSize;
@end
