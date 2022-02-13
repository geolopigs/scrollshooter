//
//  BoarSolo.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "BoarSolo.h"
#import "Sprite.h"
#import "Enemy.h"
#import "AnimClipData.h"
#import "AnimClip.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "EffectFactory.h"
#import "Effect.h"
#import "FiringPath.h"
#import "LevelManager.h"
#import "SoundManager.h"
#import "Level.h"
#import "TopCam.h"
#import "TurretSpawner.h"
#import "GameManager.h"
#import "Loot.h"
#import "LootCash.h"
#import "LootFactory.h"
#import "AddonFactory.h"
#import "Addon.h"
#import "BossWeapon.h"
#import "GameObjectSizes.h"
#import "EffectFactory.h"
#import "AchievementsManager.h"
#include "MathUtils.h"

NSString* const BOARSOLO_IDLENAME_GUN = @"BoarSoloIdle";
NSString* const BOARSOLO_IDLENAME_GROUND = @"BoarSoloGroundIdle";
NSString* const BOARSOLO_IDLENAME_HELMET = @"BoarSoloPilotIdle";
NSString* const BOARSOLO_IDLENAME_HELMET2 = @"BoarSoloNavyIdle";
NSString* const BOARSOLO_FIRENAME_GUN = @"BoarSoloFire";
NSString* const BOARSOLO_FIRENAME_GROUND = @"BoarSoloGroundFire";
NSString* const BOARSOLO_FIRENAME_HELMET = @"BoarSoloPilotFire";
NSString* const BOARSOLO_FIRENAME_HELMET2 = @"BoarSoloNavyFire";

static const float SHOT_OFFSETY = 9.0f;
static const float HITEFFECT_X = 0.0f;
static const float HITEFFECT_Y = -0.5f;

static const float HOVERVEL_X = -1.0f;
static const float EXITVEL_X = 40.0f;
static const float EXITVEL_Y = -40.0f;
static const float HOVERING_POS = 120.0f;
static const float HOVERING_DURATION = 10.0f;
static const float FIREANIM_DELAY = 0.3f;

static const unsigned int NUM_HITS_PER_RESPONSE = 1;    // number of hits this guy takes before reacting with an anim

static const float LOOTVEL_X = 0.0f;
static const float LOOTVEL_Y = -2.0f;

static const NSString* ANIMKEY_IDLE = @"idle";
static const NSString* ANIMKEY_FIRE = @"fire";

@implementation BoarSoloContext
@synthesize idleDelay;
@synthesize shotDelay;
@synthesize shotSpeed;
@synthesize shotsPerRound;
@synthesize initHealth;
@synthesize angularSpeed;
@synthesize hidden;

@synthesize idleTimer;
@synthesize timeTillFire;
@synthesize hitCounts;
@synthesize layerDistance;
@synthesize rotateParamTarget;
@synthesize rotateParam;
@synthesize rotateSpeed;
@synthesize behaviorState;
@synthesize hasCargo;
@synthesize bossWeapon;
@synthesize shotCount;
@synthesize gunAddon = _gunAddon;;
- (id) init
{
    self = [super init];
    if(self)
    {
        idleDelay = 1.0f;
        shotDelay = 0.5f;
        shotSpeed = 50.0f;
        shotsPerRound = 1;
        initHealth = 5;
        angularSpeed = M_PI * 0.3f;
        hidden = NO;
        _flags = 0;
        
        hitCounts = 0;
        rotateParamTarget = 0.0f;
        rotateParam = 0.0f;
        rotateSpeed = 0.0f;
        behaviorState = BOARSOLO_BEHAVIORSTATE_INIT;
        idleTimer = 0.0f;
        timeTillFire = 0.0f;
        hasCargo = YES;
        self.bossWeapon = nil;
        shotCount = 0;
        self.gunAddon = nil;
    }
    return self;
}

