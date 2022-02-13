//
//  DynamicSpawner.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/9/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "DynamicsSpawner.h"
#import "EnemySpawner.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "BoarSolo.h"
#import "RenderBucketsManager.h"
#import "LevelManager.h"
#import "Level.h"
#import "TopCam.h"

// behavior constants
static const float INITVEL_X = 0.0f;
static const float INITVEL_Y = 0.0f;


@implementation DynamicsSpawnerContext
@synthesize spawnPositions;
@synthesize layerDistance;
@synthesize objectTypename;
@synthesize dynamicsShadowsIndex;
@synthesize dynamicsBucketIndex;
@synthesize dynamicsAddonsIndex;
@synthesize groundedBucketShadows;
@synthesize groundedBucket;
@synthesize groundedBucketAddons;
@synthesize spawnedOnce;
@synthesize spawnedCount;
@synthesize triggerName;
@synthesize triggerContext;

- (id) initWithArray:(NSArray*)positionsArray 
          atDistance:(float)dist 
      objectTypename:(NSString *)givenObjectTypename 
      triggerContext:(NSDictionary *)triggerParms
{
    self = [super init];
    if(self)
    {
        self.spawnPositions = positionsArray;
        self.layerDistance = dist;
        self.objectTypename = [NSString stringWithString:givenObjectTypename];
        self.dynamicsShadowsIndex = 0;
        self.dynamicsBucketIndex = 0;
        self.dynamicsAddonsIndex = 0;
        self.groundedBucketShadows = 0;
        self.groundedBucket = 0;
        self.groundedBucketAddons = 0;
        self.spawnedOnce = NO;
        self.spawnedCount = 0;
        self.triggerContext = triggerParms;
    }
    return self;
}

- (void) dealloc
{
    self.triggerContext = nil;
    self.objectTypename = nil;
    self.spawnPositions = nil;
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

@implementation DynamicsSpawner

#pragma mark -
#pragma mark EnemySpawnerDelegate

- (void) initEnemySpawner:(EnemySpawner*)spawner withContextInfo:(NSMutableDictionary *)info
{
    // info from level
    NSArray* infoPosArray = [info objectForKey:@"positionsArray"];
    NSMutableArray* positionsArray = [NSMutableArray arrayWithCapacity:[infoPosArray count]];
    for(NSValue* cur in infoPosArray)
    {
        [positionsArray addObject:[NSValue valueWithCGPoint:[cur CGPointValue]]];
    }
    float layerDistance = [[info objectForKey:@"layerDistance"] floatValue];
    
    DynamicsSpawnerContext* newContext = [[DynamicsSpawnerContext alloc] initWithArray:positionsArray 
                                                                        atDistance:layerDistance
                                                                    objectTypename:[info objectForKey:@"objectType"]
                                                                        triggerContext:[info objectForKey:@"triggerContext"]];
    newContext.dynamicsShadowsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrPreDynamics"];
    newContext.dynamicsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrDynamics"];
    newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"GrPostDynamics"];
    
    newContext.groundedBucketShadows = [[info objectForKey:@"bucketShadows"] unsignedIntValue];
    newContext.groundedBucket = [[info objectForKey:@"bucket"] unsignedIntValue];
    newContext.groundedBucketAddons = [[info objectForKey:@"bucketAddons"] unsignedIntValue];
    newContext.triggerName = [info objectForKey:@"triggerName"];
    
    spawner.spawnerContext = newContext;
    [newContext release];
}

- (void) restartEnemySpawner:(EnemySpawner *)spawner
{
    DynamicsSpawnerContext* curContext = (DynamicsSpawnerContext*)spawner.spawnerContext;
    curContext.spawnedOnce = NO;
    curContext.spawnedCount = 0;
}

- (Enemy*) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    Enemy* newEnemy = nil;
    DynamicsSpawnerContext* spawnerContext = [spawner spawnerContext];
    
    // spawn once and be done
    if((![spawnerContext spawnedOnce]) && (0 == [spawner.spawnedEnemies count]))
    {
        spawnerContext.spawnedOnce = YES;
        for(NSValue* cur in spawnerContext.spawnPositions)
        {
            CGPoint initPos = [cur CGPointValue];
            TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];
            CGPoint camPos = [gameCam camPointFromWorldPoint:initPos atDistance:[spawnerContext layerDistance]];

            newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:[spawnerContext objectTypename] AtPos:camPos withSpawnerContext:spawnerContext];
            newEnemy.renderBucketIndex = [spawnerContext dynamicsBucketIndex];
            newEnemy.isGrounded = NO;
            
            // add it to spawnedEnemies
            newEnemy.mySpawner = spawner;
            [spawner.spawnedEnemies addObject:newEnemy];
            [newEnemy spawn];
            [newEnemy release];
            spawnerContext.spawnedCount++;
        }
        
        // I am done
        [spawner setActivated:NO];
    }    
    
    // this spawner spawns all enemies at once; EnemySpawner requires it to add all the enemies itself
    // and return a nil here
    return nil;
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
    
    DynamicsSpawnerContext* spawnerContext = [spawner spawnerContext];
    spawnerContext.triggerContext = context;
}

@end
