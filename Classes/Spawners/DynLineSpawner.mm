//
//  DynLineSpawner.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/14/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "DynLineSpawner.h"
#import "RenderBucketsManager.h"
#import "EnemySpawner.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "GameManager.h"

@implementation DynLineSpawnerContext
@synthesize timeTillSpawn;
@synthesize spawnCounter;
@synthesize introOffset;
@synthesize introPos;
@synthesize isInfiniteSpawn = _isInfiniteSpawn;
@synthesize numToSpawn;
@synthesize timeBetweenSpawns;
@synthesize enemyTypeName;
@synthesize triggerName;
@synthesize triggerContext;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.enemyTypeName = nil;
        self.triggerName = nil;
        self.triggerContext = nil;
        
        _isInfiniteSpawn = NO;
        timeTillSpawn = 0.0f;
        spawnCounter = 0;
    }
    return self;
}

- (void) dealloc
{
    self.triggerContext = nil;
    self.triggerName = nil;
    self.enemyTypeName = nil;
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

@implementation DynLineSpawner
#pragma mark -
#pragma mark EnemySpawnerDelegate

- (void) initEnemySpawner:(EnemySpawner*)spawner withContextInfo:(NSMutableDictionary *)info
{
    DynLineSpawnerContext* newContext = [[DynLineSpawnerContext alloc] init];
    spawner.spawnerContext = newContext;
    [newContext release];
}

- (void) restartEnemySpawner:(EnemySpawner *)spawner
{
    DynLineSpawnerContext* spawnerContext = [spawner spawnerContext];
    spawnerContext.timeTillSpawn = 0.0f;
    spawnerContext.spawnCounter = 0;
}

- (Enemy*) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    Enemy* newEnemy = nil;
    DynLineSpawnerContext* spawnerContext = [spawner spawnerContext];
    
    BOOL doSpawn = NO;
    if([spawnerContext isInfiniteSpawn])
    {
        doSpawn = ([spawnerContext numToSpawn] > [spawner.spawnedEnemies count]);
        
        // if infiniteSpawn, wrap counter back to 0 so that spawnPos does not go off screen
        if([spawnerContext spawnCounter] >= [spawnerContext numToSpawn])
        {
            spawnerContext.spawnCounter = 0;
        }        
    }
    else
    {
        doSpawn = ([spawnerContext numToSpawn] > [spawnerContext spawnCounter]);
    }

    // spawn one at a time
    if(doSpawn)
    {
        CGPoint spawnPos = [spawnerContext introPos];
        spawnPos.x += ([spawnerContext introOffset].x * [spawnerContext spawnCounter]);
        spawnPos.y += ([spawnerContext introOffset].y * [spawnerContext spawnCounter]);
        spawnerContext.timeTillSpawn -= elapsed;
        if(0.0f >= spawnerContext.timeTillSpawn)
        {
            newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:[spawnerContext enemyTypeName] 
                                                                AtPos:spawnPos
                                                   withSpawnerContext:spawnerContext];
                            
            spawnerContext.timeTillSpawn = spawnerContext.timeBetweenSpawns;
            spawnerContext.spawnCounter++;
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
    DynLineSpawnerContext * spawnerContext = [spawner spawnerContext];
    spawnerContext.triggerContext = context;
    if(context)
    {
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        float introPosX = [[context objectForKey:@"introPosX"] floatValue] * playArea.size.width;
        float introPosY = [[context objectForKey:@"introPosY"] floatValue] * playArea.size.height;
        unsigned int numToSpawn = [[context objectForKey:@"numToSpawn"] unsignedIntValue];
        float timeBetweenSpawns = [[context objectForKey:@"timeBetweenSpawns"] floatValue];

        // when maxAlive is specified, it overrides numToSpawn
        NSNumber* maxAliveNumber = [context objectForKey:@"maxAlive"];
        if(maxAliveNumber)
        {
            numToSpawn = [maxAliveNumber unsignedIntValue];
            spawnerContext.isInfiniteSpawn = YES;
        }
        else
        {
            spawnerContext.isInfiniteSpawn = NO;
        }

        spawnerContext.introPos = CGPointMake(introPosX, introPosY);
        spawnerContext.numToSpawn = numToSpawn;
        spawnerContext.timeBetweenSpawns = timeBetweenSpawns;
        spawnerContext.enemyTypeName = [context objectForKey:@"typename"];

        NSNumber* introOffsetX = [context objectForKey:@"introOffsetX"];
        NSNumber* introOffsetY = [context objectForKey:@"introOffsetY"];
        if(introOffsetX && introOffsetY)
        {
            spawnerContext.introOffset = CGPointMake([introOffsetX floatValue] * playArea.size.width, 
                                                     [introOffsetY floatValue] * playArea.size.height);
        }
        else
        {
            spawnerContext.introOffset = CGPointMake(0.0f, 0.0f);
        }
        
    }
    
    // restart enemy spawner
    [self restartEnemySpawner:spawner];
}

@end
