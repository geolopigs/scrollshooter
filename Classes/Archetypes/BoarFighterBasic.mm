//
//  BoarFighterBasic.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/14/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "BoarFighterBasic.h"
#import "LineSpawner.h"
#import "GameObjectSizes.h"
#import "Sprite.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "EnemySpawner.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "AnimLinearController.h"
#import "FiringPath.h"
#import "GameManager.h"
#import "Effect.h"
#import "EffectFactory.h"
#import "Loot.h"
#import "LootFactory.h"
#import "SoundManager.h"
#import "StatsManager.h"
#include "MathUtils.h"

enum BehaviorStates
{
    BEHAVIORSTATE_INTRO = 0,
    BEHAVIORSTATE_CRUISING,
    BEHAVIORSTATE_LAUNCHED,
    BEHAVIORSTATE_WAITINGTORETIRE,         // waiting for a short delay before retiring to leave its bullets around 
    
    BEHAVIORSTATE_NUM
};

static NSString* const ANIMNAME = @"BoarFighter";
static NSString* const TYPENAME = @"BoarFighterBasic";

static const float EXPLOSION_LOCAL_X = 0.0f;
static const float EXPLOSION_LOCAL_Y = -4.5f;

static const int INIT_HEALTH = 4;

@implementation BoarFighterBasicContext
@synthesize timeBetweenShots;
@synthesize shotSpeed;
@synthesize introDoneBotLeft;
@synthesize introDoneTopRight;
@synthesize colAreaBotLeft;
@synthesize colAreaTopRight;
@synthesize introVel;
@synthesize angularSpeed;
@synthesize launchDelay;
@synthesize launchSpeed;
@synthesize launchLeft;
@synthesize retireDelay;
@synthesize hasGroupBonus;

@synthesize timeTillFire;
@synthesize behaviorState;
@synthesize rot;
@synthesize launchTimer;
@synthesize timeTillRetire;
@synthesize collisionOn;

- (id) init
{
    self = [super init];
    if(self)
    {
        timeTillFire = 0.0f;
        rot = 0.0f;
        launchTimer = 1000.0f;  // some large number
        launchLeft = YES;
        hasGroupBonus = NO;
        collisionOn = YES;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}
@end

@implementation BoarFighterBasic
#pragma mark - EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    NSString* typeName = TYPENAME;
    NSString* animName = ANIMNAME;
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:typeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClip
    AnimClipData* clipData = [animData getClipForName:animName];
    AnimLinearController* newController = [[AnimLinearController alloc] initFromAnimClipData:clipData];
    givenEnemy.animController = newController;
    [newController release];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:typeName];
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

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(LineSpawnerContext*)spawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    givenEnemy.spawnedDelegate = self;  
    
    // create context
    BoarFighterBasicContext* newContext = [[BoarFighterBasicContext alloc] init];
    givenEnemy.behaviorContext = newContext;
    [newContext release];
    
    // init from spawnercontext
    NSDictionary* triggerContext = [spawnerContext spawnerTriggerContext];
    {
        BoarFighterBasicContext* myContext = [givenEnemy behaviorContext];
        myContext.introDoneBotLeft = spawnerContext.introDoneBotLeft;
        myContext.introDoneTopRight = spawnerContext.introDoneTopRight;
        myContext.timeBetweenShots = spawnerContext.timeBetweenShots;
        myContext.shotSpeed = spawnerContext.shotSpeed;
        myContext.angularSpeed = spawnerContext.angularSpeed;
        myContext.launchDelay = spawnerContext.launchDelay;
        myContext.launchSpeed = spawnerContext.launchSpeed;

        CGRect playArea = [[GameManager getInstance] getPlayArea];
        myContext.colAreaBotLeft = CGPointMake(playArea.origin.x,
                                               playArea.origin.y);
        myContext.colAreaTopRight = CGPointMake(playArea.size.width + myContext.colAreaBotLeft.x,
                                                playArea.size.height + myContext.colAreaBotLeft.y);
        myContext.collisionOn = NO;
        
        // alternate launch params every other spawn
        if(([spawnerContext spawnCounter]+1) % 2)
        {
            myContext.launchDelay += spawnerContext.launchSplit;
            if([spawnerContext angularSpeed] > 0.0f)
            {
                myContext.launchLeft = YES;
            }
            else
            {
                myContext.launchLeft = NO;
            }
        }
        else
        {
            myContext.launchDelay -= spawnerContext.launchSplit;            
            if([spawnerContext angularSpeed] > 0.0f)
            {
                myContext.launchLeft = NO;
            }
            else
            {
                myContext.launchLeft = YES;
            }
        }
        
        if(triggerContext)
        {
            NSNumber* introDirNumber = [triggerContext objectForKey:@"introDir"];
            NSNumber* introSpeedNumber = [triggerContext objectForKey:@"introSpeed"];
            if(introDirNumber && introSpeedNumber)
            {
                myContext.introVel = radiansToVector(CGPointMake(0.0f, -1.0f), 
                                                     [introDirNumber floatValue] * M_PI, [introSpeedNumber floatValue]);
            }
            else
            {
                myContext.introVel = spawnerContext.introVel;
            }

            NSNumber* retireDelay = [triggerContext objectForKey:@"retireDelay"];
            if(retireDelay)
            {
                myContext.retireDelay = [retireDelay floatValue];
            }
            else
            {
                myContext.retireDelay = 5.0f;
            }
            
            NSNumber* groupBonusBool = [triggerContext objectForKey:@"hasGroupBonus"];
            if(groupBonusBool)
            {
                myContext.hasGroupBonus = [groupBonusBool boolValue];
            }
        }
    }
}

