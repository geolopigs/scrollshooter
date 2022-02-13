//
//  DynLineSpawner.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/14/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface DynLineSpawnerContext : NSObject<EnemySpawnerContextDelegate> 
{
    // runtme params
    float           timeTillSpawn;
    unsigned int    spawnCounter;
    
    // config params
    CGPoint         introOffset;
    CGPoint         introPos;
    BOOL            _isInfiniteSpawn;
    unsigned int    numToSpawn;
    float           timeBetweenSpawns;
    NSString* enemyTypeName;
    NSString* triggerName;
    NSDictionary* triggerContext;
}
@property (nonatomic,assign) float timeTillSpawn;
@property (nonatomic,assign) unsigned int spawnCounter;
@property (nonatomic,assign) CGPoint introOffset;
@property (nonatomic,assign) CGPoint introPos;
@property (nonatomic,assign) BOOL isInfiniteSpawn;
@property (nonatomic,assign) unsigned int numToSpawn;
@property (nonatomic,assign) float timeBetweenSpawns;
@property (nonatomic,retain) NSString* enemyTypeName;
@property (nonatomic,retain) NSString* triggerName;
@property (nonatomic,retain) NSDictionary* triggerContext;
@end



@interface DynLineSpawner : NSObject<EnemySpawnerDelegate>

@end
