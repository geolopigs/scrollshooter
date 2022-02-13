//
//  CargoBoat.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class AddonData;
@interface CargoBoatContext : NSObject
{
    float layerDistance;
    NSMutableArray* attachedEnemies;
    AddonData* addonData;
    unsigned int renderBucket;
    unsigned int renderBucketAddons;
    unsigned int renderBucketAddons2;
    float stopAndGoPoint;
    float stopAndGoTimer;
    unsigned int behaviorState;
    float leftEnd;
    float rightEnd;
}
@property (nonatomic,assign) float  layerDistance;
@property (nonatomic,retain) NSMutableArray* attachedEnemies;
@property (nonatomic,retain) AddonData* addonData;
@property (nonatomic,assign) unsigned int renderBucket;
@property (nonatomic,assign) unsigned int renderBucketAddons;
@property (nonatomic,assign) unsigned int renderBucketAddons2;
@property (nonatomic,assign) float stopAndGoPoint;
@property (nonatomic,assign) float stopAndGoTimer;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,assign) float leftEnd;
@property (nonatomic,assign) float rightEnd;
@end

@interface CargoBoat : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemyParentDelegate,EnemySpawnedDelegate>

@end
