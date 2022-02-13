//
//  EnemySpawner.h
//  PeterPog
//
//  The EnemySpawner is responsible for spawning and retiring all enemies within a Level.
//  It is part of a level.
//
//  Created by Shu Chiun Cheah on 7/13/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class Enemy;
@interface EnemySpawner : NSObject 
{
    NSObject<EnemySpawnerDelegate>* delegate;
    NSMutableSet* spawnedEnemies;
    NSMutableSet* trashSet;
    BOOL            activated;
    BOOL            triggered;     // internal use only for hasWoundDown to determine that this
                                    // spawner has at least been triggered before it was deactivated
    unsigned int    numIncapacitated;
    unsigned int    numSpawned;
    NSMutableArray* incapsPerWave;
    
    id              spawnerContext;
    float           timeToRock;
    float           nextDirection;
    
    BOOL            _hasFinalFight;  // if TRUE, this spawner's final wave needs to be triggered explicitly
}
@property (nonatomic,retain) NSObject<EnemySpawnerDelegate>* delegate;
@property (nonatomic,retain) NSMutableSet* spawnedEnemies;
@property (nonatomic,retain) NSMutableSet* trashSet;
@property (nonatomic,assign) BOOL activated;
@property (nonatomic,assign) BOOL triggered;
@property (nonatomic,assign) unsigned int numIncapacitated;
@property (nonatomic,assign) unsigned int numSpawned;
@property (nonatomic,retain) NSMutableArray* incapsPerWave;
@property (nonatomic,retain) id spawnerContext;
@property (nonatomic,assign) BOOL hasFinalFight;

- (id) initWithDelegate:(NSObject<EnemySpawnerDelegate>*)spawnerDelegate;
- (id) initWithDelegate:(NSObject<EnemySpawnerDelegate>*)spawnerDelegate contextInfo:(NSMutableDictionary*)contextInfo;

- (void) activateWithContext:(NSDictionary*)context;
- (void) restart;
- (void) removeEnemy:(Enemy*)enemy;
- (void) update:(NSTimeInterval)elapsed;
- (void) killAllBullets;
- (void) shutdownSpawner;
- (void) triggerFinalFight;
- (void) incapThenKillAllEnemies;

// queries
- (BOOL) areAllEnemiesIncapacitated;

// for tracking incaps in spawners that generate waves of enemies
- (void) decrIncapsForWave:(unsigned int)waveIndex;
- (void) setIncapsForWave:(unsigned int)waveIndex toValue:(int)newValue;
- (unsigned int) incapsRemainingForWave:(unsigned int)waveIndex;

// GameManager needs to check this after deactivating a spawner before killing it off
- (BOOL) hasWoundDown;
- (BOOL) hasOutstandingEnemies;
@end