- (void) dealloc
{
    self.gunAddon = nil;
    self.bossWeapon = nil;
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

- (void) setupFromTriggerContext:(NSDictionary *)triggerContext
{
    if(triggerContext)
    {
        NSNumber* idleDelayNum = [triggerContext objectForKey:@"idleDelay"];
        if(idleDelayNum)
        {
            self.idleDelay = [idleDelayNum floatValue];
            self.shotDelay = [[triggerContext objectForKey:@"shotDelay"] floatValue];
            self.shotSpeed = [[triggerContext objectForKey:@"shotSpeed"] floatValue];
            self.shotsPerRound = [[triggerContext objectForKey:@"shotsPerRound"] unsignedIntValue];
            self.angularSpeed = [[triggerContext objectForKey:@"angularSpeed"] floatValue] * M_PI;
        }
        NSDictionary* bossWeaponConfig = [triggerContext objectForKey:@"bossWeapon"];
        if(bossWeaponConfig)
        {
            BossWeapon* newWeapon = [[BossWeapon alloc] initFromConfig:bossWeaponConfig];
            self.bossWeapon = newWeapon;
            [newWeapon release];
        }
        NSNumber* healthConfig = [triggerContext objectForKey:@"health"];
        if(healthConfig)
        {
            self.initHealth = [healthConfig intValue];
        }
        
        NSNumber* isHiddenNumber = [triggerContext objectForKey:@"hidden"];
        if(isHiddenNumber)
        {
            self.hidden = [isHiddenNumber boolValue];
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

@interface BoarSolo (PrivateMethods)
- (CGPoint) derivePosFromParentForEnemy:(Enemy*)givenEnemy;
+ (void) enemy:(Enemy*)givenEnemy replaceAnimClipsIdle:(NSString*)idleClipName fire:(NSString*)fireClipName;
@end

@implementation BoarSolo
+ (unsigned int) animTypeFromName:(NSString *)name
{
    unsigned int result = BOARSOLO_ANIMTYPE_GUN;
    if(name)
    {
        if([name isEqualToString:@"Ground"])
        {
            result = BOARSOLO_ANIMTYPE_GROUND;
        }
        else if([name isEqualToString:@"Helmet"])
        {
            result = BOARSOLO_ANIMTYPE_HELMET;
        }
        else if([name isEqualToString:@"Helmet2"])
        {
            result = BOARSOLO_ANIMTYPE_HELMET2;
        }
    }
    return result;
}

+ (void) enemy:(Enemy*)givenEnemy replaceAnimClipsIdle:(NSString*)idleClipName fire:(NSString*)fireClipName
{
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    AnimClipData* clipData = [animData getClipForName:idleClipName];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_IDLE];
    [newClip release];
    
    clipData = [animData getClipForName:fireClipName];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_FIRE];
    [newClip release];
    
    // init animclip to the new idle
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];  
}

+ (void) enemy:(Enemy*)givenEnemy replaceAnimWithType:(unsigned int)newAnimType
{
    if(BOARSOLO_ANIMTYPE_GROUND == newAnimType)
    {
        [BoarSolo enemy:givenEnemy replaceAnimClipsIdle:BOARSOLO_IDLENAME_GROUND fire:BOARSOLO_FIRENAME_GROUND];
    }
    else if(BOARSOLO_ANIMTYPE_HELMET == newAnimType)
    {
        [BoarSolo enemy:givenEnemy replaceAnimClipsIdle:BOARSOLO_IDLENAME_HELMET fire:BOARSOLO_FIRENAME_HELMET];
    }
    else if(BOARSOLO_ANIMTYPE_HELMET2 == newAnimType)
    {
        [BoarSolo enemy:givenEnemy replaceAnimClipsIdle:BOARSOLO_IDLENAME_HELMET2 fire:BOARSOLO_FIRENAME_HELMET2];
    }
    else
    {
        // default
        [BoarSolo enemy:givenEnemy replaceAnimClipsIdle:BOARSOLO_IDLENAME_GUN fire:BOARSOLO_FIRENAME_GUN];
    }
}

+ (void) enemy:(Enemy*)givenEnemy createGunAddonInBucket:(unsigned int)bucketIndex
{
    BoarSoloContext* myContext = [givenEnemy behaviorContext];
    
    // must create behaviorContext before calling this
    assert(myContext);
    Addon* gun = [[[LevelManager getInstance] addonFactory] createAddonNamed:@"SoloGun" atPos:CGPointMake(0.0f, 0.0f)];
    myContext.gunAddon = gun;
    [givenEnemy.effectAddons addObject:gun];
    gun.renderBucket = bucketIndex;
    gun.ownsBucket = YES;
    [gun release];  
}

#pragma mark - Private Methods
- (CGPoint) derivePosFromParentForEnemy:(Enemy*)givenEnemy
{
    CGPoint myPos = [givenEnemy pos];
    if([givenEnemy parentEnemy])
    {
        Enemy* parentEnemy = [givenEnemy parentEnemy];
        CGPoint parentPos = [parentEnemy pos];
        CGAffineTransform t = CGAffineTransformMakeRotation([parentEnemy rotate]);
        CGPoint offset = CGPointApplyAffineTransform(myPos, t);
        
        myPos.x = offset.x + parentPos.x;
        myPos.y = offset.y + parentPos.y;
    }
    return myPos;
}

- (CGPoint) deriveCamPosFromParentForEnemy:(Enemy*)givenEnemy
{
    TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
    CGPoint myWorldPos = [self derivePosFromParentForEnemy:givenEnemy];
    CGPoint myPos = [gameCam camPointFromWorldPoint:myWorldPos atDistance:[[givenEnemy behaviorContext] layerDistance]];
    return myPos;
}

#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:@"BoarSolo"];
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:@"BoarSolo"];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize colSize:colSize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init the anim registry
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    AnimClipData* clipData = [animData getClipForName:@"BoarSoloIdle"];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_IDLE];
    [newClip release];

    clipData = [animData getClipForName:@"BoarSoloFire"];
    newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_FIRE];
    [newClip release];
    
    // init animclip to idle
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    givenEnemy.collisionAABBDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // game status
    givenEnemy.health = 5;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}


- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(TurretSpawnerContext*)spawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];
    
    // init its context given the spawner's context
    BoarSoloContext* newContext = [[BoarSoloContext alloc] init];
    newContext.idleTimer = 1.0f;
    newContext.timeTillFire = 0.0f;
    newContext.layerDistance = 100.0f;
    givenEnemy.behaviorContext = newContext;

    // for TurretSpawner BoarSolos, the default alternate is Ground unless one is specified
    unsigned int animType = BOARSOLO_ANIMTYPE_GROUND;

    if(spawnerContext)
    {
        newContext.layerDistance = [spawnerContext layerDistance];
        NSDictionary* triggerContext = [spawnerContext spawnerTriggerContext];
        if(triggerContext)
        {
            [newContext setupFromTriggerContext:triggerContext];
            givenEnemy.health = [newContext initHealth];
            
            NSString* animTypeString = [triggerContext objectForKey:@"animType"];
            if(animTypeString)
            {
                animType = [BoarSolo animTypeFromName:animTypeString];
            }        
        }
        
        // setup gun as addon
        [BoarSolo enemy:givenEnemy createGunAddonInBucket:[spawnerContext renderBucketShadows]];
    }
    
    // half prob select alternate
    if(randomFrac() <= 0.5f)
    {
        [BoarSolo enemy:givenEnemy replaceAnimWithType:animType];
    }

    [newContext release];
}


