//
//  DuaSeatoSpawner.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "DuaSeatoSpawner.h"
#import "EnemySpawner.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "GameManager.h"
#import "RenderBucketsManager.h"
#import "DuaSeatoArchetype.h"
#include "MathUtils.h"

// behavior constants
static const float TIME_BETWEEN_SPAWNS = 3.0f;


@implementation DuaSeatoSpawnerContext
@synthesize timeTillSpawn;
@synthesize spawnCounter;
@synthesize useIntroPos;
@synthesize introPos;
@synthesize introDir;
@synthesize introVel;
@synthesize maxEnemiesAlive;
@synthesize timeBetweenSpawns;
@synthesize spawnPosArray;
@synthesize triggerName;
@synthesize triggerContext;
@synthesize dynamicsShadowsIndex;
@synthesize dynamicsBucketIndex;
@synthesize dynamicsAddonsIndex;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.triggerName = nil;
        self.triggerContext = nil;

        // normalized direction
        useIntroPos = NO;
        introPos = CGPointMake(0.2, -0.2f);
        introDir = M_PI;
        introVel = CGPointMake(0.0f, 1.0f);
        maxEnemiesAlive = 2;
        timeBetweenSpawns = TIME_BETWEEN_SPAWNS;
        self.spawnPosArray = [NSArray arrayWithObjects:
                              [NSValue valueWithCGPoint:CGPointMake(0.2f, -0.2f)],
                              [NSValue valueWithCGPoint:CGPointMake(0.8f, -0.2f)], 
                              [NSValue valueWithCGPoint:CGPointMake(0.3f, -0.2f)], 
                              [NSValue valueWithCGPoint:CGPointMake(0.7f, -0.2f)], 
                              nil];
        
        // runtime params
        timeTillSpawn = 0.0f;
        spawnCounter = 0;
    }
    return self;
}

- (void) dealloc
{
    self.spawnPosArray = nil;
    self.triggerContext = nil;
    self.triggerName = nil;
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

@interface DuaSeatoSpawner (PrivateMethods)
- (void) initSpawnerContext:(EnemySpawner*)spawner withContextInfo:(NSMutableDictionary *)info;
@end

@implementation DuaSeatoSpawner

#pragma mark - PrivateMethods
- (void) initSpawnerContext:(EnemySpawner *)spawner withContextInfo:(NSMutableDictionary *)info
{
    DuaSeatoSpawnerContext* newContext = [[DuaSeatoSpawnerContext alloc] init];
    spawner.spawnerContext = newContext;
    if(info)
    {
        newContext.triggerName = [info objectForKey:@"triggerName"];
    }
    newContext.dynamicsShadowsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Shadows"];
    newContext.dynamicsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Dynamics"];
    newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Addons"];

    [newContext release];    
}

#pragma mark -
#pragma mark EnemySpawnerDelegate

- (void) initEnemySpawner:(EnemySpawner*)spawner withContextInfo:(NSMutableDictionary *)info
{
    [self initSpawnerContext:spawner withContextInfo:info];
}

- (void) restartEnemySpawner:(EnemySpawner *)spawner
{
    DuaSeatoSpawnerContext* spawnerContext = [spawner spawnerContext];
    spawnerContext.spawnCounter = 0;
    spawnerContext.timeTillSpawn = 0.0f;
}

- (Enemy*) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    Enemy* newEnemy = nil;
    DuaSeatoSpawnerContext* spawnerContext = [spawner spawnerContext];

    // spawn one at a time
    if([spawnerContext maxEnemiesAlive] > [spawner.spawnedEnemies count])
    {
        spawnerContext.timeTillSpawn -= elapsed;
        if(0.0f >= spawnerContext.timeTillSpawn)
        {
            CGRect playArea = [[GameManager getInstance] getPlayArea];
            unsigned int spawnCounter = [spawnerContext spawnCounter];
            CGPoint initPos = [[spawnerContext.spawnPosArray objectAtIndex:spawnCounter] CGPointValue]; 
            if([spawnerContext useIntroPos])
            {
                initPos = [spawnerContext introPos];
            }
            
            initPos = CGPointMake(initPos.x * playArea.size.width, initPos.y * playArea.size.height);
            newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"DuaSeato" AtPos:initPos withSpawnerContext:spawnerContext];
            
            // init velocity and facing direction
            newEnemy.vel = spawnerContext.introVel;
            newEnemy.rotate = M_PI;
                        
            ++spawnCounter;
            if(spawnCounter >= [spawnerContext.spawnPosArray count])
            {
                spawnCounter = 0;
            }
            spawnerContext.spawnCounter = spawnCounter;
            spawnerContext.timeTillSpawn = spawnerContext.timeBetweenSpawns;
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
    DuaSeatoSpawnerContext * spawnerContext = [spawner spawnerContext];
    spawnerContext.triggerContext = context;
    if(context)
    {
        float introSpeed = [[context objectForKey:@"introSpeed"] floatValue];
        CGPoint introVel = CGPointMake(0.0f, 1.0f);
        introVel.x *= introSpeed;
        introVel.y *= introSpeed;
        spawnerContext.introVel = introVel;
        spawnerContext.timeBetweenSpawns = [[context objectForKey:@"timeBetweenSpawns"] floatValue];
        spawnerContext.maxEnemiesAlive = [[context objectForKey:@"maxAlive"] floatValue];
        
        NSNumber* contextIntroDir = [context objectForKey:@"introDir"];
        NSNumber* contextIntroPosX = [context objectForKey:@"introPosX"];
        NSNumber* contextIntroPosY = [context objectForKey:@"introPosY"];
        if((contextIntroDir) && (contextIntroPosX) && (contextIntroPosY))
        {
            spawnerContext.useIntroPos = YES;
            spawnerContext.introPos = CGPointMake([contextIntroPosX floatValue], [contextIntroPosY floatValue]);
            float introDir = [contextIntroDir floatValue] * M_PI;
            spawnerContext.introVel = radiansToVector(CGPointMake(0.0f, -1.0f), introDir, introSpeed);
        }
    }
}


@end
