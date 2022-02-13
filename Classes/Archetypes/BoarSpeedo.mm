//
//  BoarSpeedo.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/6/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "BoarSpeedo.h"
#import "Addon.h"
#import "AddonFactory.h"
#import "Sprite.h"
#import "Enemy.h"
#import "EnemyFactory.h"
#import "GameObjectSizes.h"
#import "AnimClipData.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "AnimClip.h"
#import "DynamicsSpawner.h"
#import "DynLineSpawner.h"
#import "Effect.h"
#import "EffectFactory.h"
#import "TopCam.h"
#import "RenderBucketsManager.h"
#import "GameManager.h"
#import "BoarSolo.h"
#import "FiringPath.h"
#import "Loot.h"
#import "LootFactory.h"
#import "SoundManager.h"
#include "MathUtils.h"

enum BehaviorStates
{
    BEHAVIORSTATE_INTRO = 0,
    BEHAVIORSTATE_CRUISING,
    BEHAVIORSTATE_LEAVING,
    BEHAVIORSTATE_RETIRING,
    BEHAVIORSTATE_PREINTRO,
    
    BEHAVIORSTATE_NUM
};

enum BehaviorCat
{
    BEHAVIORCATEGORY_GUNNER = 0,
    BEHAVIORCATEGORY_SCATTER,
    BEHAVIORCATEGORY_SINGLE,        // the easiest
    BEHAVIORCATEGORY_DOUBLE,
    
    BEHAVIORCATEGORY_NUM
};

// gunner rendering
static const float GUNNER_OFFSET_X = 0.0f;
static const float GUNNER_OFFSET_Y = -0.48f;
static const float GUNNER2_OFFSET_X = 0.0f;
static const float GUNNER2_OFFSET_Y = 0.0f;

// timer
static const float CRUISING_SECS = 10.0f;

// movement
static const float WEAVE_RANGE_MIN = 2.0f;
static const float WEAVE_RANGE = 6.0f;
static const float WEAVE_VEL = M_PI_4;
static const float WEAVE_Y_VEL = 0.5f * M_PI_4;
static const float WEAVE_Y_RANGE = 30.0f;

// firing configs
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


static NSString* const ARCHETYPE_NAME = @"BoarSpeedo";

@implementation BoarSpeedoContext
@synthesize layerDistance;
@synthesize attachedEnemies;
@synthesize cruisingTimeout;
@synthesize cruisingTimer;
@synthesize enemyTriggerName;
@synthesize initPos;
@synthesize weaveVel;
@synthesize weaveParam;
@synthesize weaveRange;
@synthesize weaveYVel;
@synthesize weaveYParam;
@synthesize weaveYRange;
@synthesize introDoneBotLeft;
@synthesize introDoneTopRight;
@synthesize initVel;
@synthesize hasSetInitVel;
@synthesize dynamicsShadowsIndex;
@synthesize dynamicsBucketIndex;
@synthesize dynamicsAddonsIndex;
@synthesize behaviorState;
@synthesize behaviorCategory;
@synthesize timeBetweenShots;
@synthesize shotSpeed;
@synthesize timeToCool;
@synthesize timeToOverheat;
@synthesize timeTillFire;
@synthesize fireSlot;
@synthesize overHeatTimer;
@synthesize isDynamic;
@synthesize wakeStarted;
@synthesize behaviorCategoryReg;
@synthesize boarSpec;
@synthesize initHealth = _initHealth;

