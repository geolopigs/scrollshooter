//
//  BossWeapon.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/23/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "BossWeapon.h"
#import "Enemy.h"
#import "ScatterBomb.h"
#import "EnemyFactory.h"
#import "RenderBucketsManager.h"
#import "GameManager.h"
#import "Player.h"
#import "PlayerMissile.h"
#import "Boomerang.h"
#import "Laser.h"
#import "NSDictionary+Curry.h"
#include "MathUtils.h"

enum BossWeaponTypes
{
    WEAPON_NONE = 0,
    WEAPON_SCATTER,
    WEAPON_HOMINGMISSILE,
    WEAPON_LASER,
    WEAPON_BOOMERANG,
    
    WEAPON_NUM
};

static const float PLAYERMISSILE_FIREPOS = 7.5f;

@interface BossWeapon (PrivateMethods)
- (unsigned int) getWeaponTypeFromName:(NSString*)name;
- (void) setupScatter;
- (void) setupHomingMissile;
- (void) setupLaser;
- (void) setupBoomerang;
- (void) enemyFireScatter:(Enemy*)enemy fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed;
- (void) playerFireMissile:(Player*)player fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed;
- (void) playerFireLaser:(Player*)player fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed;
- (void) playerFireBoomerang:(Player*)player fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed;
- (void) enemyFireLaser:(Enemy*)enemy fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed;
- (BOOL) handleKilledEnemy:(Enemy*)enemy;
- (void) enemy:(Enemy*)enemy updateWeapon:(NSTimeInterval)elapsed;
- (void) retireLaser:(NSTimeInterval)elapsed;
@end

@implementation BossWeapon
@synthesize scatterBombContext;
@synthesize missileContext;
@synthesize missileType = _missileType;
@synthesize laserContext;
@synthesize timeTillFire;
@synthesize activeMissiles;
@synthesize activeComponents;
@synthesize startupTimer = _startupTimer;

@synthesize startupDelay = _startupDelay;
@synthesize shotDelay;
@synthesize localPos;
@synthesize config;
@synthesize weaponType;

- (id) initFromConfig:(NSDictionary *)givenConfig
{
    self = [super init];
    if(self)
    {
        // config
        shotDelay = 1.0f;
        _startupDelay = 0.0f;
        self.config = givenConfig;
        self.scatterBombContext = nil;
        self.missileContext = nil;
        self.missileType = @"PlayerMissile";
        self.laserContext = nil;

        // runtime
        self.activeMissiles = [NSMutableArray array];
        self.activeComponents = [NSMutableArray array];
        localPos = CGPointMake(0.0f, 0.0f);
        shotPos = CGPointMake(0.0f, 0.0f);
        timeTillFire = 0.0f;
        roundsFired = 0;

        // setup common config params
        NSNumber* configShotDelay = [config objectForKey:@"shotDelay"];
        if(configShotDelay)
        {
            shotDelay = [configShotDelay floatValue];
        }
        NSNumber* configShotPosX = [config objectForKey:@"shotPosX"];
        NSNumber* configShotPosY = [config objectForKey:@"shotPosY"];
        if(configShotPosX && configShotPosY)
        {
            shotPos = CGPointMake([configShotPosX floatValue], [configShotPosY floatValue]);
        }
        NSNumber* configStartupDelay = [config objectForKey:@"startupDelay"];
        if(configStartupDelay)
        {
            _startupDelay = [configStartupDelay floatValue];
        }

        // setup type specific config params
        weaponType = [self getWeaponTypeFromName:[givenConfig objectForKey:@"weaponType"]];
        switch (weaponType) 
        {
            case WEAPON_SCATTER:
                [self setupScatter];
                break;
                
            case WEAPON_HOMINGMISSILE:
                [self setupHomingMissile];
                break;
                
            case WEAPON_LASER:
                [self setupLaser];
                break;
                
            case WEAPON_BOOMERANG:
                [self setupBoomerang];
                break;
                
            default:
                break;
        }

        // runtime 
        _startupTimer = _startupDelay;
    }
    return self;
}

