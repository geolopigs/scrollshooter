//
//  TextEffectType.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/7/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "TextEffectType.h"
#import "AnimClipData.h"
#import "Texture.h"
#import "LevelManager.h"
#import "Level.h"
#import "TopCam.h"

@implementation TextEffectType

- (id)initWithString:(NSString*)text withFontNamed:(NSString*)fontName atRes:(unsigned int)numTexelLines
{
    self = [super init];
    if (self) 
    {
        Texture* newTexture = [[Texture alloc] initFromString:text withFontNamed:fontName atRes:numTexelLines];
        self.effectTexture = newTexture;
        
        CGRect gameFrame = [[[[LevelManager getInstance] curLevel] gameCamera] getPlayFrame];
        CGRect appFrame = [[[[LevelManager getInstance] curLevel] gameCamera] appFrame];
        
        // setup the recommended effect size based on the original width and height of texture (prior to retina scale)
        float effectWidth = [newTexture imageWidth];
        float effectHeight = [newTexture imageHeight];
        effectWidth *= ((gameFrame.size.width - gameFrame.origin.x) / (appFrame.size.width - appFrame.origin.x));
        effectHeight *= ((gameFrame.size.height - gameFrame.origin.y) / (appFrame.size.height - appFrame.origin.y));
        self.effectSize = CGSizeMake(effectWidth, effectHeight);
        [newTexture release];
    }
    
    return self;
}

- (void) dealloc
{
    self.effectTexture = nil;
    [super dealloc];
}

#pragma mark - EffectTypeDelegate
@synthesize effectSize;
@synthesize effectTexture;

- (void) setEffectClipData:(AnimClipData*)clipData
{
    // do nothing
}

- (AnimClipData*) effectClipData
{
    return nil;
}

@end
