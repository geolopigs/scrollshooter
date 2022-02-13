//
//  BoarFighterSpawner.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "BoarFighterSpawner.h"
#import "EnemySpawner.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "BoarFighterArchetype.h"

// behavior constants
static const float BOARFIGHTER_DISTTILLTURN = 30.0f;
static const float TIME_BETWEEN_ROCKS = 1.3f;
static const float INITVEL_X = 0.0f;
static const float INITVEL_Y = -20.0f;
static const float FINALSPEED_X = 120.0f;
static const float FINALSPEED_Y = 60.0f;
static const float ACCEL_X = 50.0f;
static const float ACCEL_Y = -80.0f;


@implementation BoarFighterSpawnerContext
@synthesize timeToRock;
@synthesize nextDirection;

- (id) init
{
    self = [super init];
    if(self)
    {
        timeToRock = TIME_BETWEEN_ROCKS;
        nextDirection = 1.0f;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

#pragma mark - EnemySpawnerContextDelegate
- (NSDictionary*) spawnerTriggerContext
{
    // BoarFighterSpawner trigger context not yet implemented
    return nil;
}

- (float) spawnerLayerDistance
{
    return 100.0f;
}


@end

@interface BoarFighterSpawner (PrivateMethods)
- (void) initSpawnerContext:(EnemySpawner*)spawner;
@end

@implementation BoarFighterSpawner

#pragma mark - Private Methods
- (void) initSpawnerContext:(EnemySpawner *)spawner
{
    BoarFighterSpawnerContext* newContext = [[BoarFighterSpawnerContext alloc] init];
    spawner.spawnerContext = newContext;
    [newContext release];    
}

#pragma mark -
#pragma mark EnemySpawnerDelegate

- (void) initEnemySpawner:(EnemySpawner*)spawner withContextInfo:(NSMutableDictionary *)info
{
    [self initSpawnerContext:spawner];
}

- (void) restartEnemySpawner:(EnemySpawner *)spawner
{
    [self initSpawnerContext:spawner];
}

- (Enemy*) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    Enemy* newEnemy = nil;
    BoarFighterSpawnerContext* spawnerContext = [spawner spawnerContext];
    spawnerContext.timeToRock -= elapsed;
    if(0.0f >= spawnerContext.timeToRock)
    {
        CGPoint initPos = CGPointMake(40.0f, 150.0f);
        if(0.0f > spawnerContext.nextDirection)
        {
            initPos.x = 80.0f;
        }
        newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"BoarFighterFixed" AtPos:initPos];
        newEnemy.vel = CGPointMake(INITVEL_X, INITVEL_Y);
        
        BoarFighterContext* newContext = [[BoarFighterContext alloc] init];
        newContext.lastY = newEnemy.pos.y;
        newContext.distTillTurn = BOARFIGHTER_DISTTILLTURN;        
        newContext.finalSpeed = CGPointMake(FINALSPEED_X, FINALSPEED_Y);
        newContext.accel = CGPointMake(spawnerContext.nextDirection * ACCEL_X, ACCEL_Y);
        newContext.timeTillFire = 0.0f;
        newContext.firingSlot = 0;
        newEnemy.behaviorContext = newContext;
        [newContext release];
        
        // alternate x-direction for each enemy
        spawnerContext.nextDirection *= -1.0f;        
        spawnerContext.timeToRock = TIME_BETWEEN_ROCKS;
    }
    
    return newEnemy;
}

- (void) retireEnemies:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    // HACK - kill out of screen enemies
    for(Enemy* cur in spawner.spawnedEnemies)
    {
        if(-10.0f >= cur.pos.y)
        {
            [cur kill];
        }
    }
    // HACK
}

- (void) activateEnemySpawner:(EnemySpawner*)spawner withTriggerContext:(NSDictionary*)context
{
    [spawner setActivated:YES];    
}


@end
