//
//  GroundCargoSpawner.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface GroundCargoSpawnerContext : NSObject<EnemySpawnerContextDelegate>
{
    NSArray* spawnPositions;
    float layerDistance;
    unsigned int renderBucketIndex;
    BOOL spawnedOnce;
    
    NSMutableArray* attachedLoots;
}
@property (nonatomic,retain) NSArray* spawnPositions;
@property (nonatomic,assign) float layerDistance;
@property (nonatomic,assign) unsigned int renderBucketIndex;
@property (nonatomic,assign) BOOL spawnedOnce;
@property (nonatomic,retain) NSMutableArray* attachedLoots;
- (id) initWithArray:(NSArray*)positionsArray atDistance:(float)dist;
@end

@interface GroundCargoSpawner : NSObject<EnemySpawnerDelegate>
{
    
}

@end
