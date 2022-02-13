//
//  HoverFighter.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "HoverFighter.h"
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
#import "SineWeaver.h"
#import "TopCam.h"
#import "RenderBucketsManager.h"
#import "AchievementsManager.h"
#include "MathUtils.h"

enum BehaviorStates
{
    BEHAVIORSTATE_INTRO = 0,
    BEHAVIORSTATE_TAKINGOFF,
    BEHAVIORSTATE_ROLLINGINTRO,
    BEHAVIORSTATE_SUBINTRO,     // intro state when spawned on an enemy (like a Boss SubSpawner)
    BEHAVIORSTATE_CRUISING,
    BEHAVIORSTATE_LEAVING,
    BEHAVIORSTATE_RETIRING,
    
    BEHAVIORSTATE_NUM
};

static NSString* const ANIMNAME = @"BoarBuzz";
static NSString* const TYPENAME = @"HoverFighter";
static const NSString* ANIMKEY_IDLE = @"idle";
static const NSString* ANIMKEY_CRUISING = @"cr";

static const float EXPLOSION_LOCAL_X = 0.0f;
static const float EXPLOSION_LOCAL_Y = -4.5f;

@implementation HoverFighterContext
@synthesize introVel;
@synthesize introDoneBotLeft;
@synthesize introDoneTopRight;
@synthesize introDelay;
@synthesize numShotsPerRound;
@synthesize shotDelay;
@synthesize shotSpeed;
@synthesize roundDelay;
@synthesize hoverInterval;
@synthesize hoverDelay;
@synthesize hoverDelayStep;
@synthesize angularSpeed;
@synthesize exitVel;
@synthesize targetAngle;
@synthesize weaverX;
@synthesize weaverY;
@synthesize initHealth;
@synthesize timeout; 
@synthesize groundedBucket;
@synthesize dynamicsBucket;
@synthesize layerDistance;
@synthesize groundedPos;