#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    BoarSoloContext* myContext = [givenEnemy behaviorContext];
    
    // special case for one-time init
    if(BOARSOLO_BEHAVIORSTATE_INIT == myContext.behaviorState)
    {
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];
        [givenEnemy.curAnimClip playClipForward:YES];
        myContext.idleTimer = randomFrac() * [myContext idleDelay];
        myContext.behaviorState = BOARSOLO_BEHAVIORSTATE_IDLE;
    }
    
    // regular state processing
    if(BOARSOLO_BEHAVIORSTATE_IDLE == myContext.behaviorState)
    {
        myContext.idleTimer -= elapsed;
        if(myContext.idleTimer <= 0.0f)
        {
            myContext.timeTillFire = FIREANIM_DELAY;
            myContext.behaviorState = BOARSOLO_BEHAVIORSTATE_TARGETING;
            
            CGPoint playerPos = [[GameManager getInstance] getCamSpacePlayerPos];
            CGPoint myWorldPos;
            if([givenEnemy isGrounded])
            {
                // on the ground, so, it's position needs to be transformed to cam space
                myWorldPos = [self deriveCamPosFromParentForEnemy:givenEnemy];
            }
            else
            {
                // otherwise, we're already in cam space;
                myWorldPos = [self derivePosFromParentForEnemy:givenEnemy];
            }
            CGPoint targetVec = CGPointMake(playerPos.x - myWorldPos.x, playerPos.y - myWorldPos.y);
            
            // get rotation based on zero being (0,-1) in a (0,1) system
            float targetRot = vectorToRadians(targetVec, 3.0f * M_PI_2);      
            BOOL doOffset = (randomFrac() < 0.3f);
            if(doOffset)
            {
                // sometimes they're off
                float randomOffset = (randomFrac() * M_PI * 0.8f) - (M_PI_2 * 0.8f);
                targetRot += randomOffset;
            }
            [myContext setupRotationParamsForSrc:givenEnemy.rotate target:targetRot];
        }
    }
    else if(BOARSOLO_BEHAVIORSTATE_TARGETING == myContext.behaviorState)
    {
        myContext.rotateParam = myContext.rotateParam + elapsed;
        
        // update rotation
        float newRotate = givenEnemy.rotate + (elapsed * myContext.rotateSpeed);
        if(0.0f > newRotate)
        {
            float numOver = truncf(fabsf(newRotate) / (2.0f * M_PI));
            newRotate += ((2.0f * M_PI) * (1.0f + numOver));
        }
        else if(newRotate > (2.0f * M_PI))
        {
            float numOver = truncf(newRotate / (2.0f * M_PI));
            newRotate -= (2.0f * M_PI * numOver);
        }
        givenEnemy.rotate = newRotate;
        
        if(myContext.rotateParamTarget <= myContext.rotateParam)
        {
            if([givenEnemy readyToFire])
            {
                // done targeting, fire
                myContext.behaviorState = BOARSOLO_BEHAVIORSTATE_FIRING;
            
                givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_FIRE];
                [givenEnemy.curAnimClip playClipForward:YES];
                [myContext.gunAddon.anim playClipForward:YES];
            }
            else
            {
                // not ready to fire, go back to IDLE
                myContext.behaviorState = BOARSOLO_BEHAVIORSTATE_IDLE;
                myContext.idleTimer = 0.0f;
            }
        }
    }
    else if(BOARSOLO_BEHAVIORSTATE_FIRING == myContext.behaviorState)
    {       
        myContext.timeTillFire -= elapsed;
        if(myContext.timeTillFire <= 0.0f)
        {
            // fire
            CGPoint firingDir = CGPointMake(0.0f, -1.0f);   // -1 for y because enemy sprite assets face downwards
            CGAffineTransform t = CGAffineTransformMakeRotation(givenEnemy.rotate);
            CGPoint dir = CGPointApplyAffineTransform(firingDir, t);
            CGPoint vel = CGPointMake(dir.x * [myContext shotSpeed], dir.y * [myContext shotSpeed]);
            CGPoint firingPosOffset = CGPointMake(SHOT_OFFSETY * dir.x, SHOT_OFFSETY * dir.y);
            
            CGPoint firingPos;
            if([givenEnemy isGrounded])
            {
                // on the ground, so, it's position needs to be transformed to cam space
                TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
                CGPoint myPos = [self derivePosFromParentForEnemy:givenEnemy];
                firingPos = [gameCam camPointFromWorldPoint:myPos atDistance:[myContext layerDistance]];
            }
            else
            {
                // otherwise, we're already in cam space;
                firingPos = [self derivePosFromParentForEnemy:givenEnemy];
            }

            firingPos.x += firingPosOffset.x;
            firingPos.y += firingPosOffset.y;
            [givenEnemy fireFromPos:firingPos withVel:vel];
            
            myContext.shotCount++;
            if([myContext shotCount] < [myContext shotsPerRound])
            {
                myContext.timeTillFire = [myContext shotDelay];
            }
            else
            {
                myContext.idleTimer = (randomFrac()+0.5f) * myContext.idleDelay;
                myContext.shotCount = 0;
                myContext.behaviorState = BOARSOLO_BEHAVIORSTATE_IDLE;
            }
            givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_IDLE];
            [givenEnemy.curAnimClip playClipForward:YES];
        }
    }
}

