//
//  DynamicSpawner.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/9/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface DynamicsSpawnerContext : NSObject<EnemySpawnerContextDelegate> 
{
    NSArray* spawnPositions;
    float layerDistance;
    NSString* objectTypename;
    unsigned int dynamicsShadowsIndex;
    unsigned int dynamicsBucketIndex;
    unsigned int dynamicsAddonsIndex;
    unsigned int groundedBucketShadows;
    unsigned int groundedBucket;
    unsigned int groundedBucketAddons;
    BOOL spawnedOnce;
    unsigned int spawnedCount;  // can be used by spawned enemies to init behavior variation
    
    NSString* triggerName;
    NSDictionary* triggerContext;
}
@property (nonatomic,retain) NSArray* spawnPositions;
@property (nonatomic,assign) float layerDistance;
@property (nonatomic,retain) NSString* objectTypename;
@property (nonatomic,assign) unsigned int dynamicsShadowsIndex;
@property (nonatomic,assign) unsigned int dynamicsBucketIndex;
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@property (nonatomic,assign) unsigned int groundedBucketShadows;
@property (nonatomic,assign) unsigned int groundedBucket;
@property (nonatomic,assign) unsigned int groundedBucketAddons;
@property (nonatomic,assign) BOOL spawnedOnce;
@property (nonatomic,assign) unsigned int spawnedCount;
@property (nonatomic,retain) NSString* triggerName;
@property (nonatomic,retain) NSDictionary* triggerContext;

- (id) initWithArray:(NSArray*)positionsArray 
          atDistance:(float)dist 
      objectTypename:(NSString*)givenObjectTypename
      triggerContext:(NSDictionary*)triggerParms;
@end

@interface DynamicsSpawner : NSObject<EnemySpawnerDelegate>
{
    
}

@end
