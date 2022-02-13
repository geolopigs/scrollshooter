//
//  SubSpawner.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/14/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class Addon;
@interface SubSpawnerContext : NSObject<EnemySpawnerContextDelegate>
{
    // configs
    NSDictionary* _triggerContext;
    NSString* _groupName;
    
    // runtime
}
// configs
@property (nonatomic,retain) NSMutableArray* spawnPoints;
@property (nonatomic,retain) Addon* spawnAnim;
@property (nonatomic,retain) Enemy* parent;
@property (nonatomic,retain) NSDictionary* triggerContext;
@property (nonatomic,retain) NSString* groupName;
@property (nonatomic,assign) float spawnDelay;
@property (nonatomic,assign) float hiddenDelayForSpawnEffect;
@property (nonatomic,assign) BOOL isBossGroup;        // if TRUE, the last wave is the final fight

// runtime
@property (nonatomic,assign) unsigned int state;
@property (nonatomic,assign) unsigned int nextWave;
@property (nonatomic,assign) float spawnTimer;

- (void) setupFromTriggerContext:(NSDictionary*)context;
- (unsigned int) getNumWaves;
- (BOOL) isSpawnerDestroyed;
- (BOOL) hasSpawnedFinalWave;
@end

@interface SubSpawner : NSObject<EnemySpawnerDelegate>
+ (BOOL) areConditionsMetForNextWaveForSpawner:(EnemySpawner*)spawner;
+ (BOOL) isClearToMoveOutOfCurrentWave:(EnemySpawner*)spawner;
@end