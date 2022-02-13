//
//  ScatterBomb.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "ScatterBomb.h"
#import "DynamicsSpawner.h"
#import "GameObjectSizes.h"
#import "Sprite.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "AnimClip.h"
#import "FiringPath.h"
#import "GameManager.h"
#import "Effect.h"
#import "EffectFactory.h"
#import "Loot.h"
#import "LootFactory.h"
#import "SoundManager.h"
#import "TopCam.h"
#import "BossWeapon.h"
#include "MathUtils.h"


static NSString* const TYPENAME = @"ScatterBomb";

@implementation ScatterBombContext
@synthesize numShotsPerRound;
@synthesize initVel;

@synthesize scatterWeapon;
@synthesize shotCount;


- (id) init
{
    self = [super init];
    if(self)
    {
        // default configs
        numShotsPerRound = 1;
        initVel = CGPointMake(0.0f, 0.0f);
        
        // init runtime
        self.scatterWeapon = nil;
        shotCount = 0;
    }
    return self;
}

- (void) dealloc
{
    self.scatterWeapon = nil;
    [super dealloc];
}


- (void) setupFromTriggerContext:(NSDictionary*)triggerContext
{
    if(triggerContext)
    {
        numShotsPerRound = [[triggerContext objectForKey:@"shotsPerRound"] unsignedIntValue];
        
        NSDictionary* bossWeaponConfig = [triggerContext objectForKey:@"bossWeapon"];
        assert(bossWeaponConfig);
        self.scatterWeapon = [[BossWeapon alloc] initFromConfig:bossWeaponConfig];
    }
}

@end

@implementation ScatterBomb
@synthesize animName;
@synthesize explosionName;

- (id) initWithAnimNamed:(NSString *)name explosionNamed:(NSString*)expName
{
    self = [super init];
    if(self)
    {
        self.animName = name;
        self.explosionName = expName;
    }
    return self;
}

- (void) dealloc
{
    self.animName = nil;
    self.explosionName = nil;
    [super dealloc];
}



#pragma mark - EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    NSString* typeName = TYPENAME;
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:typeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClip
    AnimClipData* clipData = [animData getClipForName:animName];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    givenEnemy.animClip = newClip;
    [newClip release];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:typeName];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // game status
    givenEnemy.health = 50;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"SpinTriBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(NSObject<EnemySpawnerContextDelegate>*)givenSpawnerContext
{
    // do nothing
}

#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    ScatterBombContext* myContext = [givenEnemy behaviorContext];
    float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
    float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
    
    // process firing
    if([myContext shotCount] < [myContext numShotsPerRound])
    {
        BOOL shotsFired = [[myContext scatterWeapon] enemyFire:givenEnemy elapsed:elapsed];
        if(shotsFired)
        {
            myContext.shotCount++;
        }
    }        
    else
    {
        if(![givenEnemy hidden])
        {
            // when all scatters fired, hide it
            givenEnemy.hidden = YES;
        
            // play sound
            [[SoundManager getInstance] playClip:@"BoarFighterExplosion"];

            // play explosion effect
            if([self explosionName])
            {
                [EffectFactory effectNamed:[self explosionName] atPos:[givenEnemy pos]];
            }
        }
        
        if(0 == [[givenEnemy firingPath] numOutstandingShots])
        {
            givenEnemy.willRetire = YES;
        }
    }
        
    givenEnemy.pos = CGPointMake(newPosX, newPosY);
}

- (NSString*) getEnemyTypeName
{
    return TYPENAME;
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    // do nothing
}


#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    // do nothing
    // Add code here to deplete health when we want to allow player to shoot it down
}

- (BOOL) isPlayerCollidable
{
    return YES;
}

- (BOOL) isPlayerWeapon
{
    return NO;
}

- (BOOL) isCollidable
{
    return NO;
}

- (BOOL) isCollisionOnFor:(Enemy *)enemy
{
    BOOL result = YES;
    if([enemy hidden])
    {
        result = NO;
    }
    return result;
}


#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    ScatterBombContext* myContext = [givenEnemy behaviorContext];
    myContext.scatterWeapon = nil;
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    // do nothing
    // returns true for enemy to be killed immediately
    return YES;
}
#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    ScatterBombContext* myContext = [givenEnemy behaviorContext];
    
    // setup my weapons
    myContext.shotCount = 0;
    
    // setup my velocity
    givenEnemy.vel = [myContext initVel];
}



@end
