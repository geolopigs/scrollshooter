//
//  CargoShipB.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/10/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "CargoShipB.h"
#import "DynamicsSpawner.h"
#import "Sprite.h"
#import "Enemy.h"
#import "EnemyFactory.h"
#import "GameObjectSizes.h"
#import "AnimClipData.h"
#import "AnimClip.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "AnimClip.h"
#import "Effect.h"
#import "EffectFactory.h"
#import "TopCam.h"
#import "RenderBucketsManager.h"
#import "GameManager.h"
#import "AddonData.h"
#import "Addon.h"
#import "AddonFactory.h"
#import "Loot.h"
#import "LootFactory.h"
#import "CargoPack.h"
#include "MathUtils.h"

enum BehaviorStates
{
    BEHAVIORSTATE_INTRO = 0,
    BEHAVIORSTATE_CRUISING,
    BEHAVIORSTATE_LEAVING,
    BEHAVIORSTATE_RETIRING,
    
    BEHAVIORSTATE_NUM
};

static NSString* const ARCHETYPE_NAME = @"CargoShipB";

// health
static const int INIT_HEALTH = 10;

// timer
static const float CRUISING_SECS = 8.0f;

// movement
static const float WEAVE_RANGE_MIN = 5.0f;
static const float WEAVE_RANGE = 6.0f;
static const float WEAVE_VEL = M_PI_4;

static const float WEAVE_Y_VEL = 0.5f * M_PI_4;
static const float WEAVE_Y_RANGE = 8.0f;
static const float INTROVEL_X = 0.0f;
static const float INTROVEL_Y = -10.0f;
static const float CRUISING_VEL_Y = 0.0f;
static const float OUTWARD_VEL_X = -5.0f;
static const float OUTWARD_VEL_Y = -25.0f;

@implementation CargoShipBContext
@synthesize dynamicsBucketIndex;
@synthesize dynamicsShadowsIndex;
@synthesize dynamicsAddonsIndex;
@synthesize behaviorState;
@synthesize cruisingTimer;
@synthesize initPos;
@synthesize weaveVel;
@synthesize weaveParam;
@synthesize weaveRange;
@synthesize weaveYVel;
@synthesize weaveYParam;
@synthesize weaveYRange;
@synthesize cargoAddons;
@synthesize cargoReleaseTriggerName;
@synthesize addonData;

- (id) init
{
    self = [super init];
    if(self)
    {
        dynamicsBucketIndex = 0;
        dynamicsShadowsIndex = 0;
        dynamicsAddonsIndex = 0;
        behaviorState = BEHAVIORSTATE_INTRO;
        cruisingTimer = 0.0f;
        initPos = CGPointMake(0.0f, 0.0f);
        weaveVel = 0.0f;
        weaveParam = 0.0f;
        weaveRange = 0.0f;
        weaveYVel = 0.0f;
        weaveYParam = 0.0f;
        weaveYRange = 0.0f;
        self.cargoAddons = [NSMutableArray array];
        self.addonData = nil;
    }
    return self;
}

- (void) dealloc
{
    self.cargoReleaseTriggerName = nil;
    self.cargoAddons = nil;
    self.addonData = nil;
    [super dealloc];
}

@end

