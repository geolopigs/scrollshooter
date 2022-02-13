//
//  UpgradePack.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "UpgradePack.h"
#import "Loot.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "RenderBucketsManager.h"
#import "Level.h"
#import "Sprite.h"
#import "AnimClip.h"
#import "TopCam.h"
#import "GameObjectSizes.h"
#import "GameManager.h"
#import "Player.h"
#include "MathUtils.h"

static const float PHYSICS_WIDTH = 10.0f;
static const float PHYSICS_HEIGHT = 10.0f;
static const float RENDER_WIDTH = 10.0f;
static const float RENDER_HEIGHT = 10.0f;
static const float LIFESPAN = 25.0f;
static const float SWING_SPEED = M_PI * 0.1f;   // in radians
static const float SWING_RANGE = 10.0f;
static const float RELEASETHRESHOLD_POSY = 60.0f;       // if the Loot's world position y is below this threshold, release it and let it float
static const float INIT_VEL_X = 0.0f;
static const float INIT_VEL_Y = -10.0f;
static const float MAGNET_SPEED = 100.0f;


@implementation UpgradePackContext
@synthesize lifeSpanRemaining;
@synthesize swingParam;
@synthesize swingVel;
@synthesize initPos;
@synthesize willRelease;
@end


@implementation UpgradePack
@synthesize typeName;
@synthesize sizeName;
@synthesize clipName;

- (id) initWithTypeName:(NSString*)givenName 
               sizeName:(NSString*)givenSizeName 
               clipName:(NSString*)givenClipName 
{
    self = [super init];
    if(self)
    {
        self.typeName = givenName;
        self.sizeName = givenSizeName;
        self.clipName = givenClipName;
    }
    return self;
}

- (void) dealloc
{
    self.clipName = nil;
    self.sizeName = nil;
    self.typeName = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark LootInitDelegate
- (void) initLoot:(Loot*)givenLoot isDynamics:(BOOL)isDynamics
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:sizeName];
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:sizeName];
	Sprite* lootSprite = [[Sprite alloc] initWithSize:mySize colSize:colSize];
	givenLoot.sprite = lootSprite;
    [lootSprite release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClip
    AnimClipData* clipData = [animData getClipForName:clipName];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    givenLoot.animClip = newClip;
    [newClip release];
    
    // install the behavior delegate
    givenLoot.behaviorDelegate = self;
    UpgradePackContext* newContext = [[UpgradePackContext alloc] init];
    newContext.lifeSpanRemaining = LIFESPAN;
    newContext.swingParam = 0.0f;
    newContext.swingVel = SWING_SPEED;
    newContext.initPos = givenLoot.pos;
    givenLoot.lootContext = newContext;
    [newContext release];
    
    // behavior params
    givenLoot.vel = CGPointMake(INIT_VEL_X, INIT_VEL_Y);
    
    // set collision AABB
    givenLoot.collisionSize = [[GameObjectSizes getInstance] colSizeFor:sizeName];
    givenLoot.collisionResponseDelegate = self;
    givenLoot.collisionAABBDelegate = self;
    
    // install killed delegate
    givenLoot.collectedDelegate = self;
    
}

#pragma mark -
#pragma mark LootBehaviorDelegate
- (void) update:(NSTimeInterval)elapsed forLoot:(Loot*)givenLoot
{
    UpgradePackContext* myContext = [givenLoot lootContext];
    
    // init new pos
    CGPoint newPos = givenLoot.pos;
    
    Player* player = [[GameManager getInstance] playerShip];
    if(([player isAlive]) &&
       ([player magnetDistUpgrade] >= Distance(newPos, [player pos])))
    {
        CGPoint vecToPlayer = CGPointSubtract([[[GameManager getInstance] playerShip] pos], newPos);
        CGPoint vecNormalized = CGPointNormalize(vecToPlayer);
        newPos.x += (elapsed * MAGNET_SPEED * vecNormalized.x);
        newPos.y += (elapsed * MAGNET_SPEED * vecNormalized.y);
        givenLoot.pos = newPos;
    }
    else
    {
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
}

- (void) releasePickup:(Loot *)givenPickup
{
    
}

- (NSString*) getTypeName
{
    return typeName;
}

#pragma mark -
#pragma mark LootCollisionResponse
- (void) loot:(Loot*)Loot respondToCollisionWithAABB:(CGRect)givenAABB
{
    // do nothing
}

- (BOOL) isCollisionOn:(Loot *)loot
{
    // collision is always on for UpgradePack
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
    CGPoint AABBPos;
    float halfWidth = givenLoot.collisionSize.width * 0.5f;
    float halfHeight = givenLoot.collisionSize.height * 0.5f;
    AABBPos = [givenLoot pos];
    CGRect result = CGRectMake(AABBPos.x - halfWidth, AABBPos.y - halfHeight, givenLoot.collisionSize.width, givenLoot.collisionSize.height);
    return result;  
}


@end
