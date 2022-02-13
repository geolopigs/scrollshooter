//
//  EffectArchetype.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "EffectArchetype.h"
#import "Texture.h"

@implementation EffectArchetype

- (id) initWithClipData:(AnimClipData*)initData andSize:(CGSize)initSize;
{
    self = [super init];
    if (self) 
    {
        self.effectSize = initSize;
        self.effectClipData = initData;
    }    
    return self;
}

- (void) dealloc
{
    self.effectClipData = nil;
    [super dealloc];
}

#pragma mark - EffectTypeDelegate
@synthesize effectSize;
@synthesize effectClipData;

- (void) setEffectTexture:(Texture *)effectTexture
{
    // do nothing
}

- (Texture*) effectTexture
{
    return nil;
}

@end
