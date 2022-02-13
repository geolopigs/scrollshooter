//
//  GroundCargoSpawner.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "GroundCargoSpawner.h"
#import "EnemySpawner.h"
#import "LootFactory.h"
#import "LevelManager.h"
#import "Loot.h"
#import "LootCash.h"
#import "BoarSolo.h"
#import "RenderBucketsManager.h"

// behavior constants
static const float INITVEL_X = 0.0f;
static const float INITVEL_Y = 4.0f;
static const unsigned int FIRINGSLOT_NUM = 5;


@implementation GroundCargoSpawnerContext
@synthesize spawnPositions;
@synthesize layerDistance;
@synthesize renderBucketIndex;
@synthesize spawnedOnce;
@synthesize attachedLoots;

- (id) initWithArray:(NSArray*)positionsArray atDistance:(float)dist
{
    self = [super init];
    if(self)
    {
        self.spawnPositions = positionsArray;
        self.layerDistance = dist;
        self.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Background"];
        self.spawnedOnce = NO;
        self.attachedLoots = [NSMutableArray array];
    }
    return self;
}

- (void) dealloc
{
    // kill all outstanding loots
    for(Loot* cur in attachedLoots)
    {
        if([cur isAlive])
        {
            [cur kill];
        }
    }
    self.attachedLoots = nil;
    self.spawnPositions = nil;
    [super dealloc];
}

#pragma mark - EnemySpawnerContextDelegate
- (NSDictionary*) spawnerTriggerContext
{
    // GroundCargo does not have trigger context
    return nil;
}

- (float) spawnerLayerDistance
{
    return layerDistance;
}

@end

@implementation GroundCargoSpawner

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
    unsigned int bucketIndex = [[info objectForKey:@"bucket"] unsignedIntValue];
    float layerDistance = [[info objectForKey:@"layerDistance"] floatValue];
    
    GroundCargoSpawnerContext* newContext = [[GroundCargoSpawnerContext alloc] initWithArray:positionsArray atDistance:layerDistance];
    newContext.renderBucketIndex = bucketIndex;
    spawner.spawnerContext = newContext;
    [newContext release];
}

- (void) restartEnemySpawner:(EnemySpawner *)spawner
{
    GroundCargoSpawnerContext* curContext = (GroundCargoSpawnerContext*)spawner.spawnerContext;
    curContext.spawnedOnce = NO;
    
    // kill all outstanding loots
    for(Loot* cur in curContext.attachedLoots)
    {
        if([cur isAlive])
        {
            [cur kill];
        }
    }
    [curContext.attachedLoots removeAllObjects];
}

- (id) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    GroundCargoSpawnerContext* spawnerContext = [spawner spawnerContext];

    // spawn once and be done
    if((![spawnerContext spawnedOnce]) && (0 == [spawner.spawnedEnemies count]))
    {
        float initSwingVelFactor = 0.5f;
        float initSwingVelFactorIncr = -1.0f;
        spawnerContext.spawnedOnce = YES;
        for(NSValue* cur in spawnerContext.spawnPositions)
        {
            CGPoint initPos = [cur CGPointValue];
            Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:@"LootCash" atPos:initPos 
                                                                            isDynamics:NO 
                                                                            groundedBucketIndex:[spawnerContext renderBucketIndex] 
                                                                         layerDistance:[spawnerContext layerDistance]];
        
            LootCashContext* context = (LootCashContext*) [newLoot lootContext];
            context.swingVel *= initSwingVelFactor;
            initSwingVelFactor += initSwingVelFactorIncr;
            if(-1.0f >= initSwingVelFactor)
            {
                initSwingVelFactorIncr *= -1.0f;
            }
            
            [newLoot spawn];
            
            [spawnerContext.attachedLoots addObject:newLoot];
            [newLoot release];
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
    // do nothing
    // LootCash has a timeout after which they kill themselves
    // the only time they stay around is if the user restarts or quits in the middle of a level
    // this is handled in restartEnemySpawner and dealloc
}


- (void) activateEnemySpawner:(EnemySpawner*)spawner withTriggerContext:(NSDictionary*)context
{
    [spawner setActivated:YES];    
}

@end