- (void) dealloc
{
    self.activeComponents = nil;
    self.activeMissiles = nil;
    self.laserContext = nil;
    self.missileType = nil;
    self.missileContext = nil;
    self.scatterBombContext = nil;
    self.config = nil;
    [super dealloc];
}

// reset to init states
- (void) reset
{
    _startupTimer = _startupDelay;
    timeTillFire = 0.0f;
    roundsFired = 0.0f;
}

- (BOOL) playerFire:(Player *)player elapsed:(NSTimeInterval)elapsed
{
    BOOL shotsFired = NO;
    if(_startupTimer > 0.0f)
    {
        _startupTimer -= elapsed;
    }
    else
    {
        CGPoint firingPos = [player pos];
        firingPos.x += (localPos.x + shotPos.x);
        firingPos.y += (localPos.y + shotPos.y);
        shotsFired = [self playerFire:player fromPos:firingPos elapsed:elapsed];
    }
    return shotsFired;
}

- (BOOL) playerFire:(Player *)player fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed
{
    BOOL shotsFired = NO;
    timeTillFire -= elapsed;
    if(0.0f >= timeTillFire)
    {
        timeTillFire = shotDelay;
        switch (weaponType) 
        {
            case WEAPON_SCATTER:
                // not implemented for Player yet
                break;
                
            case WEAPON_HOMINGMISSILE:
                [self playerFireMissile:player fromPos:pos elapsed:elapsed];
                break;
                
            case WEAPON_LASER:
                [self playerFireLaser:player fromPos:pos elapsed:elapsed];
                break;
                
            case WEAPON_BOOMERANG:
                [self playerFireBoomerang:player fromPos:pos elapsed:elapsed];
                break;
                
            default:
                break;
        }
        shotsFired = YES;
    }
    return shotsFired;
}

// allow each weapon-type a chance to do some per-frame processing
- (void) playerUpdateWeapon:(NSTimeInterval)elapsed
{
    switch (weaponType) 
    {
        case WEAPON_SCATTER:
            // do nothing
            break;
            
        case WEAPON_HOMINGMISSILE:
            [self killRetiredMissiles];
            break;
            
        case WEAPON_LASER:
            [self retireLaser:elapsed];
            break;
            
        case WEAPON_BOOMERANG:
            [self killRetiredMissiles];
            break;
            
        default:
            break;
    }
    
}

- (BOOL) enemyFire:(Enemy *)enemy elapsed:(NSTimeInterval)elapsed
{
    BOOL shotsFired = NO;
    if(_startupTimer > 0.0f)
    {
        _startupTimer -= elapsed;
    }
    else
    {
        CGPoint firingPos = [enemy pos];
        firingPos.x += (localPos.x + shotPos.x);
        firingPos.y += (localPos.y + shotPos.y);
        shotsFired = [self enemyFire:enemy fromPos:firingPos elapsed:elapsed];
    }
    return shotsFired;
}

- (BOOL) enemyFire:(Enemy *)enemy fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed
{
    BOOL shotsFired = NO;
    timeTillFire -= elapsed;
    if(0.0f >= timeTillFire)
    {
        timeTillFire = shotDelay;

        CGPoint firingPos = pos;
        firingPos.x += shotPos.x;
        firingPos.y += shotPos.y;

        switch (weaponType) 
        {
            case WEAPON_SCATTER:
                [self enemyFireScatter:enemy fromPos:firingPos elapsed:elapsed];
                break;
              
            case WEAPON_HOMINGMISSILE:
                // not implemented for enemies yet
                NSLog(@"Homing Missile not implemented for Enemy yet");
                break;
                
            case WEAPON_LASER:
                [self enemyFireLaser:enemy fromPos:firingPos elapsed:elapsed];
                break;
                
            default:
                break;
        }
        shotsFired = YES;
    }
    [self enemy:enemy updateWeapon:elapsed];

    return shotsFired;
}

