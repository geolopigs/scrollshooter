//
//  EnemySpawner.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/13/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

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

@implementation EnemySpawner
@synthesize delegate;
@synthesize spawnedEnemies;
@synthesize trashSet;
@synthesize activated;
@synthesize triggered;
@synthesize numIncapacitated;
@synthesize numSpawned;
@synthesize incapsPerWave;
@synthesize spawnerContext;
@synthesize hasFinalFight = _hasFinalFight;

- (id) initWithDelegate:(NSObject<EnemySpawnerDelegate> *)spawnerDelegate
{
    self = [super init];
    if(self)
    {
        self.delegate = spawnerDelegate;
        self.spawnedEnemies = [NSMutableSet setWithCapacity:10];
        self.trashSet = [NSMutableSet setWithCapacity:10];
        self.activated = YES;
        self.triggered = NO;
        self.numIncapacitated = 0;
        self.numSpawned = 0;
        self.incapsPerWave = [NSMutableArray array];
        self.spawnerContext = nil;
        _hasFinalFight = NO;
        
        // call type specific init from delegate
        [self.delegate initEnemySpawner:self withContextInfo:nil];
    }
    return self;
}

- (id) initWithDelegate:(NSObject<EnemySpawnerDelegate>*)spawnerDelegate contextInfo:(NSMutableDictionary*)contextInfo
{
    self = [super init];
    if(self)
    {
        self.delegate = spawnerDelegate;
        self.spawnedEnemies = [NSMutableSet setWithCapacity:10];
        self.trashSet = [NSMutableSet setWithCapacity:10];
        self.activated = YES;
        self.triggered = NO;
        self.numIncapacitated = 0;
        self.incapsPerWave = [NSMutableArray array];
        self.spawnerContext = nil;
        _hasFinalFight = NO;
        
        // call type specific init from delegate
        [self.delegate initEnemySpawner:self withContextInfo:contextInfo];
    }
    return self;    
}


- (void) dealloc
{
    self.spawnerContext = nil;
    self.incapsPerWave = nil;
    self.trashSet = nil;
    self.spawnedEnemies = nil;
    self.delegate = nil;
    [super dealloc];
}

- (void) activateWithContext:(NSDictionary *)context
{
    [delegate activateEnemySpawner:self withTriggerContext:context];
}

- (void) restart
{
    // remove all enemies
    [self shutdownSpawner];
    
    // restart delegate so that it can reset its context accordingly
    [delegate restartEnemySpawner:self];
    
    // reset number of incapacitated
    self.numIncapacitated = 0;
    self.numSpawned = 0;
    
    self.activated = YES;
    self.triggered = NO;
}

- (void) removeEnemy:(Enemy *)enemy
{
    [trashSet addObject:enemy];
}

- (void) update:(NSTimeInterval)elapsed
{
    // call delegate update
    if(self.activated)
    {
        Enemy* newEnemy = [self.delegate updateEnemySpawner:self elapsed:elapsed];
        if(newEnemy)
        {
            [spawnedEnemies addObject:newEnemy];
            newEnemy.mySpawner = self;
            [newEnemy spawn];
            [newEnemy release];
            ++numSpawned;
        }
        else
        {
            // if delegate returns nil, then it has generated multiple enemies in one shot and has taken care of adding
            // the enemies to spawnedEnemies itself
            // so, spawnedEnemies count at this point is the total number of enemies spawned
            if(numSpawned < [spawnedEnemies count])
            {
                numSpawned = [spawnedEnemies count];
            }
        }
    }
    
    // garbage collect
    [self.delegate retireEnemies:self elapsed:elapsed];
    if([trashSet count])
    {
        for(id cur in trashSet)
        {
            [spawnedEnemies removeObject:cur];
        }
        [trashSet removeAllObjects];
    }
}

- (BOOL) hasWoundDown
{
    BOOL result = (![self activated] && 
                   [self triggered] && 
                   ((0 == [spawnedEnemies count]) || (numIncapacitated == numSpawned)) && 
                   (0 == [trashSet count]));
    return result;
}

- (BOOL) hasOutstandingEnemies
{
    BOOL result = (0 < [spawnedEnemies count]);
    return result;
}

- (void) killAllBullets
{
    for(Enemy* cur in spawnedEnemies)
    {
        [cur killAllBullets];
    }
}

- (void) incapThenKillAllEnemies
{
    for(Enemy* cur in spawnedEnemies)
    {
        [cur incapThenKillWithPoints:NO];
    }    
}

- (void) shutdownSpawner
{
    for(Enemy* cur in spawnedEnemies)
    {
        // unset the spawner field so that the enemy doesn't try to remove itself from the spawner in this loop
        cur.mySpawner = nil;
        [cur kill];
    }
    [trashSet removeAllObjects];
    [spawnedEnemies removeAllObjects];
    [incapsPerWave removeAllObjects];
}

- (void) triggerFinalFight
{
    _hasFinalFight = NO;
}

- (BOOL) areAllEnemiesIncapacitated
{
    BOOL result = YES;
    for(Enemy* cur in spawnedEnemies)
    {
        if(![cur incapacitated])
        {
            result = NO;
            break;
        }
    }
    return result;
}

- (void) decrIncapsForWave:(unsigned int)waveIndex
{
    if(waveIndex < [incapsPerWave count])
    {
        unsigned int cur = [[incapsPerWave objectAtIndex:waveIndex] unsignedIntValue];
        if(0 < cur)
        {
            --cur;
        }
        [incapsPerWave replaceObjectAtIndex:waveIndex withObject:[NSNumber numberWithUnsignedInt:cur]];
    }
}

- (void) setIncapsForWave:(unsigned int)waveIndex toValue:(int)newValue
{
    if(waveIndex < [incapsPerWave count])
    {
        [incapsPerWave replaceObjectAtIndex:waveIndex withObject:[NSNumber numberWithInt:newValue]];
    }
}

- (unsigned int) incapsRemainingForWave:(unsigned int)waveIndex
{
    unsigned int result = 0;
    if(waveIndex < [incapsPerWave count])
    {
        result = [[incapsPerWave objectAtIndex:waveIndex] unsignedIntValue];
    }
    return result;
}

@end
