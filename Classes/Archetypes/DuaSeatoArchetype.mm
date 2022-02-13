//
//  DuaSeatoArchetype.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "DuaSeatoArchetype.h"
#import "DuaSeatoSpawner.h"
#import "BoarSolo.h"
#import "Sprite.h"
#import "Enemy.h"
#import "EnemyFactory.h"
#import "AnimClipData.h"
#import "AnimClip.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "EffectFactory.h"
#import "Effect.h"
#import "FiringPath.h"
#import "GameManager.h"
#import "SineWeaver.h"
#import "GameObjectSizes.h"
#import "BossWeapon.h"
#import "SoundManager.h"
#import "DynLineSpawner.h"
#import "RenderBucketsManager.h"
#include "MathUtils.h"

enum BehaviorStates
{
    BEHAVIORSTATE_INTRO = 0,
    BEHAVIORSTATE_CRUISING,
    BEHAVIORSTATE_LEAVING,
    BEHAVIORSTATE_RETIRING,
    
    BEHAVIORSTATE_NUM
};

static const int INIT_HEALTH = 20;
static const float EXPLOSION_VEL_X = 0.0f;
static const float EXPLOSION_VEL_Y = -40.0f;

static const float GUNNER_OFFSET_X = 0.0f;
static const float GUNNER_OFFSET_Y = 0.25f;

// firing configs
static const float SHOTSPEED = 50.0f;
static const float FIRING_ANGLES[2][5] = 
{
    {
        M_PI_4 * 0.25f + (0.0f),
        M_PI_4 * 0.25f + (M_PI_4),
        M_PI_4 * 0.25f + (M_PI_2),
        M_PI_4 * 0.25f + (M_PI_4 * 3.0f),
        M_PI_4 * 0.25f + (M_PI)
    },
    {
        0.0f,
        M_PI_4,
        M_PI_2,
        M_PI_4 * 3.0f,
        M_PI
    }
};

@interface DuaSeatoContext (PrivateMethods)
- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@implementation DuaSeatoContext
@synthesize attachedEnemies;
@synthesize timeTillFire;
@synthesize fireSlot;
@synthesize dynamicsBucketIndex = _dynamicsBucketIndex;
@synthesize dynamicsAddonsIndex;
@synthesize behaviorState;
@synthesize introDoneBotLeft;
@synthesize introDoneTopRight;
@synthesize cruisingTimer;
@synthesize enemyTriggerName;
@synthesize weaverX;
@synthesize weaverY;
@synthesize bossWeapon;
@synthesize fireBossWeaponRightAway;
@synthesize timeBetweenShots;
@synthesize shotSpeed;
@synthesize cruisingTimeout;
@synthesize exitVel;
@synthesize cruisingVel;
@synthesize boarSpec;
@synthesize initHealth = _initHealth;
@synthesize flags = _flags;
@synthesize introVel = _introVel;
@synthesize faceDir = _faceDir;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.attachedEnemies = [NSMutableArray array];
        behaviorState = BEHAVIORSTATE_INTRO;
        introDoneBotLeft = CGPointMake(0.0f, 0.0f);
        introDoneTopRight = CGPointMake(1.0f, 1.0f);
        self.weaverX = nil;
        self.weaverY = nil;
        self.bossWeapon = nil;
        self.fireBossWeaponRightAway = NO;
        self.enemyTriggerName = nil;
        self.cruisingTimer = 0.0f;
        self.cruisingTimeout = 3600.0f;
        self.exitVel = CGPointMake(0.0f, 20.0f);
        self.cruisingVel = CGPointMake(0.0f, 0.0f);
        self.boarSpec = nil;
        _initHealth = 10;
        _flags = 0;
        _introVel = CGPointMake(0.0f, -20.0f);
        _faceDir = M_PI;
        
    }
    return self;
}

- (void) dealloc
{
    self.boarSpec = nil;
    self.bossWeapon = nil;
    self.enemyTriggerName = nil;
    self.weaverY = nil;
    self.weaverX = nil;
    self.attachedEnemies = nil;
    [super dealloc];
}