// preIntro
@synthesize preIntroVel = _preIntroVel;
@synthesize preIntroBl = _preIntroBl;
@synthesize preIntroTr = _preIntroTr;
@synthesize hasPreIntro = _hasPreIntro;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.attachedEnemies = [NSMutableArray array];
        behaviorState = BEHAVIORSTATE_INTRO;
        behaviorCategory = BEHAVIORCATEGORY_GUNNER;
        isDynamic = YES;
        wakeStarted = NO;
        cruisingTimer = 0.0f;
        weaveVel = 0.0f;
        weaveParam = 0.0f;
        weaveYVel = 0.0f;
        weaveYParam = 0.0f;
        weaveYRange = 0.0f;
        introDoneBotLeft = CGPointMake(0.0f, 0.0f);
        introDoneTopRight = CGPointMake(100.0f, 150.0f);
        
        dynamicsShadowsIndex = 0;
        dynamicsBucketIndex = 0;
        dynamicsAddonsIndex = 0;
        
        // init behavior cateogry lookup
        self.behaviorCategoryReg = [NSMutableDictionary dictionary];
        [behaviorCategoryReg setObject:[NSNumber numberWithUnsignedInt:BEHAVIORCATEGORY_GUNNER] forKey:@"BoarSoloGun"];
        [behaviorCategoryReg setObject:[NSNumber numberWithUnsignedInt:BEHAVIORCATEGORY_SCATTER] forKey:@"ScatterGun"];
        [behaviorCategoryReg setObject:[NSNumber numberWithUnsignedInt:BEHAVIORCATEGORY_SINGLE] forKey:@"SingleGun"];
        [behaviorCategoryReg setObject:[NSNumber numberWithUnsignedInt:BEHAVIORCATEGORY_DOUBLE] forKey:@"DoubleGun"];
        self.boarSpec = nil;
        _flags = 0;
        _initHealth = 15;
        
        hasSetInitVel = NO;
        
        // preIntro
        _hasPreIntro = NO;
        _preIntroVel = CGPointMake(0.0f, 0.0f);
        _preIntroBl = CGPointMake(0.0f, 0.0f);
        _preIntroTr = CGPointMake(100.0f, 150.0f);
    }
    return self;
}

- (void) dealloc
{
    self.boarSpec = nil;
    self.behaviorCategoryReg = nil;
    self.attachedEnemies = nil;
    [super dealloc];
}

- (unsigned int) behaviorCategoryFromName:(NSString *)name
{
    unsigned int result = BEHAVIORCATEGORY_NUM;
    NSNumber* cat = [behaviorCategoryReg objectForKey:name];
    if(cat)
    {
        result = [cat floatValue];
    }
    return result;
}

#pragma mark - EnemyBehaviorContext

