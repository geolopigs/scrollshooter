//
//  BossSpawner.h
//  PeterPog
//
//  Generic Boss spawner
//
//  Created by Shu Chiun Cheah on 9/22/2011.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface BossSpawnerContext : NSObject<EnemySpawnerContextDelegate> 
{
    // runtime params
    float           timeTillSpawn;

    // config params
    NSDictionary* triggerContext;
    CGPoint introPos;
    NSString* enemyTypeName;
    
    // rendering
    unsigned int dynamicsShadowsIndex;
    unsigned int dynamicsBucketIndex;
    unsigned int dynamicsAddonsIndex;
}
@property (nonatomic,assign) float timeTillSpawn;
@property (nonatomic,retain) NSDictionary* triggerContext;
@property (nonatomic,assign) CGPoint introPos;
@property (nonatomic,retain) NSString* enemyTypeName;
@property (nonatomic,assign) unsigned int dynamicsShadowsIndex;
@property (nonatomic,assign) unsigned int dynamicsBucketIndex;
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@end

@interface BossSpawner : NSObject<EnemySpawnerDelegate>
{
    
}

@end
