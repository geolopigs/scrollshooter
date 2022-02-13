//
//  CargoAddon.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/8/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddonProtocols.h"

@class AnimClipData;
@interface CargoAddon : NSObject<AddonTypeDelegate>
{
    CGSize          spriteSize;
    AnimClipData*   clipData;    
}
@property (nonatomic,assign) CGSize spriteSize;
@property (nonatomic,retain) AnimClipData* clipData;
- (id)initWithClipData:(AnimClipData*)animClipData renderSize:(CGSize)givenRenderSize;

@end