- (void) setupFromTriggerContext:(NSDictionary *)triggerContext
{
    CGRect playArea = [[GameManager getInstance] getPlayArea];
    float doneX = [[triggerContext objectForKey:@"introDoneX"] floatValue];
    float doneY = [[triggerContext objectForKey:@"introDoneY"] floatValue];
    float doneW = [[triggerContext objectForKey:@"introDoneW"] floatValue];
    float doneH = [[triggerContext objectForKey:@"introDoneH"] floatValue];
    self.introDoneBotLeft = CGPointMake((doneX * playArea.size.width) + playArea.origin.x,
                                              (doneY * playArea.size.height) + playArea.origin.y);
    self.introDoneTopRight = CGPointMake((doneW * playArea.size.width) + self.introDoneBotLeft.x,
                                               (doneH * playArea.size.height) + self.introDoneBotLeft.y);
    
    // if timeout specified, use it; otherwise, just leave it at the default long timeout
    NSNumber* timeoutNumber = [triggerContext objectForKey:@"timeout"];
    if(timeoutNumber)
    {
        self.cruisingTimeout = [timeoutNumber floatValue];
        float exitSpeed = [[triggerContext objectForKey:@"exitSpeed"] floatValue];
        float exitDir = [[triggerContext objectForKey:@"exitDir"] floatValue] * M_PI;
        self.exitVel = radiansToVector(CGPointMake(0.0f, -1.0f), exitDir, exitSpeed);
    }
    
    NSNumber* cruisingDirNumber = [triggerContext objectForKey:@"cruisingDir"];
    NSNumber* cruisingSpeedNumber = [triggerContext objectForKey:@"cruisingSpeed"];
    if(cruisingDirNumber && cruisingSpeedNumber)
    {
        float cruisingDir = [cruisingDirNumber floatValue] * M_PI;
        float cruisingSpeed = [cruisingSpeedNumber floatValue];
        self.cruisingVel = radiansToVector(CGPointMake(0.0f, -1.0f), cruisingDir, cruisingSpeed);
    }
    
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
    self.timeBetweenShots = 1.0f / [[triggerContext objectForKey:@"shotFreq"] floatValue];
    self.shotSpeed = [[triggerContext objectForKey:@"shotSpeed"] floatValue];
    NSDictionary* bossWeaponConfig = [triggerContext objectForKey:@"bossWeapon"];
    if(bossWeaponConfig)
    {
        self.bossWeapon = [[BossWeapon alloc] initFromConfig:bossWeaponConfig];
    }
    NSNumber* contextHealth = [triggerContext objectForKey:@"health"];
    if(contextHealth)
    {
        self.initHealth = [contextHealth intValue];
    }
    NSNumber* fireBossWeapon = [triggerContext objectForKey:@"fireBossWeapon"];
    if(fireBossWeapon)
    {
        self.fireBossWeaponRightAway = YES;
    }
    self.boarSpec = [triggerContext objectForKey:@"boarSpec"];

    
    NSNumber* introSpeed = [triggerContext objectForKey:@"introSpeed"];
    NSNumber* introDir = [triggerContext objectForKey:@"introDir"];
    if(introSpeed && introDir)
    {
        _introVel = radiansToVector(CGPointMake(0.0f, -1.0f), [introDir floatValue] * M_PI, [introSpeed floatValue]);
    }
    NSNumber* faceDirNumber = [triggerContext objectForKey:@"faceDir"];
    if(faceDirNumber)
    {
        _faceDir = [faceDirNumber floatValue] * M_PI;
    }
}

#pragma mark - EnemyBehaviorContext

- (void) setupFromConfig:(NSDictionary *)config
{
    [self setupFromTriggerContext:config];
}

