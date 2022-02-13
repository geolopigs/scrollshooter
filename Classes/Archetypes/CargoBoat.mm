//
//  CargoBoat.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "CargoBoat.h"
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
#import "TurretSpawner.h"
#import "BoarSolo.h"
#import "AddonData.h"
#import "TopCam.h"
#import "GameObjectSizes.h"
#include "MathUtils.h"

enum BehaviorStates
{
    BEHAVIORSTATE_ENTERING = 0,
    BEHAVIORSTATE_STOPPED,
    BEHAVIORSTATE_LEAVING,
    
    BEHAVIORSTATE_NUM
};

static const float INITSPEED = 20.0f;

static const float EXPLOSION_VEL_X = 0.0f;
static const float EXPLOSION_VEL_Y = -40.0f;

static const float STOP_AND_GO_RANGE = 0.5f;    // a fraction of the play-area width
static const float STOP_AND_GO_TIMEMAX = 6.0f;  // seconds
static const float STOP_AND_GO_TIMEMIN = 3.0f;

@implementation CargoBoatContext
@synthesize layerDistance;
@synthesize attachedEnemies;
@synthesize addonData;
@synthesize renderBucket;
@synthesize renderBucketAddons;
@synthesize renderBucketAddons2;
@synthesize stopAndGoPoint;
@synthesize stopAndGoTimer;
@synthesize behaviorState;
@synthesize leftEnd;
@synthesize rightEnd;
- (id) init
{
    self = [super init];
    if(self)
    {
        self.attachedEnemies = [NSMutableArray array];
        self.addonData = nil;
        stopAndGoPoint = 0.0f;
        stopAndGoTimer = 0.0f;
        behaviorState = BEHAVIORSTATE_ENTERING;
        leftEnd = 0.0f;
        rightEnd = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    self.addonData = nil;
    self.attachedEnemies = nil;
    [super dealloc];
}
@end

@interface CargoBoat (PrivateMethods)
- (void) initBehaviorPosVel:(Enemy*)givenEnemy;
- (void) initBehaviorContext:(Enemy*)givenEnemy;
@end

@implementation CargoBoat

#pragma mark - Private Methods
- (void) initBehaviorPosVel:(Enemy *)givenEnemy
{
    // init orientation and velocity
    float center = [[GameManager getInstance] getPlayArea].size.width * 0.5f;
    if(center >= givenEnemy.pos.x)
    {
        // if I am to the left of the screen, move right
        givenEnemy.rotate = M_PI_2 * 3.0f;
    }
    else
    {
        // otherwise, move left
        givenEnemy.rotate = M_PI_2;                
    }
    CGAffineTransform t = CGAffineTransformMakeRotation(givenEnemy.rotate);
    givenEnemy.vel = CGPointApplyAffineTransform(CGPointMake(0.0f, INITSPEED), t);
}

- (void) initBehaviorContext:(Enemy*)givenEnemy
{
    CargoBoatContext* myContext = [givenEnemy behaviorContext];
    // randomly pick a stop-n-go point
    CGRect playArea = [[GameManager getInstance] getPlayArea];
    float center = playArea.origin.x + (playArea.size.width * 0.5f);

    float stopRange = (randomFrac() - 0.5f) * STOP_AND_GO_RANGE * playArea.size.width;
    myContext.stopAndGoPoint = center + stopRange;
    
    // init begin and end point of rail;
    if(givenEnemy.pos.x < center)
    {
        // init is left of center
        myContext.leftEnd = givenEnemy.pos.x;
        myContext.rightEnd = (center - givenEnemy.pos.x) + center;
    }
    else
    {
        myContext.leftEnd = center - (givenEnemy.pos.x - center);
        myContext.rightEnd = givenEnemy.pos.x;
    }
}

#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:@"CargoBoat"];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClip
    AnimClipData* clipData = [animData getClipForName:@"CargoBoat"];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    givenEnemy.animClip = newClip;
    [newClip release];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    [self initBehaviorPosVel:givenEnemy];
        
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:@"CargoBoat"];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(TurretSpawnerContext*)spawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    givenEnemy.spawnedDelegate = self;
    
    // init its context given the spawner's context
    CargoBoatContext* newContext = [[CargoBoatContext alloc] init];
    newContext.layerDistance = [spawnerContext layerDistance];
    newContext.attachedEnemies = [NSMutableArray array];
    newContext.addonData = [[LevelManager getInstance] getAddonDataForName:@"CargoBoatBoar_addons"];
    newContext.renderBucket = [spawnerContext renderBucket];
    newContext.renderBucketAddons = [spawnerContext renderBucketAddons];
    newContext.renderBucketAddons2 = [spawnerContext renderBucketAddons];
    
    givenEnemy.behaviorContext = newContext;
    [self initBehaviorContext:givenEnemy];
    [newContext release];
}


