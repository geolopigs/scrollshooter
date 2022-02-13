//
//  DuaSeatoSpawner.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface DuaSeatoSpawnerContext : NSObject<EnemySpawnerContextDelegate> 
{
    // runtme params
    float           timeTillSpawn;
    unsigned int    spawnCounter;
    
    // config params
    BOOL            useIntroPos;
    CGPoint         introPos;
    float           introDir;
    CGPoint         introVel;
    unsigned int    maxEnemiesAlive;       // max enemies alive at one time
    float           timeBetweenSpawns;
    NSArray* spawnPosArray;          // pre-set spawn positions
    NSString* triggerName;
    NSDictionary* triggerContext;

    // rendering
    unsigned int dynamicsShadowsIndex;
    unsigned int dynamicsBucketIndex;
    unsigned int dynamicsAddonsIndex;
}
@property (nonatomic,assign) float timeTillSpawn;
@property (nonatomic,assign) unsigned int spawnCounter;
@property (nonatomic,assign) BOOL useIntroPos;
@property (nonatomic,assign) CGPoint introPos;
@property (nonatomic,assign) float introDir;
@property (nonatomic,assign) CGPoint introVel;
@property (nonatomic,assign) unsigned int maxEnemiesAlive;
@property (nonatomic,assign) float timeBetweenSpawns;
@property (nonatomic,retain) NSArray* spawnPosArray;
@property (nonatomic,retain) NSString* triggerName;
@property (nonatomic,retain) NSDictionary* triggerContext;
@property (nonatomic,assign) unsigned int dynamicsShadowsIndex;
@property (nonatomic,assign) unsigned int dynamicsBucketIndex;
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@end

@interface DuaSeatoSpawner : NSObject<EnemySpawnerDelegate>
{
    
}

@end
