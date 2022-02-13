//
//  Addon.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "Addon.h"
#import "Sprite.h"
#import "AnimClip.h"
#import "DynamicManager.h"
#import "AnimProcessor.h"
#import "AnimFrame.h"
#import "Texture.h"
#import "DrawCommand.h"
#import "RenderBucketsManager.h"
#import "Enemy.h"
#include "MathUtils.h"

@implementation Addon
@synthesize sprite;
@synthesize pos;
@synthesize scale;
@synthesize rotate = _rotate;
@synthesize anim;
@synthesize startDelay = _startDelay;
@synthesize behaviorContext;
@synthesize delegate;
@synthesize parent;
@synthesize ownsBucket;
@synthesize renderBucket;

#pragma mark -
#pragma mark Public Methods

- (id) initAtPos:(CGPoint)givenPos withDelegate:(NSObject<AddonTypeDelegate>*)addonDelegate
{
    self = [super init];
    if (self) 
    {
        self.sprite = nil;
        self.pos = givenPos;
        self.scale = CGPointMake(1.0f, 1.0f);
        _rotate = 0.0f;
        self.anim = nil;
        _startDelay = 0.0f;
        self.behaviorContext = nil;
        self.delegate = addonDelegate;
        self.ownsBucket = NO;
        self.renderBucket = 0;
    }
    
    return self;
}

- (void) dealloc
{
    assert(nil == parent);
    self.delegate = nil;
    self.behaviorContext = nil;
    self.anim = nil;
    self.sprite = nil;
    [super dealloc];
}

- (void) spawnOnParent:(NSObject<AddonDelegate>*)givenParent;
{
    [[DynamicManager getInstance] addObject:self];
    [[AnimProcessor getInstance] addClip:anim];
    self.parent = givenParent;
}

- (void) kill
{
    self.parent = nil;
    [[AnimProcessor getInstance] removeClip:anim];
    [[DynamicManager getInstance] removeObject:self];
}

- (void) addDrawAsAddonToBucketIndex:(unsigned int)bucketIndex
{
    if(0.0f >= _startDelay)
    {
        unsigned int renderBucketIndex = bucketIndex;
        if(ownsBucket)
        {
            // if I own the renderbucket, ignore the caller's bucket
            renderBucketIndex = renderBucket;
        }
        SpriteInstance* instanceData = [[SpriteInstance alloc] init];
        AnimFrame* curFrame = [anim currentFrame];
        instanceData.texture = [[curFrame texture] texName];
        CGPoint parentPos = [parent worldPosition];
        instanceData.pos = CGPointMake(parentPos.x + pos.x, parentPos.y + pos.y);
        instanceData.scale = CGPointMake([curFrame renderScale].x * scale.x,
                                         [curFrame renderScale].y * scale.y);
        instanceData.rotate = _rotate + RadiansToDegrees([parent rotation]) + [curFrame renderRotate];
        instanceData.texcoordScale = CGPointMake(([[curFrame texture] getImageWidthTexcoord] * [curFrame scale].x),
                                                 ([[curFrame texture] getImageHeightTexcoord] * [curFrame scale].y));
        instanceData.texcoordTranslate = [curFrame translate];
        instanceData.colorR = [curFrame colorR];
        instanceData.colorG = [curFrame colorG];
        instanceData.colorB = [curFrame colorB];
        instanceData.alpha = [curFrame colorA];
        DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:self.sprite DrawData:instanceData];
        [[RenderBucketsManager getInstance] addCommand:cmd toBucket:renderBucketIndex];
        [instanceData release];
        [cmd release];
    }
}

- (void) addDrawAsAddonAtAnimFrameIndex:(int)animFrameIndex toBucketIndex:(unsigned int)bucketIndex withAlpha:(float)givenAlpha
{
    if(0.0f >= _startDelay)
    {
        unsigned int renderBucketIndex = bucketIndex;
        if(ownsBucket)
        {
            // if I own the renderbucket, ignore the caller's bucket
            renderBucketIndex = renderBucket;
        }
        
        SpriteInstance* instanceData = [[SpriteInstance alloc] init];
        AnimFrame* curFrame = [anim currentFrameAtIndex:animFrameIndex];
        instanceData.texture = [[curFrame texture] texName];
        CGPoint parentPos = [parent worldPosition];
        instanceData.pos = CGPointMake(parentPos.x + pos.x, parentPos.y + pos.y);
        instanceData.scale = CGPointMake([curFrame renderScale].x * scale.x,
                                         [curFrame renderScale].y * scale.y);
        instanceData.rotate = _rotate + RadiansToDegrees([parent rotation]) + [curFrame renderRotate];
        instanceData.texcoordScale = CGPointMake(([[curFrame texture] getImageWidthTexcoord] * [curFrame scale].x),
                                                 ([[curFrame texture] getImageHeightTexcoord] * [curFrame scale].y));
        instanceData.texcoordTranslate = [curFrame translate];
        instanceData.colorR = [curFrame colorR];
        instanceData.colorG = [curFrame colorG];
        instanceData.colorB = [curFrame colorB];
        instanceData.alpha = [curFrame colorA] * givenAlpha;
        DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:self.sprite DrawData:instanceData];
        [[RenderBucketsManager getInstance] addCommand:cmd toBucket:renderBucketIndex];
        [instanceData release];
        [cmd release];    
    }
}


#pragma mark -
#pragma mark DynamicDelegate

- (BOOL) isViewConstrained
{
    return NO;
}

- (void) addDraw
{
    // do nothing
    // add-ons are added by their parent to ensure the correct draw order
}


- (void) updateBehavior:(NSTimeInterval)elapsed
{
    if(_startDelay > 0.0f)
    {
        _startDelay -= elapsed;
        if(0.0f >= _startDelay)
        {
            _startDelay = 0.0f;
            [anim playClipForward:YES];
        }
    }
    [delegate updateBehaviorForAddon:self elapsed:elapsed];
}

@end