- (int) getInitHealth
{
    return [self initHealth];
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

@implementation DuaSeatoArchetype


#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:@"DuaSeato"];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClip
    AnimClipData* clipData = [animData getClipForName:@"DuaSeato"];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    givenEnemy.animClip = newClip;
    [newClip release];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:@"DuaSeato"];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // game status
    givenEnemy.health = INIT_HEALTH;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(id)givenSpawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    givenEnemy.spawnedDelegate = self;  

    // create context
    DuaSeatoContext* newContext = [[DuaSeatoContext alloc] init];
    newContext.fireSlot = 0;
    if(givenSpawnerContext)
    {
        NSDictionary* triggerContext = nil;
        if([givenSpawnerContext isMemberOfClass:[DuaSeatoSpawnerContext class]])
        {
            DuaSeatoSpawnerContext* spawnerContext = (DuaSeatoSpawnerContext*)givenSpawnerContext;
            newContext.dynamicsAddonsIndex = [spawnerContext dynamicsAddonsIndex];
            triggerContext = [spawnerContext triggerContext];
            newContext.introVel = [spawnerContext introVel];
            newContext.faceDir = M_PI;
        }
        else if([givenSpawnerContext isMemberOfClass:[DynLineSpawnerContext class]])
        {
            DynLineSpawnerContext* spawnerContext = (DynLineSpawnerContext*)givenSpawnerContext;
            triggerContext = [spawnerContext triggerContext];
            float introSpeed = [[triggerContext objectForKey:@"introSpeed"] floatValue];
            float introDir = [[triggerContext objectForKey:@"introDir"] floatValue] * M_PI;
            
            // init vel and direction
            newContext.introVel = radiansToVector(CGPointMake(0.0f, -1.0f), introDir, introSpeed);
            newContext.faceDir = M_PI;
            
            newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Addons"];
        }
        if(triggerContext)
        {
            [newContext setupFromTriggerContext:triggerContext];
            givenEnemy.health = [newContext initHealth];
        }
    }    
    else
    {
        newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Addons"];        
    }
    newContext.dynamicsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Dynamics"];
    givenEnemy.behaviorContext = newContext;
    [newContext release];
}


#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    DuaSeatoContext* myContext = [givenEnemy behaviorContext];
    float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
    float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
    
    if(BEHAVIORSTATE_INTRO == myContext.behaviorState)
    {
        CGPoint bl = myContext.introDoneBotLeft;
        CGPoint tr = myContext.introDoneTopRight;
        if((newPosX >= bl.x) && (newPosX <= tr.x) &&
           (newPosY >= bl.y) && (newPosY <= tr.y))
        {
            // when ship is fully in view, go to cruising
            myContext.behaviorState = BEHAVIORSTATE_CRUISING;
            myContext.cruisingTimer = myContext.cruisingTimeout;
            [myContext.weaverX resetRandomWithBase:newPosX];
            [myContext.weaverY resetRandomWithBase:newPosY];
            
            givenEnemy.vel = [myContext cruisingVel];

            // ok to fire
            givenEnemy.readyToFire = YES;
            for(Enemy* cur in myContext.attachedEnemies)
            {
                cur.readyToFire = YES;
            }
        }
    }
    else if(BEHAVIORSTATE_CRUISING == myContext.behaviorState)
    {
        myContext.weaverX.base += (elapsed * givenEnemy.vel.x);
        myContext.weaverY.base += (elapsed * givenEnemy.vel.y);
        
        newPosX = [myContext.weaverX update:elapsed];
        newPosY = [myContext.weaverY update:elapsed];
        myContext.cruisingTimer -= elapsed;
        
        if(0.0f > myContext.cruisingTimer)
        {
            givenEnemy.vel = myContext.exitVel;
            myContext.behaviorState = BEHAVIORSTATE_LEAVING;
        }
        else if(([myContext bossWeapon]) &&
                (([myContext.attachedEnemies count] == 0) || ([myContext fireBossWeaponRightAway])))
        {
            // if I have a boss weapon, fire it when my gunner is gone, or if the triggerContext says to fire right away
            [myContext.bossWeapon enemyFire:givenEnemy elapsed:elapsed];            
        }
        else
        {
            myContext.timeTillFire -= elapsed;
            if(0.0f >= myContext.timeTillFire)
            {
                // shoot in the general direction of the player
                CGPoint playerPos = [[GameManager getInstance] getCamSpacePlayerPos];
                CGPoint myPos = [givenEnemy pos];
                CGPoint targetVec = CGPointMake(playerPos.x - myPos.x, playerPos.y - myPos.y);
                float randomOffset = (randomFrac() * M_PI_2) - M_PI_4;
                float targetRot = vectorToRadians(targetVec) - randomOffset;            
                CGPoint firingDir = CGPointMake(1.0f, 0.0f);
                CGAffineTransform t = CGAffineTransformMakeRotation(targetRot);
                CGPoint dir = CGPointApplyAffineTransform(firingDir, t);
                CGPoint vel = CGPointMake(dir.x * [myContext shotSpeed], dir.y * [myContext shotSpeed]);
                [givenEnemy fireFromPos:myPos withVel:vel];
                
                myContext.timeTillFire = myContext.timeBetweenShots;
            }
        }
        
        // check for out of screen
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        float buffer = 0.3f;
        CGPoint retireBl = CGPointMake((-buffer * playArea.size.width) + playArea.origin.x,
                                       (-buffer * playArea.size.height) + playArea.origin.y);
        CGPoint retireTr = CGPointMake(((1.0f + buffer) * playArea.size.width) + playArea.origin.x,
                                       ((1.0f + buffer) * playArea.size.height) + playArea.origin.y);
        if((newPosX < retireBl.x) || (newPosX > retireTr.x) ||
           (newPosY < retireBl.y) || (newPosY > retireTr.y))
        {
            givenEnemy.willRetire = YES;
            myContext.behaviorState = BEHAVIORSTATE_RETIRING;
        }        
    }
    else if(BEHAVIORSTATE_LEAVING == myContext.behaviorState)
    {
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        float buffer = 0.1f;
        CGPoint retireBl = CGPointMake((-buffer * playArea.size.width) + playArea.origin.x,
                                       (-buffer * playArea.size.height) + playArea.origin.y);
        CGPoint retireTr = CGPointMake(((1.0f + buffer) * playArea.size.width) + playArea.origin.x,
                                       ((1.0f + buffer) * playArea.size.height) + playArea.origin.y);
        if((newPosX < retireBl.x) || (newPosX > retireTr.x) ||
           (newPosY < retireBl.y) || (newPosY > retireTr.y))
        {
            givenEnemy.willRetire = YES;
            myContext.behaviorState = BEHAVIORSTATE_RETIRING;
        }        
    }


    givenEnemy.pos = CGPointMake(newPosX, newPosY);
}