#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    BoarFighterBasicContext* myContext = [givenEnemy behaviorContext];
    float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
    float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
    
    if(![myContext collisionOn])
    {
        CGPoint bl = [myContext colAreaBotLeft];
        CGPoint tr = [myContext colAreaTopRight];
        if((newPosX >= bl.x) && (newPosX <= tr.x) &&
           (newPosY >= bl.y) && (newPosY <= tr.y))
        {
            myContext.collisionOn = YES;
        }
    }
    
    if(BEHAVIORSTATE_INTRO == myContext.behaviorState)
    {
        CGPoint bl = myContext.introDoneBotLeft;
        CGPoint tr = myContext.introDoneTopRight;
        if((newPosX >= bl.x) && (newPosX <= tr.x) &&
           (newPosY >= bl.y) && (newPosY <= tr.y))
        {
            // when ship is fully in view, go to cruising
            myContext.behaviorState = BEHAVIORSTATE_CRUISING;
            
            // ok to fire
            givenEnemy.readyToFire = YES;
        }
    }
    else if(BEHAVIORSTATE_CRUISING == myContext.behaviorState)
    {
        myContext.timeTillFire -= elapsed;
        if(0.0f >= myContext.timeTillFire)
        {
            // shoot in the general direction of the player
            CGPoint playerPos = [[GameManager getInstance] getCamSpacePlayerPos];
            CGPoint myPos = [givenEnemy pos];
            CGPoint targetVec = CGPointMake(playerPos.x - myPos.x, playerPos.y - myPos.y);
            float randomOffset = (randomFrac() * M_PI_4) - (M_PI_4 * 0.5f);
            float targetRot = vectorToRadians(targetVec) - randomOffset;            
            CGPoint firingDir = CGPointMake(1.0f, 0.0f);
            CGAffineTransform t = CGAffineTransformMakeRotation(targetRot);
            CGPoint dir = CGPointApplyAffineTransform(firingDir, t);
            CGPoint vel = CGPointMake(dir.x * [myContext shotSpeed], dir.y * [myContext shotSpeed]);
            [givenEnemy fireFromPos:myPos withVel:vel];
            
            myContext.timeTillFire = myContext.timeBetweenShots;
        }
        
        // change heading by angularSpeed
        float newRot = myContext.rot + (elapsed * myContext.angularSpeed);
        CGAffineTransform rotTransform = CGAffineTransformMakeRotation(newRot);
        CGPoint newVel = CGPointApplyAffineTransform([myContext introVel], rotTransform);
        givenEnemy.vel = newVel;
        float downDir = M_PI_2 * 3.0f;
        float renderRot = vectorToRadians(newVel, downDir);            
        givenEnemy.rotate = renderRot;
        myContext.rot = newRot;
        
        // check for launch
        myContext.launchTimer -= elapsed;
        if(0.0f >= [myContext launchTimer])
        {
            myContext.behaviorState = BEHAVIORSTATE_LAUNCHED;
            myContext.timeTillFire = 0.0f;
            CGPoint newVel = givenEnemy.vel;
            newVel.x *= myContext.launchSpeed;
            newVel.y *= myContext.launchSpeed;
            givenEnemy.vel = newVel;
        }
    }
    else if(BEHAVIORSTATE_LAUNCHED == myContext.behaviorState)
    {
        // LAUNCHED
        myContext.timeTillFire -= elapsed;
        if(0.0f >= myContext.timeTillFire)
        {
            // shoot in the general direction of the player
            float shotSpeed = [myContext shotSpeed];
            CGPoint playerPos = [[GameManager getInstance] getCamSpacePlayerPos];
            CGPoint myPos = [givenEnemy pos];
            CGPoint targetVec = CGPointMake(playerPos.x - myPos.x, playerPos.y - myPos.y);
            float randomOffset = (randomFrac() * M_PI_4) - (M_PI_4 * 0.5f);
            float targetRot = vectorToRadians(targetVec) - randomOffset;            
            CGPoint firingDir = CGPointMake(1.0f, 0.0f);
            CGAffineTransform t = CGAffineTransformMakeRotation(targetRot);
            CGPoint dir = CGPointApplyAffineTransform(firingDir, t);
            CGPoint vel = CGPointMake(dir.x * shotSpeed, dir.y * shotSpeed);
            [givenEnemy fireFromPos:myPos withVel:vel];
            myContext.timeTillFire = myContext.timeBetweenShots;
        }    
        // change heading by angularSpeed
        float rotVel = fabs(myContext.angularSpeed);
        if(!myContext.launchLeft)
        {
            rotVel = -rotVel;
        }
        float newRot = myContext.rot + (elapsed * rotVel);
        CGPoint headingVel = [myContext introVel];
        headingVel.x *= myContext.launchSpeed;
        headingVel.y *= myContext.launchSpeed;
        CGAffineTransform rotTransform = CGAffineTransformMakeRotation(newRot);
        CGPoint newVel = CGPointApplyAffineTransform(headingVel, rotTransform);
        givenEnemy.vel = newVel;
        float downDir = M_PI_2 * 3.0f;
        float renderRot = vectorToRadians(newVel, downDir);            
        givenEnemy.rotate = renderRot;
        myContext.rot = newRot;
    }
    else if(BEHAVIORSTATE_WAITINGTORETIRE == myContext.behaviorState)
    {
        myContext.timeTillRetire -= elapsed;
        if(myContext.timeTillRetire <= 0.0f)
        {
            givenEnemy.willRetire = YES;        
        }
    }
    
    if((BEHAVIORSTATE_CRUISING == myContext.behaviorState) ||
       (BEHAVIORSTATE_LAUNCHED == myContext.behaviorState))
    {
        // self retire if way outside of playArea
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        float buffer = 0.1f;
        CGPoint retireBl = CGPointMake((-buffer * playArea.size.width) + playArea.origin.x,
                                       (-buffer * playArea.size.height) + playArea.origin.y);
        CGPoint retireTr = CGPointMake(((1.0f + buffer) * playArea.size.width) + playArea.origin.x,
                                       ((1.0f + buffer) * playArea.size.height) + playArea.origin.y);
        if((newPosX < retireBl.x) || (newPosX > retireTr.x) ||
           (newPosY < retireBl.y) || (newPosY > retireTr.y))
        {
            myContext.timeTillRetire = myContext.retireDelay;
            myContext.behaviorState = BEHAVIORSTATE_WAITINGTORETIRE;
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
    enemy.health--;
    [EffectFactory effectNamed:@"BulletHit" atPos:enemy.pos];
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
    BoarFighterBasicContext* myContext = [enemy behaviorContext];
    BOOL result = [myContext collisionOn];
    
    return result;
}


#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    // play sound
    [[SoundManager getInstance] playClip:@"BoarFighterExplosion"];
    
    // play down effects
    [EffectFactory effectNamed:@"BoarFighterDown" atPos:givenEnemy.pos];
    
    // show points gained
    if(showPoints)
    {
        [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                               atPos:[givenEnemy pos]]; 
        
        BoarFighterBasicContext* myContext = [givenEnemy behaviorContext];
        if([myContext hasGroupBonus])
        {
            EnemySpawner* mySpawner = [givenEnemy mySpawner];
            if(0 == [mySpawner incapsRemainingForWave:[givenEnemy waveIndex]])
            {
                // credit player with group bonus if player has killed all enemies by the same spawner
                [[StatsManager getInstance] creditBonusForGroupNamed:@"BoarFighterGroup"];
                
                [EffectFactory textEffectFor:@"BoarFighterGroup"
                                       atPos:[givenEnemy pos] 
                                     withVel:CGPointMake(0.0f, 7.0f) 
                                       scale:CGPointMake(0.3f, 0.3f)
                                    duration:1.5f 
                                   colorRed:1 green:1 blue:1 alpha:1];
                
                // also spawn pickups
                [[GameManager getInstance] dequeueAndSpawnPickupAtPos:[givenEnemy pos]];
            }
        }
    }
    
    // in Time-based mode, drop cargos for the last 3 in each wave
    unsigned int cargoDropWaveMax = 1;
    if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
    {
        cargoDropWaveMax = 3;
    }
    EnemySpawner* mySpawner = [givenEnemy mySpawner];
    if(cargoDropWaveMax > [mySpawner incapsRemainingForWave:[givenEnemy waveIndex]])
    {
        if([[GameManager getInstance] shouldReleasePickups])
        {   
            // drop loots
            // dequeue game manager pickup
            NSString* pickupType = [[GameManager getInstance] dequeueNextHealthPack];
            if(nil == pickupType)
            {
                pickupType = @"LootCash";
            }
            if(pickupType)
            {
                // drop cargo
                Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:pickupType atPos:[givenEnemy pos] 
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
#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    BoarFighterBasicContext* myContext = [givenEnemy behaviorContext];
    
    // setup my weapons
    myContext.timeTillFire = 0.0f;
    
    // setup entrance
    myContext.behaviorState = BEHAVIORSTATE_INTRO;
    myContext.launchTimer = myContext.launchDelay;
    givenEnemy.vel = myContext.introVel;
    
    // init my heading
    float downDir = M_PI_2 * 3.0f;
    float renderRot = vectorToRadians([myContext introVel], downDir);            
    givenEnemy.rotate = renderRot;
    myContext.rot = 0.0f;
    
    // fix anim at center
    [[givenEnemy animController] targetRangeMedian];
}



@end
