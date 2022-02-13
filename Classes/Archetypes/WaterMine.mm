//
//  WaterMine.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/17/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "WaterMine.h"
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
#import "RenderBucketsManager.h"
#import "SineWeaver.h"
#include "MathUtils.h"

enum WATERMINE_STATES
{
    WATERMINE_STATE_WAITFORINTRO = 0,
    WATERMINE_STATE_INTRO,
    WATERMINE_STATE_ACTIVE,
    WATERMINE_STATE_GONE,
    
    WATERMINE_STATE_NUM
};

static const NSString* ANIMKEY_INTRO = @"intro";
static const NSString* ANIMKEY_BASIC = @"basic";

@implementation WaterMineContext
@synthesize numShotsPerRound;
@synthesize initVel;
@synthesize flags = _flags;
@synthesize dynamicsBucketIndex = _dynamicsBucketIndex;
@synthesize weaverX = _weaverX;
@synthesize weaverY = _weaverY;
@synthesize introDelay = _introDelay;
@synthesize initHealth = _initHealth;

@synthesize scatterWeapon;
@synthesize shotCount;
@synthesize state = _state;
@synthesize introTimer = _introTimer;

- (id) init
{
    self = [super init];
    if(self)
    {
        // default configs
        numShotsPerRound = 1;
        initVel = CGPointMake(0.0f, 0.0f);
        _flags = 0;
        _dynamicsBucketIndex = 0;
        self.weaverX = nil;
        self.weaverY = nil;
        _introDelay = 0.0f;
        _initHealth = 5;
        
        // init runtime
        self.scatterWeapon = nil;
        shotCount = 0;
        _state = WATERMINE_STATE_WAITFORINTRO;
        _introTimer = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    self.weaverY = nil;
    self.weaverX = nil;
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
        
        float wVel = [[triggerContext objectForKey:@"weaveXVel"] floatValue];
        float wRange = [[triggerContext objectForKey:@"weaveXRange"] floatValue];
        SineWeaver* newWeaverX = [[SineWeaver alloc] initWithRange:wRange vel:wVel];
        self.weaverX = newWeaverX;
        [newWeaverX release];
        wVel = [[triggerContext objectForKey:@"weaveYVel"] floatValue];
        wRange = [[triggerContext objectForKey:@"weaveYRange"] floatValue];
        SineWeaver* newWeaverY = [[SineWeaver alloc] initWithRange:wRange vel:wVel];
        self.weaverY = newWeaverY;
        [newWeaverY release];
        
        NSNumber* introDelay = [triggerContext objectForKey:@"introDelay"];
        if(introDelay)
        {
            self.introDelay = [introDelay floatValue];
        }
        
        NSNumber* initHealth = [triggerContext objectForKey:@"health"];
        if(initHealth)
        {
            self.initHealth = [initHealth intValue];
        }
    }
}
#pragma mark - EnemyBehaviorContext

- (void) setupFromConfig:(NSDictionary *)config
{
    [self setupFromTriggerContext:config];
}

- (int) getInitHealth
{
    return _initHealth;
}

- (unsigned int) getFlags
{
    return _flags;
}

- (void) setFlags:(unsigned int)newFlags
{
    _flags = newFlags;
}


@end

@implementation WaterMine
@synthesize typeName = _typeName;
@synthesize animName;
@synthesize explosionName;
@synthesize spawnName = _spawnName;

- (id) initWithTypeName:(NSString*)typeName animNamed:(NSString *)name explosionNamed:(NSString*)expName spawnAnimNamed:(NSString *)spawnName
{
    self = [super init];
    if(self)
    {
        self.typeName = typeName;
        self.animName = name;
        self.explosionName = expName;
        self.spawnName = spawnName;
    }
    return self;
}

- (void) dealloc
{
    self.spawnName = nil;
    self.animName = nil;
    self.explosionName = nil;
    self.typeName = nil;
    [super dealloc];
}



