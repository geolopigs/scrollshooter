//
//  SubSpawner.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/14/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "SubSpawner.h"
#import "Enemy.h"
#import "EnemySpawner.h"
#import "EnemyFactory.h"
#import "Addon.h"
#import "AnimClip.h"
#include "MathUtils.h"

#import "Boss2.h"
#import "BoarSolo.h"

enum SUBSPAWNER_STATE
{
    SUBSPAWNER_STATE_INTRO = 0,
    SUBSPAWNER_STATE_IDLE,
    SUBSPAWNER_STATE_SPAWN,
    SUBSPAWNER_STATE_OUTRO,
    SUBSPAWNER_STATE_DESTROYED,
    
    SUBSPAWNER_STATE_NUM
};

static const unsigned int SUBSPAWNER_FLAG_NONE = 0x00;
static const unsigned int SUBSPAWNER_FLAG_CONTINUESPAWN = 0x01; // continue to spawn next wave, no need to wait for incap per wave;
static const unsigned int SUBSPAWNER_FLAG_MUSTINCAP = 0x02; // must incap this enemy before Spawner can proceed to DESTROYED

@interface SubSpawnerContext (PrivateMethods)
- (NSString*) getEnemyTypeForWave:(unsigned int)waveIndex spawnPoint:(unsigned int)pointIndex;
- (NSDictionary*) getEnemyConfigForWave:(unsigned int)waveIndex spawnPoint:(unsigned int)pointIndex;
- (unsigned int) getNumConfigsForWave:(unsigned int)waveIndex;
@end

@implementation SubSpawnerContext
// configs
@synthesize spawnPoints = _spawnPoints;
@synthesize spawnAnim = _spawnAnim;
@synthesize parent = _parent; 
@synthesize triggerContext = _triggerContext;
@synthesize groupName = _groupName;
@synthesize spawnDelay = _spawnDelay;
@synthesize hiddenDelayForSpawnEffect = _hiddenDelayForSpawnEffect;
@synthesize isBossGroup = _isBossGroup;

// runtime
@synthesize state = _state;
@synthesize nextWave = _nextWave;
@synthesize spawnTimer = _spawnTimer;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.spawnPoints = [NSMutableArray array];
        self.spawnAnim = nil;
        self.parent = nil;
        self.triggerContext = nil;
        self.groupName = nil;
        _spawnDelay = 0.5f;
        _hiddenDelayForSpawnEffect = 0.0f;
        _isBossGroup = NO;
        
        _state = SUBSPAWNER_STATE_INTRO;
        _nextWave = 0;
        _spawnTimer = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    self.groupName = nil;
    self.triggerContext = nil;
    self.parent = nil;
    self.spawnAnim = nil;
    self.spawnPoints = nil;
    [super dealloc];
}

- (void) setupFromTriggerContext:(NSDictionary *)context
{
    self.triggerContext = context;
    
    NSNumber* configSpawnDelay = [context objectForKey:@"spawnDelay"];
    if(configSpawnDelay)
    {
        self.spawnDelay = [configSpawnDelay floatValue];
    }
    
    NSNumber* configHiddenDelay = [context objectForKey:@"hiddenDelay"];
    if(configHiddenDelay)
    {
        self.hiddenDelayForSpawnEffect = [configHiddenDelay floatValue];
    }
    
    NSNumber* configIsBossGroup = [context objectForKey:@"bossGroup"];
    if(configIsBossGroup)
    {
        self.isBossGroup = [configIsBossGroup boolValue];
    }
}

- (BOOL) isSpawnerDestroyed
{
    BOOL result = (_state == SUBSPAWNER_STATE_DESTROYED);
    return result;
}

- (BOOL) hasSpawnedFinalWave
{
    BOOL result = (_nextWave >= [self getNumWaves]);
    return result;
}

#pragma mark - private methods
- (NSString*) getEnemyTypeForWave:(unsigned int)waveIndex spawnPoint:(unsigned int)pointIndex
{
    NSString* result = nil;
    NSArray* wavesArray = [[self triggerContext] objectForKey:@"waves"];
    if(waveIndex < [wavesArray count])
    {
        NSArray* curWaveArray = [wavesArray objectAtIndex:waveIndex];
        assert(pointIndex < [curWaveArray count]);
        NSDictionary* curWaveEntry = [curWaveArray objectAtIndex:pointIndex];
        result = [curWaveEntry objectForKey:@"type"];
    }
    return result;
}

