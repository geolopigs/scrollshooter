//
//  LootCash.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/5/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LootCash.h"
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
static const float MAGNET_SPEED = 140.0f;

@implementation LootCashContext
@synthesize lifeSpanRemaining;
@synthesize swingParam;
@synthesize swingVel;
@synthesize initPos;
@synthesize magnetToPlayer;

- (id) init
{
    self = [super init];
    if(self)
    {
        magnetToPlayer = NO;
    }
    return self;
}
@end

static NSString* const CARGO1_NAME = @"Cargo1";
static NSString* const CARGOPACK_NAME = @"CargoPack";

@implementation LootCash

#pragma mark -
#pragma mark LootInitDelegate
- (void) initLoot:(Loot*)givenLoot isDynamics:(BOOL)isDynamics
{
    NSString* cargoName = CARGO1_NAME;
    if(randomFrac() > 0.5f)
    {
        cargoName = CARGOPACK_NAME;
    }
    
    // NOTE:  use CARGO1's size so that all LootCash objects have the same size regardless of anim
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:CARGO1_NAME];
	Sprite* lootSprite = [[Sprite alloc] initWithSize:mySize];
	givenLoot.sprite = lootSprite;
    [lootSprite release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
  
    // init animClip
    AnimClipData* clipData = [animData getClipForName:cargoName];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    givenLoot.animClip = newClip;
    [newClip release];
    
    // install the behavior delegate
    givenLoot.behaviorDelegate = self;
    LootCashContext* newContext = [[LootCashContext alloc] init];
    newContext.lifeSpanRemaining = LIFESPAN;
    newContext.swingParam = 0.0f;
    newContext.swingVel = SWING_SPEED;
    newContext.initPos = givenLoot.pos;
    givenLoot.lootContext = newContext;
    [newContext release];
    
    // behavior params
    givenLoot.vel = CGPointMake(INIT_VEL_X, INIT_VEL_Y);

    // set collision AABB
    givenLoot.collisionSize = [[GameObjectSizes getInstance] colSizeFor:cargoName];
    givenLoot.collisionResponseDelegate = self;
    givenLoot.collisionAABBDelegate = self;
    
    // if dynamics, make it twice as big
    if(isDynamics)
    {
        // make it twice as big
        givenLoot.renderScale = CGPointMake(2.0f, 2.0f);
        givenLoot.collisionSize = CGSizeMake(givenLoot.collisionSize.width * 2.0f,
                                             givenLoot.collisionSize.height * 2.0f);
    }
    
    // install killed delegate
    givenLoot.collectedDelegate = self;

}

#pragma mark -
#pragma mark LootBehaviorDelegate
- (void) update:(NSTimeInterval)elapsed forLoot:(Loot*)givenLoot
{
    LootCashContext* myContext = [givenLoot lootContext];

    // init new pos
    CGPoint newPos = givenLoot.pos;
    
    // check for releasing it to float
    if(![givenLoot releasedAsDynamic])
    {
        TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
        CGPoint camPos = [gameCam camPointFromWorldPoint:[givenLoot pos] atDistance:[givenLoot layerDistance]];
        if(RELEASETHRESHOLD_POSY >= camPos.y)
        {
            // release it by putting it in camera space
            givenLoot.releasedAsDynamic = YES;
            newPos.y = camPos.y;
            
            // make it twice as big
            givenLoot.renderScale = CGPointMake(2.0f, 2.0f);
            givenLoot.collisionSize = CGSizeMake(givenLoot.collisionSize.width * 2.0f,
                                                 givenLoot.collisionSize.height * 2.0f);
            
            givenLoot.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Addons"];
        }
    }

    if([givenLoot releasedAsDynamic])
    {
        Player* player = [[GameManager getInstance] playerShip];
        if(([myContext magnetToPlayer]) && ([player isAlive]))
        {
            CGPoint vecToPlayer = CGPointSubtract([player pos], newPos);
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
            
            if([player isAlive])
            {
                if([player cargoMagnetRadius] >= Distance(newPos, [player pos]))
                {
                    myContext.magnetToPlayer = YES;
                }
            }
        }
    }
}


- (void) releasePickup:(Loot *)givenPickup
{
    // do nothing; this Loot type behavior handles pickup release by itself
}


- (NSString*) getTypeName
{
    return @"LootCash";
}

#pragma mark -
#pragma mark LootCollisionResponse
- (void) loot:(Loot*)loot respondToCollisionWithAABB:(CGRect)givenAABB
{
    // do nothing
}

- (BOOL) isCollisionOn:(Loot*)loot
{
    BOOL result = YES;
    if(![loot releasedAsDynamic])
    {
        result = NO;
    }
    return result;
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
    if([givenLoot releasedAsDynamic])
    {
        AABBPos = [givenLoot pos];
    }
    else
    {
        TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
        AABBPos = [gameCam camPointFromWorldPoint:[givenLoot pos] atDistance:[givenLoot layerDistance]];
    }
    CGRect result = CGRectMake(AABBPos.x - halfWidth, AABBPos.y - halfHeight, givenLoot.collisionSize.width, givenLoot.collisionSize.height);
    return result;  
}


@end
