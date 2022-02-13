//
//  Addon.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DynamicProtocols.h"
#import "AddonProtocols.h"
#import "AnimProcDelegate.h"

@class Sprite;
@class AnimClip;
@interface Addon : NSObject<DynamicDelegate>
{
    Sprite*     sprite;
    CGPoint     pos;
    CGPoint     scale;
    float       _rotate;
    AnimClip* anim;
    
    id          behaviorContext;
    NSObject<AddonTypeDelegate>* delegate;
    
    NSObject<AddonDelegate>* parent;
    
    
    BOOL            ownsBucket;
    unsigned int    renderBucket;
}
@property (nonatomic,retain) Sprite* sprite;
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGPoint scale;
@property (nonatomic,assign) float rotate;
@property (nonatomic,retain) AnimClip* anim;
@property (nonatomic,assign) float startDelay;
@property (nonatomic,retain) id behaviorContext;
@property (nonatomic,retain) NSObject<AddonTypeDelegate>* delegate;
@property (nonatomic,retain) NSObject<AddonDelegate>* parent;
@property (nonatomic,assign) BOOL ownsBucket;
@property (nonatomic,assign) unsigned int renderBucket;

- (id) initAtPos:(CGPoint)givenPos withDelegate:(NSObject<AddonTypeDelegate>*)addonDelegate;
- (void) spawnOnParent:(NSObject<AddonDelegate>*)givenParent;
- (void) kill;
- (void) addDrawAsAddonToBucketIndex:(unsigned int)bucketIndex;
- (void) addDrawAsAddonAtAnimFrameIndex:(int)animFrameIndex toBucketIndex:(unsigned int)bucketIndex withAlpha:(float)alpha;

@end
