//
//  TurretSpawner.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "TurretSpawner.h"
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
static const unsigned int FIRINGSLOT_NUM = 5;


@implementation TurretSpawnerContext
@synthesize spawnPositions;
@synthesize layerDistance;
@synthesize objectTypename;
@synthesize renderBucketShadows;
@synthesize renderBucket;
@synthesize renderBucketAddons;
@synthesize spawnedOnce;
@synthesize firingSlot;
@synthesize spawnedCount;
@synthesize triggerContext;

- (id) initWithArray:(NSArray*)positionsArray atDistance:(float)dist objectTypename:(NSString *)givenObjectTypename
{
    self = [super init];
    if(self)
    {
        self.spawnPositions = positionsArray;
        self.layerDistance = dist;
        self.objectTypename = [NSString stringWithString:givenObjectTypename];
        
        self.renderBucketShadows = 0;
        self.renderBucket = 0;
        self.renderBucketAddons = 0;
        
        self.spawnedOnce = NO;
        self.firingSlot = 0;
        self.spawnedCount = 0;
        self.triggerContext = nil;
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
    return layerDistance;
}

@end

@implementation TurretSpawner

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
    
    TurretSpawnerContext* newContext = [[TurretSpawnerContext alloc] initWithArray:positionsArray 
                                                                        atDistance:layerDistance
                                                                    objectTypename:[info objectForKey:@"objectType"]];
    newContext.renderBucketShadows = [[info objectForKey:@"bucketShadows"] unsignedIntValue];
    newContext.renderBucket = [[info objectForKey:@"bucket"] unsignedIntValue];
    newContext.renderBucketAddons = [[info objectForKey:@"bucketAddons"] unsignedIntValue];
    
    spawner.spawnerContext = newContext;
    [newContext release];
}

- (void) restartEnemySpawner:(EnemySpawner *)spawner
{
    TurretSpawnerContext* curContext = (TurretSpawnerContext*)spawner.spawnerContext;
    curContext.spawnedOnce = NO;
}

- (Enemy*) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    Enemy* newEnemy = nil;
    TurretSpawnerContext* spawnerContext = [spawner spawnerContext];

    // spawn once and be done
    if((![spawnerContext spawnedOnce]) && (0 == [spawner.spawnedEnemies count]))
    {
        spawnerContext.firingSlot = 0;
        spawnerContext.spawnedOnce = YES;
        for(NSValue* cur in spawnerContext.spawnPositions)
        {
            CGPoint initPos = [cur CGPointValue];
            newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:[spawnerContext objectTypename] AtPos:initPos withSpawnerContext:spawnerContext];
            newEnemy.renderBucketIndex = spawnerContext.renderBucket;
            newEnemy.isGrounded = YES;

            // add it to spawnedEnemies
            newEnemy.mySpawner = spawner;
            [spawner.spawnedEnemies addObject:newEnemy];
            [newEnemy spawn];
            [newEnemy release];
            
            spawnerContext.firingSlot = (spawnerContext.firingSlot + 1) % FIRINGSLOT_NUM;
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
    TopCam* gameCam = [[[LevelManager getInstance] curLevel] gameCamera];

    for(Enemy* cur in spawner.spawnedEnemies)
    {
        if([cur willRetire])
        {
            [cur kill];
        }
        else
        {
            BoarSoloContext* myContext = [cur behaviorContext];
            CGPoint enemyCamPos = [cur pos];
            if([cur shouldAddToRenderBucketLayer])
            {
                // if in a layer, transform pos to cam space first
                enemyCamPos = [gameCam camPointFromWorldPoint:[cur pos] atDistance:[myContext layerDistance]];
            }
            // HACK - magic number 10.0f assumes BoarSolo is 20x20 render dimensions
            if(-10.0f >= enemyCamPos.y)
            {
                [cur kill];
            }
        }
    }
}

- (void) activateEnemySpawner:(EnemySpawner*)spawner withTriggerContext:(NSDictionary*)context
{
    TurretSpawnerContext* curContext = (TurretSpawnerContext*)spawner.spawnerContext;
    curContext.triggerContext = context;
    [spawner setActivated:YES];    
}


@end
