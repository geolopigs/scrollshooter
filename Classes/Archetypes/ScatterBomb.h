//
//  ScatterBomb.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class BossWeapon;
@interface ScatterBombContext : NSObject
{
    // config params
    unsigned int numShotsPerRound;
    CGPoint initVel;
    
    // runtime params
    BossWeapon* scatterWeapon;
    unsigned int shotCount;
}
@property (nonatomic,assign) unsigned int numShotsPerRound;
@property (nonatomic,assign) CGPoint initVel;

@property (nonatomic,retain) BossWeapon* scatterWeapon;
@property (nonatomic,assign) unsigned int shotCount;

- (void) setupFromTriggerContext:(NSDictionary*)triggerContext;
@end

@interface ScatterBomb : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemySpawnedDelegate>
{
    NSString* animName;
    NSString* explosionName;
}
@property (nonatomic,retain) NSString* animName;
@property (nonatomic,retain) NSString* explosionName;
- (id) initWithAnimNamed:(NSString*)name explosionNamed:(NSString*)expName;
@end