@implementation CargoShipB
#pragma mark - EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    // renderer
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:ARCHETYPE_NAME];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
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
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:ARCHETYPE_NAME];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // game status
    givenEnemy.health = INIT_HEALTH;
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(DynamicsSpawnerContext*)spawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    givenEnemy.spawnedDelegate = self;
        
    // init its context given the spawner's context
    CargoShipBContext* newContext = [[CargoShipBContext alloc] init];
    newContext.dynamicsBucketIndex = [spawnerContext dynamicsBucketIndex];
    newContext.dynamicsShadowsIndex = [spawnerContext dynamicsShadowsIndex];
    newContext.dynamicsAddonsIndex = [spawnerContext dynamicsAddonsIndex];
    
    // introduce ship from the top
    newContext.behaviorState = BEHAVIORSTATE_INTRO;
    givenEnemy.vel = CGPointMake(INTROVEL_X, INTROVEL_Y);
    
    newContext.initPos = [givenEnemy pos];
    newContext.weaveRange = WEAVE_RANGE_MIN + (randomFrac() * WEAVE_RANGE);
    newContext.weaveVel = WEAVE_VEL;
    newContext.weaveYRange = WEAVE_Y_RANGE;
    newContext.weaveYVel = WEAVE_Y_VEL;
    
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

    // addons placement
    newContext.addonData = [[LevelManager getInstance] getAddonDataForName:@"CargoShipB_addons"];
    
    // register myself to receive a trigger message from GameManager
    newContext.cargoReleaseTriggerName = [NSString stringWithFormat:@"%@_cargo", [spawnerContext triggerName]];    
    [[GameManager getInstance] registerTriggerEnemy:givenEnemy forTriggerLabel:[newContext cargoReleaseTriggerName]];
    
    givenEnemy.behaviorContext = newContext;
    [newContext release];
}


#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    CargoShipBContext* myContext = [givenEnemy behaviorContext];
    float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
    float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);

    if(BEHAVIORSTATE_INTRO == myContext.behaviorState)
    {
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        if(playArea.size.height > (newPosY + (0.5f * givenEnemy.renderer.size.height)))
        {
            // when ship is fully in view, go to cruising
            myContext.behaviorState = BEHAVIORSTATE_CRUISING;
            CGPoint newVel = [givenEnemy vel];
            newVel.y = CRUISING_VEL_Y;            // slowly move up while cruising
            givenEnemy.vel = newVel;
            
            myContext.initPos = CGPointMake(newPosX, newPosY);
            myContext.cruisingTimer = CRUISING_SECS;
        }
    }
    else if(BEHAVIORSTATE_CRUISING == myContext.behaviorState)
    {
        // NOTE: the ship transitions out of this state in the triggerEnemy function, not here;
        
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
    // do nothing
}

- (void) enemyBehavior:(Enemy *)givenEnemy receiveTrigger:(NSString *)label
{
    CargoShipBContext* myContext = [givenEnemy behaviorContext];
    
    // clear out cargo packs on ship
    for(Addon* cur in [myContext cargoAddons])
    {
        [cur kill];
        [givenEnemy.effectAddons removeObject:cur];
    }
    [myContext.cargoAddons removeAllObjects];
    
    // spawn cargo packs
    CGSize myRenderSize = [[givenEnemy renderer] size];
    CGPoint parentPos = [givenEnemy pos];
    CGAffineTransform t = CGAffineTransformMakeRotation([givenEnemy rotate]);
    float initSwingVelFactor = 0.5f;
    float initSwingVelFactorIncr = -1.0f;
    unsigned int num = [[myContext addonData] getNumForGroup:@"Cargos"];
    unsigned int index = 0;
    while(index < num)
    {
        CGPoint offset = [[myContext addonData] getOffsetAtIndex:index forGroup:@"Cargos"];
        CGPoint newPos = CGPointMake((offset.x * myRenderSize.width),
                                     (offset.y * myRenderSize.height));
        CGPoint newPosRotated = CGPointApplyAffineTransform(newPos, t);
        CGPoint addPos = CGPointMake(newPosRotated.x + parentPos.x,
                                     newPosRotated.y + parentPos.y);

        Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:@"CargoPack" atPos:addPos 
                                                                         isDynamics:YES 
                                                                groundedBucketIndex:0 
                                                                      layerDistance:100.0f];
        
        CargoPackContext* context = (CargoPackContext*) [newLoot lootContext];
        context.swingVel *= initSwingVelFactor;
        initSwingVelFactor += initSwingVelFactorIncr;
        if(-1.0f >= initSwingVelFactor)
        {
            initSwingVelFactorIncr *= -1.0f;
        }
        
        [newLoot spawn];
        [newLoot release];
        
        ++index;
    }

    // leave the game
    if(BEHAVIORSTATE_LEAVING != myContext.behaviorState)
    {
        givenEnemy.vel = CGPointMake(OUTWARD_VEL_X, OUTWARD_VEL_Y);
        myContext.behaviorState = BEHAVIORSTATE_LEAVING;
    }
}

