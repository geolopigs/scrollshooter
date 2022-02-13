//
//  CargoAddon.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/8/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "CargoAddon.h"
#import "Sprite.h"
#import "AnimClip.h"
#import "Addon.h"


@implementation CargoAddon
@synthesize spriteSize;
@synthesize clipData;

- (id)initWithClipData:(AnimClipData*)animClipData renderSize:(CGSize)givenRenderSize
{
    self = [super init];
    if (self) 
    {
        self.spriteSize = givenRenderSize;
        self.clipData = animClipData;
    }
    
    return self;
}

- (void) dealloc
{
    self.clipData = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark AddonTypeDelegate
- (void) initAddon:(Addon *)newAddon
{
    AnimClip* newAnim = [[AnimClip alloc] initWithClipData:clipData];
    Sprite* newSprite = [[Sprite alloc] initWithSize:spriteSize];
    
    newAddon.sprite = newSprite;
    newAddon.anim = newAnim;
    
    [newAnim release];
    [newSprite release];
}

- (void) updateBehaviorForAddon:(Addon *)givenAddon elapsed:(NSTimeInterval)elapsed
{
    
}

@end