@synthesize introTimer;
@synthesize timeTillFire;
@synthesize behaviorState;
@synthesize rotateParamTarget;
@synthesize rotateParam;
@synthesize rotateSpeed;
@synthesize shotCount;
@synthesize roundTimer;
@synthesize hoverTimer;
@synthesize nextHoverParam;
@synthesize cruisingTimer;
- (id) init
{
    self = [super init];
    if(self)
    {
        // default configs
        introDelay = 3.0f;
        numShotsPerRound = 4;
        shotSpeed = 40.0f;
        angularSpeed = 0.25f * M_PI;
        hoverInterval = M_PI_2;
        hoverDelay = 0.0f;
        hoverDelayStep = 0.5f;
        roundDelay = 0.0f;
        exitVel = CGPointMake(0.0f, -100.0f);
        targetAngle = 0.0f;
        self.weaverX = nil;
        self.weaverY = nil;
        initHealth = 50;
        timeout = 30.0f;
        layerDistance = 100.0f;
        _flags = 0;
        
        // init runtime
        timeTillFire = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    self.weaverX = nil;
    self.weaverY = nil;
    [super dealloc];
}

- (void) setupRotationParamsForSrc:(float)srcAngle target:(float)tgtAngle
{
    rotateParam = 0.0f;
    float diffPositive = 0.0f;
    float diffNegative = 0.0f;
    if(srcAngle < tgtAngle)
    {
        diffPositive = tgtAngle - srcAngle;
        diffNegative = (2.0f * M_PI) - tgtAngle + srcAngle;
    }
    else
    {
        diffPositive = (2.0f * M_PI) - srcAngle + tgtAngle;
        diffNegative = srcAngle - tgtAngle;
    }
    
    if(diffPositive < diffNegative)
    {
        // rotate in the positive direction
        rotateSpeed = angularSpeed;
        rotateParamTarget = diffPositive / angularSpeed;
    }
    else
    {
        // rotate in the negative direction
        rotateSpeed = -angularSpeed;
        rotateParamTarget = diffNegative / angularSpeed;
    }
}


- (void) setupFromTriggerContext:(NSDictionary*)triggerContext
{
    if(triggerContext)
    {
        introDelay = [[triggerContext objectForKey:@"introDelay"] floatValue];
        numShotsPerRound = [[triggerContext objectForKey:@"shotsPerRound"] unsignedIntValue];
        shotDelay = [[triggerContext objectForKey:@"shotDelay"] floatValue];
        shotSpeed = [[triggerContext objectForKey:@"shotSpeed"] floatValue];
        roundDelay = [[triggerContext objectForKey:@"roundDelay"] floatValue] * M_PI;
        angularSpeed = [[triggerContext objectForKey:@"angularSpeed"] floatValue] * M_PI;
        float exitDir = [[triggerContext objectForKey:@"exitDir"] floatValue] * M_PI;
        float exitSpeed = [[triggerContext objectForKey:@"exitSpeed"] floatValue];
        exitVel = radiansToVector(CGPointMake(0.0f, -1.0f), exitDir, exitSpeed);
        
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
        initHealth = [[triggerContext objectForKey:@"initHealth"] intValue];
        hoverInterval = [[triggerContext objectForKey:@"hoverInterval"] floatValue] * M_PI;
        hoverDelay = [[triggerContext objectForKey:@"hoverDelay"] floatValue];
        hoverDelayStep = [[triggerContext objectForKey:@"hoverDelayStep"] floatValue];
        timeout = [[triggerContext objectForKey:@"timeout"] floatValue];
        
        NSNumber* introSpeed = [triggerContext objectForKey:@"introSpeed"];
        NSNumber* introDir = [triggerContext objectForKey:@"introDir"];
        if(introSpeed && introDir)
        {
            introVel = radiansToVector(CGPointMake(0.0f, -1.0f), M_PI * [introDir floatValue], [introSpeed floatValue]);
        }

        NSNumber* doneX = [triggerContext objectForKey:@"introDoneX"];
        NSNumber* doneY = [triggerContext objectForKey:@"introDoneY"];
        NSNumber* doneW = [triggerContext objectForKey:@"introDoneW"];
        NSNumber* doneH = [triggerContext objectForKey:@"introDoneH"];
        if(doneX && doneY && doneW && doneH)
        {
            CGRect playArea = [[GameManager getInstance] getPlayArea];
            introDoneBotLeft = CGPointMake(([doneX floatValue] * playArea.size.width) + playArea.origin.x,
                                           ([doneY floatValue] * playArea.size.height) + playArea.origin.y);
            introDoneTopRight = CGPointMake(([doneW floatValue] * playArea.size.width) + introDoneBotLeft.x,
                                            ([doneH floatValue] * playArea.size.height) + introDoneBotLeft.y);
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

@implementation HoverFighter
#pragma mark - EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    NSString* typeName = TYPENAME;
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:typeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init animClips
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    AnimClipData* clipData = [animData getClipForName:@"BoarBuzzIdle"];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_IDLE];
    [newClip release];

    clipData = [animData getClipForName:@"BoarBuzz"];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_CRUISING];
    [newClip release];

    // init animclip to idle
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];
    
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
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(NSObject<EnemySpawnerContextDelegate>*)givenSpawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    givenEnemy.spawnedDelegate = self;  
    
    // create context
    HoverFighterContext* newContext = [[HoverFighterContext alloc] init]; 
    if(givenSpawnerContext)
    {
        NSDictionary* triggerContext = [givenSpawnerContext spawnerTriggerContext];
        [newContext setupFromTriggerContext:triggerContext];

        // init velocity
        givenEnemy.vel = [newContext introVel];
    
        if([givenSpawnerContext isMemberOfClass:[DynamicsSpawnerContext class]])
        {
            // enemy starts off on the ground
            DynamicsSpawnerContext* spawnerContext = (DynamicsSpawnerContext*)givenSpawnerContext;
            newContext.groundedBucket = [spawnerContext groundedBucket];
            newContext.dynamicsBucket = [spawnerContext dynamicsBucketIndex];
            newContext.layerDistance = [spawnerContext layerDistance];
            newContext.groundedPos = [[[spawnerContext spawnPositions] objectAtIndex:[spawnerContext spawnedCount]] CGPointValue];
            newContext.behaviorState = BEHAVIORSTATE_INTRO;
        } 
        else
        {
            // enemy starts off outside of the screen and flies in
            newContext.groundedBucket = 0;  // not used;
            newContext.layerDistance = 100.0f;  // not used;
            newContext.groundedPos = CGPointMake(0.0f, 0.0f);   // not used;
            newContext.dynamicsBucket = [[RenderBucketsManager getInstance] getIndexFromName:@"GrDynamics"];
            newContext.behaviorState = BEHAVIORSTATE_ROLLINGINTRO;
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_CRUISING];
        }
    }
    else
    {
        // spawned by a SubSpawner
        newContext.behaviorState = BEHAVIORSTATE_SUBINTRO;
        newContext.dynamicsBucket = [[RenderBucketsManager getInstance] getIndexFromName:@"Dynamics"];
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];
    }
    
    givenEnemy.behaviorContext = newContext;
    [newContext release];
}