#pragma mark - EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    NSString* typeName = _typeName;
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:typeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    // init animClip
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    AnimClipData* clipData = [animData getClipForName:_spawnName];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_INTRO];
    [newClip release];

    clipData = [animData getClipForName:animName];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_BASIC];
    [newClip release];

    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_INTRO];
    
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
    [self initEnemy:givenEnemy];
    givenEnemy.spawnedDelegate = self;  
    
    WaterMineContext* newContext = [[WaterMineContext alloc] init];
    newContext.dynamicsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Dynamics"];
    givenEnemy.behaviorContext = newContext;
    [newContext release];
}

#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    WaterMineContext* myContext = [givenEnemy behaviorContext];
    float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
    float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
    
    if(WATERMINE_STATE_WAITFORINTRO == [myContext state])
    {
        myContext.introTimer -= elapsed;
        if([myContext introTimer] <= 0.0f)
        {
            myContext.state = WATERMINE_STATE_INTRO;

            // start anim
            [givenEnemy.curAnimClip playClipForward:YES];
        }
        else
        {
            // during wait, stay put; so, undo the position advance
            newPosX = [givenEnemy pos].x;
            newPosY = [givenEnemy pos].y;
        }
    }    
    else if(WATERMINE_STATE_INTRO == [myContext state])
    {
        if(ANIMCLIP_STATE_DONE == [[givenEnemy curAnimClip] playbackState])
        {
            // go to ACTIVE
            myContext.state = WATERMINE_STATE_ACTIVE;
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_BASIC];
            [givenEnemy.curAnimClip playClipRandomForward:YES];
            
            [myContext.weaverX reset];
            myContext.weaverX.base = newPosX;
            [myContext.weaverY reset];
            myContext.weaverY.base = newPosY;
        }
    }
    else if(WATERMINE_STATE_ACTIVE == [myContext state])
    {
        // update position
        myContext.weaverX.base += (elapsed * givenEnemy.vel.x);
        myContext.weaverY.base += (elapsed * givenEnemy.vel.y);
        newPosX = [myContext.weaverX update:elapsed];
        newPosY = [myContext.weaverY update:elapsed];
        
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
                
                myContext.state = WATERMINE_STATE_GONE;
            }            
        }
    }
    else // WATERMINE_STATE_GONE
    {
        if(0 == [[givenEnemy firingPath] numOutstandingShots])
        {
            givenEnemy.willRetire = YES;
        }
    }
    givenEnemy.pos = CGPointMake(newPosX, newPosY);
}

- (NSString*) getEnemyTypeName
{
    return _typeName;
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    // do nothing
}


#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    enemy.health--;
    CGRect myAABB = [enemy getAABB];
    CGPoint hitPos = CGPointMake(givenAABB.origin.x + (0.5f * givenAABB.size.width),
                                 myAABB.origin.y);
    [EffectFactory effectNamed:@"BulletHit" atPos:hitPos];
}

- (BOOL) isPlayerCollidable
{
    return NO;
}

- (BOOL) isPlayerWeapon
{
    return NO;
}

- (BOOL) isCollidable
{
    return YES;
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
    WaterMineContext* myContext = [givenEnemy behaviorContext];
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
    WaterMineContext* myContext = [givenEnemy behaviorContext];
    
    // decouple from the parent right away
    if([givenEnemy parentEnemy])
    {
        CGPoint dynPos = [Enemy derivePosFromParentForEnemy:givenEnemy];
        givenEnemy.parentEnemy = nil;
        givenEnemy.pos = dynPos;
        givenEnemy.renderBucketIndex = [myContext dynamicsBucketIndex];
    }

    // setup my weapons
    myContext.shotCount = 0;
    
    // setup my velocity
    givenEnemy.vel = [myContext initVel];
    
    // start with WAITFORINTRO
    myContext.state = WATERMINE_STATE_WAITFORINTRO;
    myContext.introTimer = [myContext introDelay];
}



@end