- (void) setupFromConfig:(NSDictionary *)config
{
    if(config)
    {
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        float doneX = [[config objectForKey:@"introDoneX"] floatValue];
        float doneY = [[config objectForKey:@"introDoneY"] floatValue];
        float doneW = [[config objectForKey:@"introDoneW"] floatValue];
        float doneH = [[config objectForKey:@"introDoneH"] floatValue];
        self.introDoneBotLeft = CGPointMake((doneX * playArea.size.width) + playArea.origin.x,
                                            (doneY * playArea.size.height) + playArea.origin.y);
        self.introDoneTopRight = CGPointMake((doneW * playArea.size.width) + self.introDoneBotLeft.x,
                                             (doneH * playArea.size.height) + self.introDoneBotLeft.y);
        self.weaveRange = [[config objectForKey:@"weaveXRange"] floatValue];
        self.weaveYRange = [[config objectForKey:@"weaveYRange"] floatValue];
        NSNumber* configWeaveVel = [config objectForKey:@"weaveXVel"];
        NSNumber* configWeaveYVel = [config objectForKey:@"weaveYVel"];
        if(configWeaveVel && configWeaveYVel)
        {
            self.weaveVel = [configWeaveVel floatValue] * M_PI;
            self.weaveYVel = [configWeaveYVel floatValue] * M_PI;
        }
        
        self.behaviorCategory = [self behaviorCategoryFromName:[config objectForKey:@"behaviorCategory"]];
        self.timeBetweenShots = 1.0f / [[config objectForKey:@"shotFreq"] floatValue];
        self.shotSpeed = [[config objectForKey:@"shotSpeed"] floatValue];
        self.timeToOverheat = [[config objectForKey:@"timeToOverheat"] floatValue];
        self.timeToCool = [[config objectForKey:@"timeToCool"] floatValue];
        
        NSNumber* timeout = [config objectForKey:@"timeout"];
        if(timeout)
        {
            self.cruisingTimeout = [timeout floatValue];
        }
        else
        {
            self.cruisingTimeout = 3600.0f;    // very large number for unspecified timeout;
            // typically for a blocked enemy set
        }
        self.boarSpec = [config objectForKey:@"boarSpec"];
        
        NSNumber* configHealth = [config objectForKey:@"health"];
        if(configHealth)
        {
            _initHealth = [configHealth intValue];
        }
        
        if(!hasSetInitVel)
        {
            float introSpeed = [[config objectForKey:@"introSpeed"] floatValue];
            float introDir = [[config objectForKey:@"introDir"] floatValue] * M_PI;
            self.initVel = radiansToVector(CGPointMake(0.0f, -1.0f), introDir, introSpeed);
            self.hasSetInitVel = YES;
        }
        
        NSNumber* preIntroDir = [config objectForKey:@"preIntroDir"];
        NSNumber* preIntroSpeed = [config objectForKey:@"preIntroSpeed"];
        NSNumber* preIntroX = [config objectForKey:@"preIntroX"];
        NSNumber* preIntroY = [config objectForKey:@"preIntroY"];
        NSNumber* preIntroW = [config objectForKey:@"preIntroW"];
        NSNumber* preIntroH = [config objectForKey:@"preIntroH"];
        if(preIntroDir && preIntroSpeed && preIntroX && preIntroY && preIntroW && preIntroH)
        {   
            _hasPreIntro = YES;
            _preIntroBl = CGPointMake(([preIntroX floatValue] * playArea.size.width) + playArea.origin.x,
                                      ([preIntroY floatValue] * playArea.size.height) + playArea.origin.y);
            _preIntroTr = CGPointMake(([preIntroW floatValue] * playArea.size.width) + _preIntroBl.x,
                                      ([preIntroH floatValue] * playArea.size.height) + _preIntroBl.y);
            _preIntroVel = radiansToVector(CGPointMake(0.0f, -1.0f), 
                                           [preIntroDir floatValue] * M_PI, 
                                           [preIntroSpeed floatValue]);
        }
    }
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

@implementation BoarSpeedo
#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    // renderer
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:ARCHETYPE_NAME];
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:ARCHETYPE_NAME];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize colSize:colSize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    // init animClip
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    AnimClipData* clipData = [animData getClipForName:ARCHETYPE_NAME];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    givenEnemy.animClip = newClip;
    [newClip release];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // game status
    givenEnemy.health = 15;
    
    // hold off firing until CRUISING
    givenEnemy.readyToFire = NO;
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(id)givenSpawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    givenEnemy.spawnedDelegate = self;  
    
    NSDictionary* triggerContext = nil;
    NSString* triggerName = nil;
    BoarSpeedoContext* newContext = [[BoarSpeedoContext alloc] init];
    newContext.attachedEnemies = [NSMutableArray array];
    newContext.behaviorState = BEHAVIORSTATE_INTRO;
    newContext.initPos = [givenEnemy pos];
    // start weaveParam at either 0 or PI because we need to start the weave on x=0
    // otherwise, the ship will pop when it's done with the INTRO state
    if(0.5f > randomFrac())
    {
        newContext.weaveParam = 0.0f;
    }
    else
    {
        newContext.weaveParam = M_PI;
    }
    if(0.5f > randomFrac())
    {
        newContext.weaveYParam = 0.0f;
    }
    else
    {
        newContext.weaveYParam = M_PI;
    }
    newContext.weaveVel = WEAVE_VEL;
    newContext.weaveYVel = WEAVE_Y_VEL;
    if(givenSpawnerContext)
    {
        if([givenSpawnerContext isMemberOfClass:[DynamicsSpawnerContext class]])
        {
            DynamicsSpawnerContext* spawnerContext = (DynamicsSpawnerContext*)givenSpawnerContext;
            triggerContext = [spawnerContext triggerContext];
            triggerName = [spawnerContext triggerName];
            float initVelX = [[triggerContext objectForKey:@"initVelX"] floatValue];
            float initVelY = [[triggerContext objectForKey:@"initVelY"] floatValue];
            newContext.initVel = CGPointMake(initVelX, initVelY);
            newContext.hasSetInitVel = YES;
            
            // init its context given the spawner's context
            newContext.layerDistance = [spawnerContext layerDistance];
            newContext.dynamicsShadowsIndex = [spawnerContext dynamicsShadowsIndex];
            newContext.dynamicsBucketIndex = [spawnerContext dynamicsBucketIndex];
            newContext.dynamicsAddonsIndex = [spawnerContext dynamicsAddonsIndex];
        }
        else if([givenSpawnerContext isMemberOfClass:[DynLineSpawnerContext class]])
        {
            DynLineSpawnerContext* spawnerContext = (DynLineSpawnerContext*)givenSpawnerContext;
            triggerContext = [spawnerContext triggerContext];
            triggerName = [spawnerContext triggerName];
            float introSpeed = [[triggerContext objectForKey:@"introSpeed"] floatValue];
            float introDir = [[triggerContext objectForKey:@"introDir"] floatValue] * M_PI;
            newContext.initVel = radiansToVector(CGPointMake(0.0f, -1.0f), introDir, introSpeed);
            newContext.hasSetInitVel = YES;
            
            TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
            newContext.layerDistance = [gameCam distanceMaxLayer];
            newContext.dynamicsShadowsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrPreDynamics"];
            newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrPostDynamics"];
            newContext.dynamicsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrDynamics"];

            givenEnemy.isGrounded = NO;
        }
    }
    else
    {
        TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
        newContext.layerDistance = [gameCam distanceMaxLayer];
        newContext.dynamicsShadowsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrPreDynamics"];
        newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrPostDynamics"];
        newContext.dynamicsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrDynamics"];

        givenEnemy.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrDynamics"];
        givenEnemy.isGrounded = NO;        
    }
    
    // init based on trigger context
    CGRect playArea = [[GameManager getInstance] getPlayArea];
    if(triggerContext)
    {
        [newContext setupFromConfig:triggerContext];
        givenEnemy.health = [newContext initHealth];
    }
    else
    {
        newContext.weaveRange = WEAVE_RANGE_MIN + (randomFrac() * WEAVE_RANGE);
        newContext.weaveYRange = WEAVE_Y_RANGE;

        newContext.introDoneBotLeft = CGPointMake(playArea.origin.x,
                                                  playArea.origin.y);
        newContext.introDoneTopRight = CGPointMake(playArea.size.width + newContext.introDoneBotLeft.x,
                                                   playArea.size.height + newContext.introDoneBotLeft.y);
        newContext.initVel = CGPointMake(0.0f, -30.0f);
        newContext.timeBetweenShots = 0.8f;
        newContext.shotSpeed = 50.0f;
        newContext.timeToOverheat = 3.0f;
        newContext.timeToCool = 0.5f;
        newContext.cruisingTimeout = 10.0f;
    }
    
    // register myself to receive a trigger message from GameManager
    if(triggerName)
    {
        newContext.enemyTriggerName = [NSString stringWithFormat:@"%@_timeout", triggerName];    
        [[GameManager getInstance] registerTriggerEnemy:givenEnemy forTriggerLabel:[newContext enemyTriggerName]];
    }
    
    // put my wake addon to my shadows bucket
    Addon* wakeAddon = [[[LevelManager getInstance] addonFactory] createAddonNamed:@"WakeSpeedo" atPos:CGPointMake(0.0f, 0.0f)];
    wakeAddon.renderBucket = [newContext dynamicsShadowsIndex];
    wakeAddon.ownsBucket = YES;
    [givenEnemy.effectAddons addObject:wakeAddon];
    [wakeAddon release];
    
    givenEnemy.behaviorContext = newContext;
    [newContext release];
}


