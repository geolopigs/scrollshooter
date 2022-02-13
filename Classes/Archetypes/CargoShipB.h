//
//  CargoShipB.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/10/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@class AddonData;
@interface CargoShipBContext : NSObject
{
    unsigned int dynamicsBucketIndex;       // bucket for myself
    unsigned int dynamicsShadowsIndex;      // bucket for wakes
    unsigned int dynamicsAddonsIndex;       // bucket for cargopacks
    unsigned int behaviorState;

    // timer
    float cruisingTimer;
    
    // movement behavior
    CGPoint initPos;
    float weaveVel;
    float weaveParam;
    float weaveRange;
    float weaveYVel;
    float weaveYParam;
    float weaveYRange;
    
    // cargo addons (to be killed by game event)
    NSMutableArray* cargoAddons;
    NSString* cargoReleaseTriggerName;
    
    // subcomponent placement
    AddonData* addonData;
}
@property (nonatomic,assign) unsigned int dynamicsBucketIndex;
@property (nonatomic,assign) unsigned int dynamicsShadowsIndex;
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,assign) float cruisingTimer;
@property (nonatomic,assign) CGPoint initPos;
@property (nonatomic,assign) float weaveVel;
@property (nonatomic,assign) float weaveParam;
@property (nonatomic,assign) float weaveRange;
@property (nonatomic,assign) float weaveYVel;
@property (nonatomic,assign) float weaveYParam;
@property (nonatomic,assign) float weaveYRange;
@property (nonatomic,retain) NSMutableArray* cargoAddons;
@property (nonatomic,retain) NSString* cargoReleaseTriggerName;
@property (nonatomic,retain) AddonData* addonData;
@end

@interface CargoShipB : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemyParentDelegate,EnemySpawnedDelegate>


@end