- (NSDictionary*) getEnemyConfigForWave:(unsigned int)waveIndex spawnPoint:(unsigned int)pointIndex
{
    NSDictionary* result = nil;
    NSArray* wavesArray = [[self triggerContext] objectForKey:@"waves"];
    if(waveIndex < [wavesArray count])
    {
        NSArray* curWaveArray = [wavesArray objectAtIndex:waveIndex];
        assert(pointIndex < [curWaveArray count]);
        NSDictionary* curWaveEntry = [curWaveArray objectAtIndex:pointIndex];
        result = [curWaveEntry objectForKey:@"config"];
    }
    return result;    
}

- (unsigned int) getNumWaves
{
    unsigned int result = [[_triggerContext objectForKey:@"waves"] count];
    return result;
}

- (unsigned int) getNumConfigsForWave:(unsigned int)waveIndex
{
    unsigned int result = 0;
    NSArray* wavesArray = [[self triggerContext] objectForKey:@"waves"];
    if(waveIndex < [wavesArray count])
    {
        NSArray* curWaveArray = [wavesArray objectAtIndex:waveIndex];
        result = [curWaveArray count];
    }    
    return result;
}

#pragma mark - EnemySpawnerContextDelegate
- (NSDictionary*) spawnerTriggerContext
{
    NSDictionary* result = _triggerContext;
    return result;
}

- (float) spawnerLayerDistance
{
    return 100.0f;
}


@end

@interface SubSpawner (PrivateMethods) 
- (void) spawner:(EnemySpawner*)spawner spawnWave:(unsigned int)waveIndex;
- (Enemy*) spawner:(EnemySpawner*)spawner createEnemyType:(NSString*)enemyType atPos:(CGPoint)pos withConfig:(NSDictionary*)config;
- (void) setReadyToFireForEnemiesInSpawner:(EnemySpawner*)spawner;
+ (BOOL) canProceedToDestroyed:(EnemySpawner*)spawner;
@end

@implementation SubSpawner

#pragma mark - private methods
- (void) spawner:(EnemySpawner*)spawner spawnWave:(unsigned int)waveIndex
{
    SubSpawnerContext * spawnerContext = [spawner spawnerContext];
    if(waveIndex < [spawnerContext getNumWaves])
    {        
        // kill any incapacitated enemies leftover from previous wave
        for(Enemy* cur in [spawner spawnedEnemies])
        {
            if([cur incapacitated])
            {
                [cur kill];
            }
        }
        
        unsigned int pointIndex = 0;
        unsigned int numConfigs = [spawnerContext getNumConfigsForWave:waveIndex];
        for(NSValue* cur in [spawnerContext spawnPoints])
        {
            if(pointIndex < numConfigs)
            {
                NSString* enemyType = [spawnerContext getEnemyTypeForWave:waveIndex spawnPoint:pointIndex];
                NSDictionary* enemyConfig = [spawnerContext getEnemyConfigForWave:waveIndex spawnPoint:pointIndex];
                [self spawner:spawner createEnemyType:enemyType atPos:[cur CGPointValue] withConfig:enemyConfig];
            }
            else
            {
                break;
            }
            ++pointIndex;
        }
        spawnerContext.nextWave = waveIndex + 1;
    }
}


- (void) setReadyToFireForEnemiesInSpawner:(EnemySpawner*)spawner
{
    for(Enemy* cur in [spawner spawnedEnemies])
    {
        if(![cur incapacitated])
        {
            cur.readyToFire = YES;
        }
    }
}