// allow each weapon-type a chance to do some per-frame processing
- (void) enemy:(Enemy *)enemy updateWeapon:(NSTimeInterval)elapsed
{
    switch (weaponType) 
    {
        case WEAPON_SCATTER:
            // do nothing
            break;
            
        case WEAPON_HOMINGMISSILE:
            // do nothing
            break;
            
        case WEAPON_LASER:
            [self retireLaser:elapsed];
            break;
            
        default:
            break;
    }

}

- (void) retireLaser:(NSTimeInterval)elapsed
{
    if(0 < [activeComponents count])
    {
        // one laser at a time
        assert(1 == [activeComponents count]);
        Enemy* cur = [activeComponents objectAtIndex:0];
        if([cur willRetire])
        {
            [cur incapAndKill];
            
            // reset timeTillFire
            timeTillFire = shotDelay;
        }
    }
}


#pragma mark - private methods
- (unsigned int) getWeaponTypeFromName:(NSString *)name
{
    unsigned int result = WEAPON_NONE;
    if(name)
    {
        if([name isEqualToString:@"scatter"])
        {
            result = WEAPON_SCATTER;
        }
        else if([name isEqualToString:@"homingMissile"])
        {
            result = WEAPON_HOMINGMISSILE;
        }
        else if([name isEqualToString:@"laser"])
        {
            result = WEAPON_LASER;
        }
        else if([name isEqualToString:@"boomerang"])
        {
            result = WEAPON_BOOMERANG;
        }
    }
    return result;
}

- (void) setupScatter
{
    scatterBegin = [[config objectForKey:@"scatterBegin"] floatValue] * M_PI;
    scatterShotsPerRound = [[config objectForKey:@"scatterShotsPerRound"] unsignedIntValue];
    shotSpeed = [[config objectForKey:@"shotSpeed"] floatValue];
//    shotDelay = [[config objectForKey:@"shotDelay"] floatValue];
    overheatRounds = [[config objectForKey:@"overheatRounds"] unsignedIntValue];
    cooldownDelay = [[config objectForKey:@"cooldownDelay"] floatValue];

    float scatterLength = [[config objectForKey:@"scatterLength"] floatValue] * M_PI;
    scatterInterval = scatterLength / scatterShotsPerRound;
    
    timeTillFire = cooldownDelay;
    
    // setup scatter bomb if config has it
    NSDictionary* scatterBomb = [config objectForKey:@"scatterBomb"];
    if(scatterBomb)
    {
        self.scatterBombContext = scatterBomb;
    }
}

- (void) setupHomingMissile
{
    // defaults
    missilesPerRound = 4;
    missileAngleBegin = -0.25f * M_PI;
    missileAngleSpan = 0.5f * M_PI;
    
    // configs
    NSNumber* configNumPerRound = [config objectForKey:@"numPerRound"];
    if(configNumPerRound)
    {
        missilesPerRound = [configNumPerRound unsignedIntValue];
        if(2 > missilesPerRound)
        {
            missilesPerRound = 2;
        }
    }
    missileAngleBegin = [config getFloatForKey:@"missileAngleBegin" withDefault:-0.25f] * M_PI;
    missileAngleSpan = [config getFloatForKey:@"missileAngleSpan" withDefault:0.5f] * M_PI;
    
    self.missileContext = [config objectForKey:@"missileSpec"];
    if([self missileContext])
    {
        NSString* subType = [self.missileContext objectForKey:@"subType"];
        if(subType && [subType isEqualToString:@"straight"])
        {
            // straight subtype is BlueMissile
            self.missileType = @"BlueMissile";
        }
        else
        {
            // otherwise, it's PlayerMissile
            self.missileType = @"PlayerMissile";
        }
    }
}

- (void) setupLaser
{
    // configs
    self.laserContext = [config objectForKey:@"laserSpec"];
}

- (void) setupBoomerang
{
    // configs
    missilesPerRound = [config getIntForKey:@"numPerRound" withDefault:4];
    missileAngleBegin = [config getFloatForKey:@"boomerangAngleBegin" withDefault:0.0f] * M_PI;
    missileAngleSpan = [config getFloatForKey:@"boomerangAngleSpan" withDefault:0.20f] * M_PI;
    
    self.missileContext = [config objectForKey:@"boomerangSpec"];
    
}

