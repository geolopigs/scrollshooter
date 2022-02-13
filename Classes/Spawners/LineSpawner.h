//
//  LineSpawner.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/14/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface LineSpawnerContext : NSObject<EnemySpawnerContextDelegate> 
{
    // runtme params
    float           timeTillSpawn;
    unsigned int    spawnCounter;
    
    // config params
    CGPoint         introOffset;
    CGPoint         introPos;
    CGPoint         introVel;
    float           angularSpeed;
    float           launchDelay;
    float           launchSplit;
    float           launchSpeed;
    unsigned int    numToSpawn;
    float           timeBetweenSpawns;
    float timeBetweenShots;
    float shotSpeed;
    CGPoint introDoneBotLeft;
    CGPoint introDoneTopRight;
    NSDictionary* triggerContext;
    
    // rendering
    unsigned int dynamicsShadowsIndex;
    unsigned int dynamicsBucketIndex;
    unsigned int dynamicsAddonsIndex;
}
@property (nonatomic,assign) float timeTillSpawn;
@property (nonatomic,assign) unsigned int spawnCounter;
@property (nonatomic,assign) int curWave;
@property (nonatomic,assign) unsigned int curWaveNumToSpawn;

@property (nonatomic,assign) CGPoint introOffset;
@property (nonatomic,assign) CGPoint introPos;
@property (nonatomic,assign) CGPoint introVel;
@property (nonatomic,assign) float angularSpeed;
@property (nonatomic,assign) float launchDelay;
@property (nonatomic,assign) float launchSplit;
@property (nonatomic,assign) float launchSpeed;
@property (nonatomic,assign) unsigned int numToSpawn;
@property (nonatomic,assign) float timeBetweenSpawns;
@property (nonatomic,assign) float timeBetweenShots;
@property (nonatomic,assign) float shotSpeed;
@property (nonatomic,assign) CGPoint introDoneBotLeft;
@property (nonatomic,assign) CGPoint introDoneTopRight;
@property (nonatomic,retain) NSDictionary* triggerContext;
@property (nonatomic,assign) int numWaves;
@property (nonatomic,assign) float timeBetweenWaves;
@property (nonatomic,assign) unsigned int numProgression;   // number by which to increment numToSpawn for each wave

@property (nonatomic,assign) unsigned int dynamicsShadowsIndex;
@property (nonatomic,assign) unsigned int dynamicsBucketIndex;
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;

- (void) setupFromTriggerContext:(NSDictionary*)context;

@end



@interface LineSpawner : NSObject<EnemySpawnerDelegate>

@end
