//
//  HealthPack.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/8/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "HealthPack.h"
#import "Loot.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "Sprite.h"
#import "AnimClip.h"
#import "GameObjectSizes.h"
#include "MathUtils.h"

static const float LIFESPAN = 25.0f;
static const float SWING_SPEED = M_PI * 0.1f;   // in radians
static const float SWING_RANGE = 10.0f;
static const float INIT_VEL_X = 0.0f;
static const float INIT_VEL_Y = -3.0f;

static NSString* const HEALTHPACK_NAME = @"HealthPack";

@implementation HealthPackContext
@synthesize lifeSpanRemaining;
@synthesize swingParam;
@synthesize swingVel;
@synthesize initPos;
@end


@implementation HealthPack

#pragma mark -
#pragma mark LootInitDelegate
- (void) initLoot:(Loot*)givenLoot isDynamics:(BOOL)isDynamics
{
    NSString* myName = HEALTHPACK_NAME;
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:myName];
	Sprite* lootSprite = [[Sprite alloc] initWithSize:mySize];
	givenLoot.sprite = lootSprite;
    [lootSprite release];
    
    // ignore isDynamics, health-packs are always dynamics
    givenLoot.releasedAsDynamic = YES;
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClip
    AnimClipData* clipData = [animData getClipForName:myName];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    givenLoot.animClip = newClip;
    [newClip release];
    
    // install the behavior delegate
    givenLoot.behaviorDelegate = self;
    HealthPackContext* newContext = [[HealthPackContext alloc] init];
    newContext.lifeSpanRemaining = LIFESPAN;
    newContext.swingParam = 0.0f;
    newContext.swingVel = SWING_SPEED;
    newContext.initPos = givenLoot.pos;
    givenLoot.lootContext = newContext;
    [newContext release];
    
    // behavior params
    givenLoot.vel = CGPointMake(INIT_VEL_X, INIT_VEL_Y);
    
    // set collision AABB
    givenLoot.collisionSize = [[GameObjectSizes getInstance] colSizeFor:myName];
    givenLoot.collisionResponseDelegate = self;
    givenLoot.collisionAABBDelegate = self;
    
    // install killed delegate
    givenLoot.collectedDelegate = self;
    
}

#pragma mark -
#pragma mark LootBehaviorDelegate
- (void) update:(NSTimeInterval)elapsed forLoot:(Loot*)givenLoot
{
    HealthPackContext* myContext = [givenLoot lootContext];
    
    // init new pos
    CGPoint newPos = givenLoot.pos;
    myContext.swingParam += (elapsed * myContext.swingVel);
    newPos.x = myContext.initPos.x + (sinf(myContext.swingParam) * SWING_RANGE);
    newPos.y = newPos.y + (elapsed * givenLoot.vel.y);
    
    // update life
    myContext.lifeSpanRemaining -= elapsed;
    if(0.0f > myContext.lifeSpanRemaining)
    {
        [givenLoot kill];
    }
    
    // update pos
    givenLoot.pos = newPos;
}

- (void) releasePickup:(Loot *)givenPickup
{
    // do nothing; the behavior of this type handles the releasing of pickup into the air
}

- (NSString*) getTypeName
{
    return HEALTHPACK_NAME;
}

#pragma mark -
#pragma mark LootCollisionResponse
- (void) loot:(Loot*)Loot respondToCollisionWithAABB:(CGRect)givenAABB
{
    // do nothing
}

- (BOOL) isCollisionOn:(Loot*)loot
{
    return YES;
}

#pragma mark -
#pragma mark LootCollectedDelegate
- (void) collectLoot:(Loot*)givenLoot
{
}

#pragma mark -
#pragma mark LootAABBDelegate
- (CGRect) getAABB:(Loot*)givenLoot
{
    float halfWidth = givenLoot.collisionSize.width * 0.5f;
    float halfHeight = givenLoot.collisionSize.height * 0.5f;
    CGPoint AABBPos = [givenLoot pos];
    CGRect result = CGRectMake(AABBPos.x - halfWidth, AABBPos.y - halfHeight, givenLoot.collisionSize.width, givenLoot.collisionSize.height);
    return result;  
}



@end