- (NSString*) getEnemyTypeName
{
    return @"DuaSeato";
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    DuaSeatoContext* myContext = [givenEnemy behaviorContext];
    for(Enemy* cur in [myContext attachedEnemies])
    {
        [cur killAllBullets];
    }
}

- (void) enemyBehavior:(Enemy *)givenEnemy receiveTrigger:(NSString *)label
{
    // triggered; so, timeout right away;
    DuaSeatoContext* myContext = [givenEnemy behaviorContext];
    myContext.cruisingTimer = 0.0f;
}


#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    DuaSeatoContext* myContext = [enemy behaviorContext];
    if([myContext.attachedEnemies count] == 0)
    {
        // only takes damage if all its subcomponents are dead
        enemy.health--;
        [EffectFactory effectNamed:@"BulletHit" atPos:enemy.pos];
    }    
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
    return YES;
}

- (BOOL) isCollisionOnFor:(Enemy *)enemy
{
    BOOL result = YES;
    DuaSeatoContext* myContext = [enemy behaviorContext];
    if(myContext.behaviorState != BEHAVIORSTATE_CRUISING)
    {
        result = NO;
    }
    return result;
}


#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    if(![givenEnemy incapacitated])
    {
        DuaSeatoContext* myContext = [givenEnemy behaviorContext];
        unsigned int numAttachedEnemies = [myContext.attachedEnemies count];
        unsigned int index = 0;
        while(index < numAttachedEnemies)
        {
            Enemy* cur = [myContext.attachedEnemies objectAtIndex:index];
            
            // remove parent delegate first so that the kill function won't try to also remove itself from the attachedEnemies
            cur.parentDelegate = nil;
            [cur kill];
            ++index;
        }
        [myContext.attachedEnemies removeAllObjects];
    }
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    DuaSeatoContext* myContext = [givenEnemy behaviorContext];
    unsigned int numAttachedEnemies = [myContext.attachedEnemies count];
    unsigned int index = 0;
    while(index < numAttachedEnemies)
    {
        Enemy* cur = [myContext.attachedEnemies objectAtIndex:index];
        
        // remove parent delegate first so that the kill function won't try to also remove itself from the attachedEnemies
        cur.parentDelegate = nil;
        [cur incapAndKillWithPoints:showPoints];
        ++index;
    }
    [myContext.attachedEnemies removeAllObjects];
    
    // play sound
    [[SoundManager getInstance] playClip:@"BoarFighterExplosion"];

    // play down effect
    [EffectFactory effectNamed:@"Explosion" atPos:givenEnemy.pos];
    
    // show points gained
    if(showPoints)
    {
        [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                               atPos:[givenEnemy pos]];
    }
    
    // drop loots
    [[GameManager getInstance] dequeueAndSpawnPickupAtPos:[givenEnemy pos]];
    
    // returns true for enemy to be killed immediately
    return YES;
}