#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    // do nothing
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
    return NO;
}

- (BOOL) isCollisionOnFor:(Enemy *)enemy
{
    return NO;
}

#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    CargoShipBContext* myContext = [givenEnemy behaviorContext];

    // clear all cargo addons again in case ship was not incapacitated
    [myContext.cargoAddons removeAllObjects];
    
    // unregister my trigger event
    [[GameManager getInstance] unRegisterTriggerEnemyForLabel:[myContext cargoReleaseTriggerName]];
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    CargoShipBContext* myContext = [givenEnemy behaviorContext];

    // clear all cargo addons
    [myContext.cargoAddons removeAllObjects];
    return YES;
}

#pragma mark - EnemyParentDelegate
- (void) removeFromParent:(Enemy*)parent enemy:(Enemy*)givenEnemy
{
    // do nothing; this ship does not have any child enemy
}

#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    CargoShipBContext* myContext = [givenEnemy behaviorContext];
    CGSize myRenderSize = [[givenEnemy renderer] size];
    
    // spawn wake effects addons
    {
        unsigned int num = [[myContext addonData] getNumForGroup:@"Wake"];
        
        NSArray* wakeNames = [NSArray arrayWithObjects:@"WakeSpeedo", @"WakeSpeedo2", @"WakeSpeedo3", nil];
        unsigned int nameIndex = 0;
        unsigned int index = 0;
        while(index < num)
        {
            // NOTE: this enemy lives in layer-space just like its parent
            // no need to rotate init pos here because addon inherits its parent's rotate
            CGPoint offset = [[myContext addonData] getOffsetAtIndex:index forGroup:@"Wake"];
            CGPoint newPos = CGPointMake((offset.x * myRenderSize.width),
                                         (offset.y * myRenderSize.height));
            
            NSString* wakeName = [wakeNames objectAtIndex:nameIndex];
            Addon* wakeAddon = [[[LevelManager getInstance] addonFactory] createAddonNamed:wakeName atPos:newPos];
            wakeAddon.renderBucket = [myContext dynamicsShadowsIndex];
            wakeAddon.ownsBucket = YES;
            [wakeAddon.anim playClipForward:YES];
            [givenEnemy.effectAddons addObject:wakeAddon];
            [wakeAddon release];
            ++index;
            ++nameIndex;
            if(nameIndex >= [wakeNames count])
            {
                nameIndex = 0;
            }
        }
    }
    
    // spawn cargopack addons
    {
        unsigned int num = [[myContext addonData] getNumForGroup:@"Cargos"];
        unsigned int index = 0;
        while(index < num)
        {
            // NOTE: this enemy lives in layer-space just like its parent
            // no need to rotate init pos here because addon inherits its parent's rotate
            CGPoint offset = [[myContext addonData] getOffsetAtIndex:index forGroup:@"Cargos"];
            CGPoint newPos = CGPointMake((offset.x * myRenderSize.width),
                                         (offset.y * myRenderSize.height));
            
            Addon* newAddon = [[[LevelManager getInstance] addonFactory] createAddonNamed:@"CargoPackAddon" atPos:newPos];
            newAddon.renderBucket = [myContext dynamicsAddonsIndex];
            newAddon.ownsBucket = YES;
            [newAddon.anim playClipRandomForward:YES];
            
            // add to Enemy as effectAddons for rendering
            [givenEnemy.effectAddons addObject:newAddon];
            
            // add to behaviorContext for releasing when triggered by game
            [myContext.cargoAddons addObject:newAddon];
            [newAddon release];
            ++index;
        }
    }
}


@end