#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    HoverFighterContext* myContext = [givenEnemy behaviorContext];
    float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
    float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
    
    if(BEHAVIORSTATE_INTRO == myContext.behaviorState)
    {
        myContext.introTimer -= elapsed;
        if([myContext introTimer] <= 0.0f)
        {
            myContext.behaviorState = BEHAVIORSTATE_TAKINGOFF;
            
            // take off
            givenEnemy.isGrounded = NO;
            givenEnemy.renderBucketIndex = [myContext dynamicsBucket];
            TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
            CGPoint dynPos = [gameCam camPointFromWorldPoint:[givenEnemy pos] atDistance:[myContext layerDistance]];
            newPosX = dynPos.x;
            newPosY = dynPos.y;
            
            [myContext setupRotationParamsForSrc:givenEnemy.rotate target:[myContext targetAngle]];
            myContext.nextHoverParam = [myContext hoverInterval];
            
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_CRUISING];
            [givenEnemy.curAnimClip playClipForward:YES];
        }
    }
    else if(BEHAVIORSTATE_SUBINTRO == [myContext behaviorState])
    {
        myContext.introTimer -= elapsed;
        if([myContext introTimer] <= 0.0f)
        {
            myContext.behaviorState = BEHAVIORSTATE_TAKINGOFF;
            
            // take off by decoupling from the parent
            CGPoint dynPos = [Enemy derivePosFromParentForEnemy:givenEnemy];
            newPosX = dynPos.x;
            newPosY = dynPos.y;
            givenEnemy.parentEnemy = nil;
            givenEnemy.renderBucketIndex = [myContext dynamicsBucket];
            
            [myContext setupRotationParamsForSrc:givenEnemy.rotate target:[myContext targetAngle]];
            myContext.nextHoverParam = [myContext hoverInterval];
            
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_CRUISING];
            [givenEnemy.curAnimClip playClipForward:YES];            
        }
    }
    else if(BEHAVIORSTATE_TAKINGOFF == [myContext behaviorState])
    {
        myContext.rotateParam = myContext.rotateParam + elapsed;
        
        // update rotation
        float newRotate = givenEnemy.rotate + (elapsed * myContext.rotateSpeed);
        if(0.0f > newRotate)
        {
            // normalize it to 0 to 2pi
            newRotate = (2.0f * M_PI) + newRotate;
        }
        givenEnemy.rotate = newRotate;
        
        if(myContext.rotateParamTarget <= myContext.rotateParam)
        {
            myContext.behaviorState = BEHAVIORSTATE_CRUISING;
            myContext.timeTillFire = 0.0f;
            myContext.shotCount = 0;
            myContext.cruisingTimer = [myContext timeout];
            
            [myContext.weaverX resetRandomWithBase:newPosX];
            [myContext.weaverY resetRandomWithBase:newPosY];

            // ok to fire
            givenEnemy.readyToFire = YES;
        }
    }
    else if(BEHAVIORSTATE_ROLLINGINTRO == myContext.behaviorState)
    {
        CGPoint bl = myContext.introDoneBotLeft;
        CGPoint tr = myContext.introDoneTopRight;
        if((newPosX >= bl.x) && (newPosX <= tr.x) &&
           (newPosY >= bl.y) && (newPosY <= tr.y))
        {
            myContext.behaviorState = BEHAVIORSTATE_CRUISING;
            myContext.timeTillFire = 0.0f;
            myContext.shotCount = 0;
            myContext.cruisingTimer = [myContext timeout];
            
            [myContext.weaverX resetRandomWithBase:newPosX];
            [myContext.weaverY resetRandomWithBase:newPosY];
            
            // ok to fire
            givenEnemy.readyToFire = YES;
            CGPoint newVel = [givenEnemy vel];
            newVel.y = 0.0f;
            givenEnemy.vel = newVel;
        }
    }
    else if(BEHAVIORSTATE_CRUISING == myContext.behaviorState)
    {
        // process firing
        myContext.timeTillFire -= elapsed;
        if(0.0f >= myContext.timeTillFire)
        {
            CGPoint shotVel = radiansToVector(CGPointMake(0.0f, -1.0f), [givenEnemy rotate], [myContext shotSpeed]);
            CGPoint myPos = [givenEnemy pos];
            [givenEnemy fireFromPos:myPos withVel:shotVel];
            myContext.timeTillFire = myContext.shotDelay;
            myContext.shotCount++;
            if([myContext shotCount] >= [myContext numShotsPerRound])
            {
                myContext.timeTillFire = myContext.roundDelay;
                myContext.shotCount = 0;
            }
        }
        
        // process hovering
        if([myContext shotCount])
        {
            // if firing, move slower
            NSTimeInterval scaledElapsed = elapsed * [myContext hoverDelayStep];
            myContext.weaverX.base += (scaledElapsed * givenEnemy.vel.x);
            myContext.weaverY.base += (scaledElapsed * givenEnemy.vel.y);
            newPosX = [myContext.weaverX update:scaledElapsed];
            newPosY = [myContext.weaverY update:scaledElapsed];
        }
        else
        {
            myContext.weaverX.base += (elapsed * givenEnemy.vel.x);
            myContext.weaverY.base += (elapsed * givenEnemy.vel.y);
            newPosX = [myContext.weaverX update:elapsed];
            newPosY = [myContext.weaverY update:elapsed];
        }
        /*
        myContext.hoverTimer -= elapsed;
        if([myContext hoverTimer] <= 0.0f)
        {
            myContext.hoverTimer = 0.0f;
            if([[myContext weaverX] willCrossThreshold:[myContext nextHoverParam] afterElapsed:elapsed])
            {
                // normalize before incrementing to the next-param so that we have one that
                // is slightly above 2PI
                myContext.nextHoverParam = normalizeAngle(myContext.nextHoverParam);
                myContext.nextHoverParam += [myContext hoverInterval];
                myContext.hoverTimer = [myContext hoverDelay];
            }
            myContext.weaverX.base += (elapsed * givenEnemy.vel.x);
            myContext.weaverY.base += (elapsed * givenEnemy.vel.y);
            newPosX = [myContext.weaverX update:elapsed];
            newPosY = [myContext.weaverY update:elapsed];
        }
        else
        {
            // slow section
            NSTimeInterval scaledElapsed = elapsed * [myContext hoverDelayStep];
            myContext.weaverX.base += (scaledElapsed * givenEnemy.vel.x);
            myContext.weaverY.base += (elapsed * givenEnemy.vel.y);
            newPosX = [myContext.weaverX update:scaledElapsed];
            newPosY = [myContext.weaverY update:elapsed];
        }
         */

        myContext.cruisingTimer -= elapsed;
        if([myContext cruisingTimer] <= 0.0f)
        {
            myContext.behaviorState = BEHAVIORSTATE_LEAVING;
            givenEnemy.vel = myContext.exitVel;
        }
    }
    else if(BEHAVIORSTATE_LEAVING == myContext.behaviorState)
    {
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        float buffer = 0.2f;
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
    BOOL result = YES;
    
    HoverFighterContext* myContext = [enemy behaviorContext];
    if([myContext behaviorState] == BEHAVIORSTATE_INTRO)
    {
        // collision OFF if still intro
        result = NO;
    }
    
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
    [EffectFactory effectNamed:@"Explosion" atPos:CGPointMake(givenEnemy.pos.x + EXPLOSION_LOCAL_X, givenEnemy.pos.y + EXPLOSION_LOCAL_Y)];
    
    // show points gained
    if(showPoints)
    {
        [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                               atPos:[givenEnemy pos]]; 
    }
    
    // also spawn pickups
    [[GameManager getInstance] dequeueAndSpawnPickupAtPos:[givenEnemy pos]];
    
    // achievements
    [[AchievementsManager getInstance] hoverKilled];
    
    // returns true for enemy to be killed immediately
    return YES;
}
#pragma mark - EnemySpawnedDelegate
- (void) preSpawn:(Enemy *)givenEnemy
{
    HoverFighterContext* myContext = [givenEnemy behaviorContext];
    
    // setup my weapons
    myContext.timeTillFire = 0.0f;
    
    // setup entrance
    givenEnemy.health = myContext.initHealth;
    myContext.introTimer = [myContext introDelay];
    
    // grounded at first
    if([myContext behaviorState] == BEHAVIORSTATE_INTRO)
    {
        givenEnemy.isGrounded = YES;
        givenEnemy.renderBucketIndex = [myContext groundedBucket];
        givenEnemy.pos = [myContext groundedPos];
    
        // init my heading
        float initDir = (randomFrac() * M_PI_2) + M_PI_4;
        givenEnemy.rotate = initDir;    
    }
    else if([myContext behaviorState] == BEHAVIORSTATE_SUBINTRO)
    {
        // init my heading
        float initDir = (randomFrac() * M_PI_2) + M_PI_4;
        givenEnemy.rotate = initDir;            
        [givenEnemy.curAnimClip playClipForward:YES];
    }
    else
    {
        [givenEnemy.curAnimClip playClipForward:YES];
    }
}



@end