#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    DuaSeatoContext* myContext = [givenEnemy behaviorContext];
    
    // decouple from the parent right away
    if([givenEnemy parentEnemy])
    {
        CGPoint dynPos = [Enemy derivePosFromParentForEnemy:givenEnemy];
        givenEnemy.parentEnemy = nil;
        givenEnemy.pos = dynPos;
        givenEnemy.renderBucketIndex = [myContext dynamicsBucketIndex];
    }
    
    // setup my weapons
    myContext.timeTillFire = 0.0f;
    
    // setup entrance
    myContext.behaviorState = BEHAVIORSTATE_INTRO;
    givenEnemy.vel = [myContext introVel];
    givenEnemy.rotate = [myContext faceDir];
    
    // spawn gunner
    {
        CGSize myRenderSize = [[givenEnemy renderer] size];
        
        // NOTE: this enemy lives in layer-space just like its parent
        // no need to rotate init pos here because addon inherits its parent's rotate
        CGPoint newPos = CGPointMake((GUNNER_OFFSET_X * myRenderSize.width),
                                     (GUNNER_OFFSET_Y * myRenderSize.height));        
        
        Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"BoarSoloGun" AtPos:newPos];
        newEnemy.renderBucketIndex = myContext.dynamicsAddonsIndex;
        
        // attach myself as parent
        newEnemy.parentEnemy = givenEnemy;
        newEnemy.parentDelegate = self;
        
        // don't fire until Speedo gives the ok
        newEnemy.readyToFire = NO;
        
        // half prob between Helmet and no helmet
        float dice = randomFrac();
        if(dice <= 0.7f)
        {
            [BoarSolo enemy:newEnemy replaceAnimWithType:BOARSOLO_ANIMTYPE_HELMET];
        }
        else
        {
            [BoarSolo enemy:newEnemy replaceAnimWithType:BOARSOLO_ANIMTYPE_GUN];            
        }
        // init its context given the spawner's context
        BoarSoloContext* newContext = [[BoarSoloContext alloc] init];
        newContext.timeTillFire = 0.0f;
        newContext.idleTimer = 0.0f;
        newContext.idleDelay = 0.5f;
        newContext.hasCargo = YES;
        if([myContext boarSpec])
        {
            [newContext setupFromTriggerContext:[myContext boarSpec]];
        }
        newEnemy.health = [newContext initHealth];
        newEnemy.behaviorContext = newContext;
        [newContext release];
        
        // create gun for BoarSolo
        [BoarSolo enemy:newEnemy createGunAddonInBucket:[myContext dynamicsAddonsIndex]];
        
        // add it to spawnedEnemies
        [myContext.attachedEnemies addObject:newEnemy];
        [newEnemy spawn];
        [newEnemy release];
    }
}

#pragma mark - EnemyParentDelegate
- (void) removeFromParent:(Enemy*)parent enemy:(Enemy*)givenEnemy
{
    DuaSeatoContext* myContext = [parent behaviorContext];
    [myContext.attachedEnemies removeObject:givenEnemy];
}

@end
