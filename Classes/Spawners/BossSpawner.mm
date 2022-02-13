//
//  BossSpawner.mm
//  PeterPog
//
//  Generic Boss spawner
//
//  Created by Shu Chiun Cheah on 9/22/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "BossSpawner.h"
#import "EnemySpawner.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "BossArchetype.h"
#import "RenderBucketsManager.h"
#import "GameManager.h"
#include "MathUtils.h"

// behavior constants
static const float TIME_BETWEEN_SPAWNS = 14.0f;
static const float INITVEL_X = 0.0f;
static const float INITVEL_Y = -20.0f;


@implementation BossSpawnerContext
@synthesize timeTillSpawn;
@synthesize triggerContext;
@synthesize introPos;
@synthesize enemyTypeName;
@synthesize dynamicsShadowsIndex;
@synthesize dynamicsBucketIndex;
@synthesize dynamicsAddonsIndex;

- (id) init
{
    self = [super init];
    if(self)
    {
        timeTillSpawn = 0.0f;
        
        // normalized direction
        introPos = CGPointMake(50.0f, 200.0f);
        
        // default config params
        self.triggerContext = nil;
        self.enemyTypeName = @"BoarBlimp";
    }
    return self;
}

- (void) dealloc
{
    self.enemyTypeName = nil;
    self.triggerContext = nil;
    [super dealloc];
}

#pragma mark - EnemySpawnerContextDelegate
- (NSDictionary*) spawnerTriggerContext
{
    return triggerContext;
}

- (float) spawnerLayerDistance
{
    return 100.0f;
}


@end

@interface BossSpawner (PrivateMethods)
- (void) initSpawnerContext:(EnemySpawner*)spawner;
@end

@implementation BossSpawner


#pragma mark - Private Methods
- (void) initSpawnerContext:(EnemySpawner *)spawner
{
    BossSpawnerContext* newContext = [[BossSpawnerContext alloc] init];
    newContext.dynamicsShadowsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Shadows"];
    newContext.dynamicsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"BigDynamics"];
    newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"BigAddons"];
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
    BossSpawnerContext* spawnerContext = [spawner spawnerContext];
    spawnerContext.timeTillSpawn = 0.0f;
}

- (Enemy*) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    Enemy* newEnemy = nil;

    // spawn one at a time
    if(0 == [spawner.spawnedEnemies count])
    {
        BossSpawnerContext* spawnerContext = [spawner spawnerContext];
        spawnerContext.timeTillSpawn -= elapsed;
        if(0.0f >= spawnerContext.timeTillSpawn)
        {
            CGPoint initPos = [spawnerContext introPos];
            newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:[spawnerContext enemyTypeName] AtPos:initPos withSpawnerContext:spawnerContext];            
            spawnerContext.timeTillSpawn = TIME_BETWEEN_SPAWNS;
        }
    }    
    
    return newEnemy;
}

- (void) retireEnemies:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    for(Enemy* cur in spawner.spawnedEnemies)
    {
        if([cur willRetire])
        {
            [cur kill];
        }
    }
}


- (void) activateEnemySpawner:(EnemySpawner*)spawner withTriggerContext:(NSDictionary*)context
{
    [spawner setActivated:YES];    
    BossSpawnerContext * spawnerContext = [spawner spawnerContext];
    spawnerContext.triggerContext = context;
    if(context)
    {
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        float introPosX = [[context objectForKey:@"introPosX"] floatValue] * playArea.size.width;
        float introPosY = [[context objectForKey:@"introPosY"] floatValue] * playArea.size.height;
        spawnerContext.introPos = CGPointMake(introPosX, introPosY);
        spawnerContext.enemyTypeName = [context objectForKey:@"typename"];
    }
}


@end