- (Enemy*) spawner:(EnemySpawner*)spawner createEnemyType:(NSString*)enemyType atPos:(CGPoint)pos withConfig:(NSDictionary*)config
{
    SubSpawnerContext* myContext = [spawner spawnerContext];
    Enemy* parent = [myContext parent];
    Boss2Context* parentContext = [parent behaviorContext];
    Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:enemyType AtPos:pos withSpawnerContext:nil];
    newEnemy.renderBucketIndex = [parentContext dynamicsAddonsIndex];
    newEnemy.parentEnemy = parent;
    
    // context
    NSObject<EnemyBehaviorContext>* newContext = (NSObject<EnemyBehaviorContext>*)[newEnemy behaviorContext];
    [newContext setupFromConfig:config];
    
    // HACK - BoarSolo has a gun component
    if([enemyType isEqualToString:@"BoarSoloGun"])
    {
        [BoarSolo enemy:newEnemy createGunAddonInBucket:[parentContext dynamicsAddonsIndex]];
    }
    // HACK
    
    // set SubSpawner specific flags
    unsigned int flags = [newContext getFlags];
    NSNumber* configContinueSpawn = [config objectForKey:@"continueSpawn"];
    if(configContinueSpawn)
    {
        if([configContinueSpawn boolValue])
        {
            flags |= SUBSPAWNER_FLAG_CONTINUESPAWN;
        }
    }
    NSNumber* configMustIncap = [config objectForKey:@"mustIncap"];
    if(configMustIncap)
    {
        if([configMustIncap boolValue])
        {
            flags |= SUBSPAWNER_FLAG_MUSTINCAP;
        }
    }
    [newContext setFlags:flags];

    // init health (TODO: move all the enemy health inits into preSpawn)
    newEnemy.health = [newContext getInitHealth];
    
    // spawn it
    newEnemy.mySpawner = spawner;
    [spawner.spawnedEnemies addObject:newEnemy];
    [newEnemy spawn];

    // post spawn stuff
    // not ready to fire and hidden until spawn effect is done playing
    newEnemy.readyToFire = NO;
    newEnemy.hiddenTimer = [myContext hiddenDelayForSpawnEffect];
    
    [newEnemy release];

    return newEnemy;
}

+ (BOOL) areConditionsMetForNextWaveForSpawner:(EnemySpawner *)spawner
{
    BOOL result = YES;
    result = [SubSpawner isClearToMoveOutOfCurrentWave:spawner];
    if(result && [spawner hasFinalFight])
    {
        SubSpawnerContext* spawnerContext = [spawner spawnerContext];
        // this spawner is part of a FinalFight, block until FinalFight has been triggered
        if(([spawnerContext nextWave]+1) == [spawnerContext getNumWaves])
        {
            result = NO;
        }
    }
    
    return result;
}

+ (BOOL) isClearToMoveOutOfCurrentWave:(EnemySpawner *)spawner
{
    BOOL result = YES;
    for(Enemy* cur in [spawner spawnedEnemies])
    {
        NSObject<EnemyBehaviorContext>* myContext = [cur behaviorContext];
        if(!(SUBSPAWNER_FLAG_CONTINUESPAWN & [myContext getFlags]))
        {
            if(![cur incapacitated])
            {
                result = NO;
                break;
            }
        }
    }
    
    return result;
}

// call after areConditionsMetForNextWaveForSpawner to determine whether the spawner can become Destroyed
+ (BOOL) canProceedToDestroyed:(EnemySpawner *)spawner
{
    BOOL result = YES;
    for(Enemy* cur in [spawner spawnedEnemies])
    {
        NSObject<EnemyBehaviorContext>* myContext = [cur behaviorContext];
        unsigned int flags = [myContext getFlags];
        if((SUBSPAWNER_FLAG_MUSTINCAP | SUBSPAWNER_FLAG_CONTINUESPAWN) & flags)
        {
            if(![cur incapacitated])
            {
                result = NO;
                break;
            }
        }
        else if(SUBSPAWNER_FLAG_CONTINUESPAWN & flags)
        {
            // this enemy does not block the procession to DESTROYED
        }
        else if(![cur incapacitated])
        {
            result = NO;
            break;
        }
    }
    return result;
}

#pragma mark - EnemySpawnerDelegate

- (void) initEnemySpawner:(EnemySpawner*)spawner withContextInfo:(NSMutableDictionary *)info
{
    SubSpawnerContext* newContext = [[SubSpawnerContext alloc] init];
    spawner.spawnerContext = newContext;
    [newContext release];
}