#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    BoarSpeedoContext* myContext = [givenEnemy behaviorContext];
    float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
    float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
    
    if(BEHAVIORSTATE_PREINTRO == [myContext behaviorState])
    {
        CGPoint bl = myContext.preIntroBl;
        CGPoint tr = myContext.preIntroTr;
        if((newPosX >= bl.x) && (newPosX <= tr.x) &&
           (newPosY >= bl.y) && (newPosY <= tr.y))
        {
            myContext.behaviorState = BEHAVIORSTATE_INTRO;
            givenEnemy.vel = [myContext initVel];
        }
    }
    else if(BEHAVIORSTATE_INTRO == myContext.behaviorState)
    {
        CGPoint bl = myContext.introDoneBotLeft;
        CGPoint tr = myContext.introDoneTopRight;
        if((newPosX >= bl.x) && (newPosX <= tr.x) &&
           (newPosY >= bl.y) && (newPosY <= tr.y))
        {
            // when ship is fully in view, go to cruising
            myContext.behaviorState = BEHAVIORSTATE_CRUISING;
            myContext.initPos = CGPointMake(newPosX, newPosY);
            myContext.cruisingTimer = myContext.cruisingTimeout;
            
            CGPoint newVel = givenEnemy.vel;
            newVel.y = 0.0f;
            givenEnemy.vel = newVel;
            
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
        myContext.cruisingTimer -= elapsed;
        if((myContext.cruisingTimer <= 0.0f) ||
           ((myContext.behaviorCategory == BEHAVIORCATEGORY_DOUBLE) && ([myContext.attachedEnemies count] == 0)))
        {
            // timeout, leave
            // OR, DOUBLE and both gunners are gone, leave
            givenEnemy.vel = CGPointMake(0.0f, -30.0f);
            myContext.behaviorState = BEHAVIORSTATE_LEAVING;
        }
        else
        {
            // update movement
            float newInitPosX = myContext.initPos.x + (elapsed * givenEnemy.vel.x);
            float newParam = myContext.weaveParam + (elapsed * myContext.weaveVel);
            if(newParam > (M_PI * 2.0f))
            {
                newParam = newParam - (M_PI * 2.0f);
            }        
            newPosX = newInitPosX + (sinf(newParam) * myContext.weaveRange);
            
            float newInitPosY = myContext.initPos.y + (elapsed * givenEnemy.vel.y);
            float newYParam = myContext.weaveYParam + (elapsed * myContext.weaveYVel);
            if(newYParam > (M_PI * 2.0f))
            {
                newYParam = newYParam - (M_PI * 2.0f);
            }
            newPosY = newInitPosY + (sinf(newYParam) * myContext.weaveYRange);
            
            myContext.weaveParam = newParam;
            myContext.weaveYParam = newYParam;
            
            // also slowly move initPosY according to velocity
            CGPoint newInitPos = [myContext initPos];
            newInitPos.y = newInitPosY;
            myContext.initPos = newInitPos;
            
            myContext.timeTillFire -= elapsed;
            myContext.overHeatTimer -= elapsed;
            if(myContext.overHeatTimer <= 0.0f)
            {
                // gun has overheat, stop firing for cooldown duration
                myContext.timeTillFire = myContext.timeToCool;
                myContext.overHeatTimer = myContext.timeToOverheat;
            }
            if(myContext.timeTillFire <= 0.0f)
            {
                if([myContext behaviorCategory] == BEHAVIORCATEGORY_GUNNER)
                {
                    // only fire if my gunner is gone
                    if([myContext.attachedEnemies count] == 0)
                    {
                        CGPoint firingVel = CGPointMake(0.0f, -myContext.shotSpeed);
                        [givenEnemy fireWithVel:firingVel];
                    }
                    myContext.timeTillFire = myContext.timeBetweenShots;                
                }
                else if([myContext behaviorCategory] == BEHAVIORCATEGORY_SCATTER)
                {
                    CGPoint firingDir = CGPointMake(-1.0f, 0.0f);
                    
                    for(int i = 0; i < 5; ++i)
                    {
                        CGAffineTransform t = CGAffineTransformMakeRotation(FIRING_ANGLES[myContext.fireSlot][i]);
                        CGPoint dir = CGPointApplyAffineTransform(firingDir, t);
                        CGPoint vel = CGPointMake(dir.x * myContext.shotSpeed, dir.y * myContext.shotSpeed);
                        [givenEnemy fireWithVel:vel];
                    }
                    myContext.timeTillFire = myContext.timeBetweenShots;
                    if(myContext.fireSlot == 0)
                    {
                        myContext.fireSlot = 1;
                    }
                    else
                    {
                        myContext.fireSlot = 0;
                    }
                }
            }
        }
    }
    else if(BEHAVIORSTATE_LEAVING == myContext.behaviorState)
    {
        if(newPosY < (-0.5f * givenEnemy.renderer.size.height))
        {
            // completely out of the screen, retire it
            givenEnemy.willRetire = YES;
            myContext.behaviorState = BEHAVIORSTATE_RETIRING;
        }
    }
        
    givenEnemy.pos = CGPointMake(newPosX, newPosY);
}