- (void) enemyFireScatter:(Enemy *)enemy fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed
{
    float curRotate = scatterBegin;
    CGPoint firingDir = CGPointMake(-1.0f, 0.0f);
    for(int i = 0; i < scatterShotsPerRound; ++i)
    {
        CGAffineTransform t = CGAffineTransformMakeRotation(curRotate);
        CGPoint dir = CGPointApplyAffineTransform(firingDir, t);
        CGPoint vel = CGPointMake(dir.x * shotSpeed, dir.y * shotSpeed);
        
        if([self scatterBombContext])
        {
            [BossWeapon enemyFireScatterBomb:enemy fromPos:pos withVel:vel triggerContext:[self scatterBombContext]];
        }
        else
        {
            [enemy fireFromPos:pos withVel:vel];
        }
        curRotate += scatterInterval;
    } 
    
    roundsFired++;
    if(roundsFired > overheatRounds)
    {
        timeTillFire = cooldownDelay;
        roundsFired = 0;
    }
}

- (void) playerFireMissile:(Player *)player fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed
{
    unsigned int shotCount = 0;
    float incr = missileAngleSpan / (missilesPerRound - 1);
    float cur = missileAngleBegin;
    while(shotCount < missilesPerRound)
    {
        // offset firing-pos in the firing direction
        CGPoint firingPos = pos;
        CGPoint dirVec = radiansToVector(CGPointMake(0.0f, 1.0f), cur, PLAYERMISSILE_FIREPOS);
        firingPos.x += dirVec.x;
        firingPos.y += dirVec.y;
        
        Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:[self missileType] AtPos:firingPos];
        newEnemy.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Bullets"];
        PlayerMissileContext* newContext = [[PlayerMissileContext alloc] init];
        [newContext setupFromTriggerContext:[self missileContext]];
        
        // retain target enemy
        newContext.target = [[GameManager getInstance] getValueEnemyAtIndex:shotCount];
        newContext.initDir = cur;
        newContext.shotIndex = shotCount;
        
        newEnemy.behaviorContext = newContext;
        [newContext release];
        
        // retain missile and register self as killedDelegate to release missile
        [activeMissiles addObject:newEnemy];
        newEnemy.killedDelegate = self;
        
        [newEnemy spawn];
        [newEnemy release];

        ++shotCount;
        cur += incr;
    }
}

- (void) playerFireBoomerang:(Player *)player fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed
{
    unsigned int shotCount = 0;
    float incr = missileAngleSpan / (missilesPerRound - 1);
    float cur = missileAngleBegin;
    while(shotCount < missilesPerRound)
    {
        // offset firing-pos in the firing direction
        CGPoint firingPos = pos;
        CGPoint dirVec = radiansToVector(CGPointMake(0.0f, 1.0f), cur, PLAYERMISSILE_FIREPOS);
        firingPos.x += dirVec.x;
        firingPos.y += dirVec.y;
        
        Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"Boomerang" AtPos:firingPos];
        newEnemy.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Bullets"];
        BoomerangContext* newContext = [[BoomerangContext alloc] init];
        [newContext setupFromTriggerContext:[self missileContext]];
        
        // set initial direction to match the gun direction
        newContext.initDir = cur;
        
        newEnemy.behaviorContext = newContext;
        [newContext release];
        
        // retain missile and register self as killedDelegate to release missile
        [activeMissiles addObject:newEnemy];
        newEnemy.killedDelegate = self;
        
        [newEnemy spawn];
        [newEnemy release];
        
        ++shotCount;
        cur += incr;
    }
}


- (void) enemyFireLaser:(Enemy *)enemy fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed
{
    // Laser manages its own firing; so, only need to fire once here
    if(0 == [activeComponents count])
    {
        // laser is attached as a child to the firing enemy; so, it's position needs to be in parent space
        CGPoint firingPos = pos;
        firingPos.x -= [enemy pos].x;
        firingPos.y -= [enemy pos].y;

        Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"Laser" AtPos:firingPos];
        newEnemy.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Bullets"];
        LaserContext* newContext = [[LaserContext alloc] init];
        [newContext setupFromTriggerContext:[self laserContext]];
        
        newEnemy.behaviorContext = newContext;
        [newContext release];
        
        // attach myself as parent
        newEnemy.parentEnemy = enemy;
        
        [activeComponents addObject:newEnemy];
        newEnemy.killedDelegate = self;
        [newEnemy spawn];
        [newEnemy release];
    }
}