- (NSString*) getEnemyTypeName
{
    return @"BoarSoloGun";
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
    BoarSoloContext* myContext = [enemy behaviorContext];
    myContext.hitCounts++;
    if(NUM_HITS_PER_RESPONSE <= myContext.hitCounts)
    {
        myContext.hitCounts = 0;
        TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
        CGPoint myPos = [self derivePosFromParentForEnemy:enemy];
        CGPoint firingPos = myPos;
        if([enemy isGrounded])
        {
            // on the ground, so, it's position needs to be transformed to cam space
            firingPos = [gameCam camPointFromWorldPoint:myPos atDistance:[[enemy behaviorContext] layerDistance]];
        }
        
        Effect* hitEffect = [[[LevelManager getInstance] effectFactory] createEffectNamed:@"BulletHit" atPos:CGPointMake(firingPos.x + HITEFFECT_X, firingPos.y + HITEFFECT_Y)];
        [hitEffect spawn];
        [hitEffect release];
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
    if(![enemy readyToFire])
    {
        // not ready for collision if not ready to fire
        result = NO;
    }
    return result;
}


#pragma mark -
#pragma mark EnemyAABBDelegate
- (CGRect) getAABB:(Enemy *)givenEnemy
{
    float halfWidth = givenEnemy.colAABB.size.width * 0.5f;
    float halfHeight = givenEnemy.colAABB.size.height * 0.5f;
        
    TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
    CGPoint myPos = [self derivePosFromParentForEnemy:givenEnemy];
    CGPoint firingPos = myPos;
    if([givenEnemy isGrounded])
    {
        // on the ground, so, it's position needs to be transformed to cam space
        firingPos = [gameCam camPointFromWorldPoint:myPos atDistance:[[givenEnemy behaviorContext] layerDistance]];
    }
    CGRect result = CGRectMake(firingPos.x - halfWidth, firingPos.y - halfHeight, givenEnemy.colAABB.size.width, givenEnemy.colAABB.size.height);
    return result;  
}

#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    if(![givenEnemy incapacitated])
    {
        BoarSoloContext* myContext = [givenEnemy behaviorContext];

        // release gunAddon entries
        myContext.gunAddon = nil;
    }
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    BoarSoloContext* myContext = [givenEnemy behaviorContext];

    // play falling effect
    TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
    CGPoint myPos = [self derivePosFromParentForEnemy:givenEnemy];
    CGPoint firingPos = myPos;
    if([givenEnemy isGrounded])
    {
        // on the ground, so, it's position needs to be transformed to cam space
        firingPos = [gameCam camPointFromWorldPoint:myPos atDistance:[[givenEnemy behaviorContext] layerDistance]];
    }
    
    if(![givenEnemy hidden])
    {
        Effect* explosion = [[[LevelManager getInstance] effectFactory] createEffectNamed:@"BoarSoloDown" 
                                                                                    atPos:firingPos];
        [explosion spawn];
        [explosion release];
    }
    
    // release gunAddon entries
    myContext.gunAddon = nil;
    
    // show points gained
    if(showPoints)
    {
        [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                               atPos:firingPos];
    }
    
    // check achievements
    [[AchievementsManager getInstance] checkBoarAchievementsForEnemy:givenEnemy];
    
    // play sound
    [[SoundManager getInstance] playClip:@"BoarSoloHit"];
    
    if([[GameManager getInstance] shouldReleasePickups])
    {   
        // drop loots
        // dequeue game manager pickup
        NSString* pickupType = [[GameManager getInstance] dequeueNextHealthPack];
        if(([myContext hasCargo]) || (pickupType))
        {
            if(nil == pickupType)
            {
                pickupType = @"LootCash";
            }
            // drop cargo
            Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:pickupType atPos:firingPos 
                                                                             isDynamics:YES 
                                                                    groundedBucketIndex:0 
                                                                          layerDistance:0.0f];
            [newLoot spawn];
            [newLoot release];
        }
    }
    
    // interrupt any state and put the gun into the DESTROYED state
    myContext.behaviorState = BOARSOLO_BEHAVIORSTATE_DESTROYED;

    // returns YES to have this guy killed immediately
    return YES;
}

@end