- (NSString*) getEnemyTypeName
{
    return ARCHETYPE_NAME;
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    BoarSpeedoContext* myContext = [givenEnemy behaviorContext];
    for(Enemy* cur in [myContext attachedEnemies])
    {
        [cur killAllBullets];
    }
}

- (void) enemyBehavior:(Enemy *)givenEnemy receiveTrigger:(NSString *)label
{
    // triggered; so, timeout right away;
    BoarSpeedoContext* myContext = [givenEnemy behaviorContext];
    myContext.cruisingTimer = 0.0f;
}

#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    BoarSpeedoContext* myContext = [enemy behaviorContext];
    if([myContext.attachedEnemies count] == 0)
    {
        CGRect myAABB = [enemy getAABB];
        CGPoint hitPos = CGPointMake(givenAABB.origin.x + (0.5f * givenAABB.size.width),
                                     myAABB.origin.y);
        [EffectFactory effectNamed:@"BulletHit" atPos:hitPos];
        
        
        // only takes damage if all its subcomponents are dead
        enemy.health--;
    }
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
    BoarSpeedoContext* myContext = [enemy behaviorContext];
    if(([myContext behaviorState] == BEHAVIORSTATE_INTRO) ||
       ([myContext behaviorState] == BEHAVIORSTATE_PREINTRO))
    {
        result = NO;
    }
    else if([[myContext attachedEnemies] count])
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
        BoarSpeedoContext* myContext = [givenEnemy behaviorContext];
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
    // play sound
    [[SoundManager getInstance] playClip:@"SpeedoExplosion"];

    // play down effect
    [EffectFactory effectNamed:@"Explosion2" atPos:givenEnemy.pos];
    
    BoarSpeedoContext* myContext = [givenEnemy behaviorContext];

    // show points gained
    if(showPoints)
    {
        if([myContext behaviorCategory] != BEHAVIORCATEGORY_SINGLE)
        {
            [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                                   atPos:[givenEnemy pos]]; 
        }
    }
    
    // kill off any attached enemies
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

    // drop loots
    if(!([myContext behaviorCategory] == BEHAVIORCATEGORY_SCATTER))
    {
        if([[GameManager getInstance] shouldReleasePickups])
        {   
            // dequeue game manager pickup
            NSString* pickupType = [[GameManager getInstance] dequeueNextUpgradePack];
            if(pickupType)
            {
                CGPoint myPos = [givenEnemy pos];
                Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:pickupType atPos:myPos 
                                                                                 isDynamics:YES 
                                                                        groundedBucketIndex:0 
                                                                              layerDistance:0.0f];
                [newLoot spawn];
                [newLoot release];
            }
        }
    }    
    // returns true for enemy to be killed immediately
    return YES;
}