#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    CargoBoatContext* myContext = [givenEnemy behaviorContext];
    if(BEHAVIORSTATE_ENTERING == [myContext behaviorState])
    {
        CGPoint newPos = CGPointMake(givenEnemy.pos.x + (givenEnemy.vel.x * elapsed),
                                     givenEnemy.pos.y + (givenEnemy.vel.y * elapsed));
        givenEnemy.pos = newPos;
        
        if(((givenEnemy.vel.x < 0.0f) && (newPos.x <= [myContext stopAndGoPoint])) ||
           ((givenEnemy.vel.x > 0.0f) && (newPos.x > [myContext stopAndGoPoint])))
        {
            // stop and go
            myContext.behaviorState = BEHAVIORSTATE_STOPPED;
            myContext.stopAndGoTimer = STOP_AND_GO_TIMEMIN + (randomFrac() * STOP_AND_GO_TIMEMAX);
        }
    }
    else if(BEHAVIORSTATE_STOPPED == [myContext behaviorState])
    {
        myContext.stopAndGoTimer -= elapsed;
        if(0.0f >= myContext.stopAndGoTimer)
        {
            myContext.behaviorState = BEHAVIORSTATE_LEAVING;
        }
    }
    else    // BEHAVIORSTATE_LEAVING
    {
        CGPoint newPos = CGPointMake(givenEnemy.pos.x + (givenEnemy.vel.x * elapsed),
                                     givenEnemy.pos.y + (givenEnemy.vel.y * elapsed));
        
        // if boat has moved past end points, turn it around
        if((newPos.x < myContext.leftEnd) || (newPos.x > myContext.rightEnd))
        {
            CGPoint newVel = CGPointMake(-givenEnemy.vel.x, givenEnemy.vel.y);
            givenEnemy.vel = newVel;
            givenEnemy.rotate += M_PI;
            if((2.0f * M_PI) <= givenEnemy.rotate)
            {
                givenEnemy.rotate = givenEnemy.rotate - (2.0f * M_PI);
            }
            myContext.behaviorState = BEHAVIORSTATE_ENTERING;
        }
        givenEnemy.pos = newPos;        
    }
}

- (NSString*) getEnemyTypeName
{
    return @"CargoBoat";
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    CargoBoatContext* myContext = [givenEnemy behaviorContext];
    for(Enemy* cur in [myContext attachedEnemies])
    {
        [cur killAllBullets];
    }
}


#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    // do nothing; CargoBoat is not collideable
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
    // as far as collision toggle is concerned, this enemy is ON even though it is not collidable
    // it's children relies on it this toggle to determine whether they should turn on/off their collision
    // SO, this NEEDS to return ON;
    return YES;
}


#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    if(![givenEnemy incapacitated])
    {
        CargoBoatContext* myContext = [givenEnemy behaviorContext];
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
    // kill all attached enemies
    CargoBoatContext* myContext = [givenEnemy behaviorContext];
    for(Enemy* cur in [myContext attachedEnemies])
    {
        cur.parentDelegate = nil;
        [cur incapAndKillWithPoints:showPoints];
    }
    [myContext.attachedEnemies removeAllObjects];
    myContext.attachedEnemies = nil;
    
    // returns true for enemy to be killed immediately
    return YES;
}

#pragma mark - EnemyParentDelegate
- (void) removeFromParent:(Enemy*)parent enemy:(Enemy*)givenEnemy
{
    CargoBoatContext* myContext = [parent behaviorContext];
    [myContext.attachedEnemies removeObject:givenEnemy];
}

#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    CargoBoatContext* myContext = [givenEnemy behaviorContext];
    unsigned int num = [[myContext addonData] getNumForGroup:@"GunSet1"];
    CGSize myRenderSize = [[givenEnemy renderer] size];
    unsigned int index = 0;
    while(index < num)
    {
        // NOTE: this enemy lives in layer-space just like its parent
        // no need to rotate init pos here because addon inherits its parent's rotate
        CGPoint offset = [[myContext addonData] getOffsetAtIndex:index forGroup:@"GunSet1"];
        CGPoint newPos = CGPointMake((offset.x * myRenderSize.width),
                                     (offset.y * myRenderSize.height));
 
        Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"BoarSoloGun" AtPos:newPos];        
        newEnemy.isGrounded = YES;
        newEnemy.renderBucketIndex = myContext.renderBucketAddons;
        
        // attach myself as parent
        newEnemy.parentEnemy = givenEnemy;
        newEnemy.parentDelegate = self;
        
        // use BoarSoloGunGround
        float dice = randomFrac();
        if(dice <= 0.5f)
        {
            [BoarSolo enemy:newEnemy replaceAnimWithType:BOARSOLO_ANIMTYPE_GROUND];
        }
        else
        {
            [BoarSolo enemy:newEnemy replaceAnimWithType:BOARSOLO_ANIMTYPE_GUN];            
        }
        // init its context given the spawner's context
        BoarSoloContext* newContext = [[BoarSoloContext alloc] init];
        newContext.timeTillFire = 1.0f;
        newContext.layerDistance = [myContext layerDistance];
        newEnemy.behaviorContext = newContext;
        [newContext release];
        
        // setup gun addon
        [BoarSolo enemy:newEnemy createGunAddonInBucket:[myContext renderBucketAddons2]];

        // add it to spawnedEnemies
        [myContext.attachedEnemies addObject:newEnemy];
        [newEnemy spawn];
        [newEnemy release];

        ++index;
    }
}

@end