- (void) restartEnemySpawner:(EnemySpawner *)spawner
{
 //   SubSpawnerContext* spawnerContext = [spawner spawnerContext];
}

- (Enemy*) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    Enemy* newEnemy = nil;
    SubSpawnerContext* spawnerContext = [spawner spawnerContext];
    
    if(SUBSPAWNER_STATE_OUTRO == [spawnerContext state])
    {
        spawnerContext.spawnTimer -= elapsed;
        if((![spawnerContext spawnAnim]) || ([spawnerContext.spawnAnim.anim playbackState] == ANIMCLIP_STATE_DONE))
        {
            // go to spawn
            if(0.0f >= [spawnerContext spawnTimer])
            {
                //NSLog(@"Group %@; %@", [spawnerContext groupName], spawnerContext);
                //NSLog(@"Goto SPAWN");
                spawnerContext.state = SUBSPAWNER_STATE_SPAWN; 
            }
        }
    }
    else if(SUBSPAWNER_STATE_SPAWN == [spawnerContext state])
    {
        unsigned int nextWave = [spawnerContext nextWave];
        assert(nextWave < [spawnerContext getNumWaves]);
        [self spawner:spawner spawnWave:nextWave];
        //NSLog(@"Group %@", [spawnerContext groupName]);
        //NSLog(@"Spawned wave %d; nextWave %d", nextWave, [spawnerContext nextWave]);
        
        // show spawn effect (no need to spawn it again it has not been killed)
        if([spawnerContext spawnAnim])
        {
            [spawnerContext.spawnAnim.anim playClipForward:YES];
        }
        
        spawnerContext.state = SUBSPAWNER_STATE_INTRO;            
    }
    else if(SUBSPAWNER_STATE_INTRO == [spawnerContext state])
    {
        if((![spawnerContext spawnAnim]) || ([spawnerContext.spawnAnim.anim playbackState] == ANIMCLIP_STATE_DONE))
        {
            // tell everyone to be ready to fire
            [self setReadyToFireForEnemiesInSpawner:spawner];
            
            spawnerContext.state = SUBSPAWNER_STATE_IDLE;
            //NSLog(@"Group %@", [spawnerContext groupName]);
            //NSLog(@"Goto IDLE");
        }
    }
    else if(SUBSPAWNER_STATE_IDLE == [spawnerContext state])
    {
        if([SubSpawner areConditionsMetForNextWaveForSpawner:spawner])
        {
            // all enemies incapacitated, move on to the next wave
            if([spawnerContext nextWave] < [spawnerContext getNumWaves])
            {
                spawnerContext.spawnTimer = [spawnerContext spawnDelay];
                if([spawnerContext spawnAnim])
                {
                    // play spawn effect backward
                    [spawnerContext.spawnAnim.anim playClipForward:NO];
                }
                spawnerContext.state = SUBSPAWNER_STATE_OUTRO;
                //NSLog(@"Group %@", [spawnerContext groupName]);
                //NSLog(@"Goto OUTRO");
            }
            else if([SubSpawner canProceedToDestroyed:spawner])
            {
                spawnerContext.state = SUBSPAWNER_STATE_DESTROYED;
                //NSLog(@"Group %@", [spawnerContext groupName]);
                //NSLog(@"Goto DESTROYED");
            }
        }
    }
    else
    {
        // destroyed
        assert(SUBSPAWNER_STATE_DESTROYED == [spawnerContext state]);
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
    SubSpawnerContext * spawnerContext = [spawner spawnerContext];
    
    // start with an OUTRO state to complete the outro->intro->spawn->outro->intro etc. sequence
    spawnerContext.state = SUBSPAWNER_STATE_OUTRO;
    
    // show spawn effect
    if([spawnerContext spawnAnim])
    {
        // play it backward as outro
        [spawnerContext.spawnAnim.anim playClipForward:NO];
        [spawnerContext.spawnAnim spawnOnParent:[spawnerContext parent]];
        [spawnerContext.parent.effectAddons addObject:[spawnerContext spawnAnim]];
    }
    
    // nextWave is 0
    spawnerContext.nextWave = 0;
    
    //NSLog(@"Activate %@ to OUTRO, nextWave %d", [spawnerContext groupName], [spawnerContext nextWave]);
}


@end
