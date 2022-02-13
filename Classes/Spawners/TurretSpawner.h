//
//  TurretSpawner.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface TurretSpawnerContext : NSObject<EnemySpawnerContextDelegate>
{
    NSArray* spawnPositions;
    float layerDistance;
    NSString* objectTypename;
    
    unsigned int renderBucketShadows;
    unsigned int renderBucket;
    unsigned int renderBucketAddons;
    
    BOOL spawnedOnce;
    unsigned int firingSlot;
    unsigned int spawnedCount;  // can be used by spawned enemies to init behavior variation
    
    NSDictionary* triggerContext;
}
@property (nonatomic,retain) NSArray* spawnPositions;
@property (nonatomic,assign) float layerDistance;
@property (nonatomic,retain) NSString* objectTypename;
@property (nonatomic,assign) unsigned int renderBucketShadows;
@property (nonatomic,assign) unsigned int renderBucket;
@property (nonatomic,assign) unsigned int renderBucketAddons;
@property (nonatomic,assign) BOOL spawnedOnce;
@property (nonatomic,assign) unsigned int firingSlot;
@property (nonatomic,assign) unsigned int spawnedCount;
@property (nonatomic,retain) NSDictionary* triggerContext;
- (id) initWithArray:(NSArray*)positionsArray atDistance:(float)dist objectTypename:(NSString*)givenObjectTypename;
@end

@interface TurretSpawner : NSObject<EnemySpawnerDelegate>
{
    
}

@end