#pragma mark - EnemyParentDelegate
- (void) removeFromParent:(Enemy*)parent enemy:(Enemy*)givenEnemy
{
    BoarSpeedoContext* myContext = [parent behaviorContext];
    [myContext.attachedEnemies removeObject:givenEnemy];
    
    if(([myContext.attachedEnemies count] == 0) && (myContext.behaviorCategory == BEHAVIORCATEGORY_SINGLE))
    {
        // for SINGLEs, killing the gunner also kills the boat
        [parent incapAndKillWithPoints:NO];
    }
}

#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    BoarSpeedoContext* myContext = [givenEnemy behaviorContext];
    if(![myContext wakeStarted])
    {
        // there is only one wake for speedo
        Addon* effectAddon = [givenEnemy.effectAddons objectAtIndex:0];
        [effectAddon.anim playClipForward:YES];
        myContext.wakeStarted = YES;
    }
    
    // setup my weapons
    myContext.timeTillFire = 0.1f;
    myContext.overHeatTimer = myContext.timeToOverheat;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];

    
    
    // if hasPreIntro, start it up instead of INTRO
    if([myContext hasPreIntro])
    {
        myContext.behaviorState = BEHAVIORSTATE_PREINTRO;
        givenEnemy.vel = myContext.preIntroVel;
        
        // decouple from the parent right away (PREINTRO is used by SubSpawner that always parents its spawned enemies)
        if([givenEnemy parentEnemy])
        {
            CGPoint dynPos = [Enemy derivePosFromParentForEnemy:givenEnemy];
            givenEnemy.parentEnemy = nil;
            givenEnemy.pos = dynPos;
        }
    }
    else
    {
        // setup entrance velocity
        givenEnemy.vel = myContext.initVel;        
    }
    
    // set my bucket index from context
    givenEnemy.renderBucketIndex = [myContext dynamicsBucketIndex];
    
    // spawn subcomponents
    if(([myContext behaviorCategory] == BEHAVIORCATEGORY_GUNNER) ||
       ([myContext behaviorCategory] == BEHAVIORCATEGORY_SINGLE) ||
       ([myContext behaviorCategory] == BEHAVIORCATEGORY_DOUBLE))
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
        
        // randomly select between no-helmet and helmet2
        if(randomFrac() <= 0.f)
        {
            [BoarSolo enemy:newEnemy replaceAnimWithType:BOARSOLO_ANIMTYPE_HELMET2];
        }
        else
        {
            [BoarSolo enemy:newEnemy replaceAnimWithType:BOARSOLO_ANIMTYPE_GUN];            
        }

        // init its context given the spawner's context
        BoarSoloContext* newContext = [[BoarSoloContext alloc] init];
        newContext.idleDelay = 1.0f;
        newContext.timeTillFire = 0.0f;
        newContext.layerDistance = [myContext layerDistance];
        newContext.hasCargo = NO;
        if([myContext boarSpec])
        {
            [newContext setupFromTriggerContext:[myContext boarSpec]];
        }
        newEnemy.behaviorContext = newContext;
        newEnemy.health = [newContext initHealth];
        [newContext release];
        
        // create gun for BoarSolo
        [BoarSolo enemy:newEnemy createGunAddonInBucket:[myContext dynamicsAddonsIndex]];
        
        // add it to spawnedEnemies
        [myContext.attachedEnemies addObject:newEnemy];
        [newEnemy spawn];
        [newEnemy release];
    }

    // spawn the second gunner for DOUBLE
    if([myContext behaviorCategory] == BEHAVIORCATEGORY_DOUBLE)
    {
        CGSize myRenderSize = [[givenEnemy renderer] size];
        
        // NOTE: this enemy lives in layer-space just like its parent
        // no need to rotate init pos here because addon inherits its parent's rotate
        CGPoint newPos = CGPointMake((GUNNER2_OFFSET_X * myRenderSize.width),
                                     (GUNNER2_OFFSET_Y * myRenderSize.height));        
        
        Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"BoarSoloGun" AtPos:newPos];
        newEnemy.renderBucketIndex = myContext.dynamicsAddonsIndex;
        
        // attach myself as parent
        newEnemy.parentEnemy = givenEnemy;
        newEnemy.parentDelegate = self;
        
        // don't fire until Speedo gives the ok
        newEnemy.readyToFire = NO;

        // randomly select between helmet, helmet2, and gun
        float dice = randomFrac();
        if(dice <= 0.7f)
        {
            [BoarSolo enemy:newEnemy replaceAnimWithType:BOARSOLO_ANIMTYPE_HELMET2];
        }
        else
        {
            [BoarSolo enemy:newEnemy replaceAnimWithType:BOARSOLO_ANIMTYPE_GUN];                        
        }

        // init its context given the spawner's context
        BoarSoloContext* newContext = [[BoarSoloContext alloc] init];
        newContext.idleDelay = 0.8f;
        newContext.timeTillFire = 0.1f;
        newContext.layerDistance = [myContext layerDistance];
        newContext.hasCargo = NO;
        if([myContext boarSpec])
        {
            [newContext setupFromTriggerContext:[myContext boarSpec]];
        }
        newEnemy.behaviorContext = newContext;
        newEnemy.health = [newContext initHealth];
        [newContext release];
        
        // create gun for BoarSolo
        [BoarSolo enemy:newEnemy createGunAddonInBucket:[myContext dynamicsAddonsIndex]];
        
        // add it to spawnedEnemies
        [myContext.attachedEnemies addObject:newEnemy];
        [newEnemy spawn];
        [newEnemy release];        
    }
}

@end