- (void) playerFireLaser:(Player *)player fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed
{
    // Laser manages its own firing; so, only need to fire once here
    if(0 == [activeComponents count])
    {
        // laser is attached as a child to the firing enemy; so, it's position needs to be in parent space
        CGPoint firingPos = pos;
        firingPos.x -= [player pos].x;
        firingPos.y -= [player pos].y;
        
        Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"PlayerLaser" AtPos:firingPos];
        newEnemy.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Bullets"];
        LaserContext* newContext = [[LaserContext alloc] init];
        [newContext setupFromTriggerContext:[self laserContext]];
        
        newEnemy.behaviorContext = newContext;
        [newContext release];
        
        // use player as parent
        newEnemy.hasPlayerParent = YES;
        
        [activeComponents addObject:newEnemy];
        newEnemy.killedDelegate = self;
        [newEnemy spawn];
        [newEnemy release];
    }
}


- (void) killRetiredMissiles
{
    NSMutableArray* trash = [NSMutableArray array];
    for(Enemy* cur in activeMissiles)
    {
        if([cur willRetire])
        {
            cur.killedDelegate = nil;
            [cur kill];
            [trash addObject:cur];
        }
    }
    for(Enemy* cur in trash)
    {
        [activeMissiles removeObject:cur];
    }
    [trash removeAllObjects];
}

- (void) killAllMissiles
{
    for(Enemy* cur in activeMissiles)
    {
        cur.killedDelegate = nil;
        [cur kill];
    }
    [activeMissiles removeAllObjects];
}

- (void) killAllComponents
{
    for(Enemy* cur in activeComponents)
    {
        cur.killedDelegate = nil;
        [cur incapAndKill];
    }
    [activeComponents removeAllObjects];    
}

+ (void) enemyFireScatterBomb:(Enemy*)enemy fromPos:(CGPoint)pos withVel:(CGPoint)vel triggerContext:(NSDictionary*)triggerContext
{
    if(([enemy readyToFire]) && (![enemy incapacitated]))
    {
        Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"ScatterBomb" AtPos:pos];
        newEnemy.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Bullets"];
        
        // create context
        ScatterBombContext* newContext = [[ScatterBombContext alloc] init];
        [newContext setupFromTriggerContext:triggerContext];
        newContext.initVel = vel;
        
        newEnemy.vel = [newContext initVel];
        newEnemy.behaviorContext = newContext;
        [newContext release];
        
        // set weapon
        newEnemy.readyToFire = YES;
        
        // add it to spawnedEnemies
        [[GameManager getInstance].delayedWeapons addObject:newEnemy];
        [newEnemy spawn];
        [newEnemy release];
    }
}


#pragma mark - EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    if(![givenEnemy incapacitated])
    {
        [self handleKilledEnemy:givenEnemy];
    }
    if([[givenEnemy behaviorContext] isMemberOfClass:[PlayerMissileContext class]])
    {
        [activeMissiles removeObject:givenEnemy];
    }
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    BOOL killImmediately = [self handleKilledEnemy:givenEnemy];
    return killImmediately;
}

- (BOOL) handleKilledEnemy:(Enemy *)enemy
{
    BOOL killImmediately = YES; // by default, all BossWeapon spawned enemies get killed immediately
    if([[enemy behaviorContext] isMemberOfClass:[PlayerMissileContext class]])
    {
        // do missile-specific incap
        [PlayerMissile incapacitateEnemy:enemy];
        
        // don't kill yet until trail finishes (at which point PlayerMissile will set the willRetire flag)
        killImmediately = NO;
    }
    else
    {
        [activeComponents removeObject:enemy];
    }    
    return killImmediately;
}

@end
