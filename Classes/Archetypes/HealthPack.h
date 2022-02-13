//
//  HealthPack.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/8/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import "LootProtocols.h"
#import "CollisionProtocols.h"

@interface HealthPackContext : NSObject
{
    CGPoint initPos;
    float lifeSpanRemaining;
    float swingParam;
    float swingVel;
}
@property (nonatomic,assign) CGPoint initPos;
@property (nonatomic,assign) float lifeSpanRemaining;
@property (nonatomic,assign) float swingParam;
@property (nonatomic,assign) float swingVel;
@end

@interface HealthPack : NSObject<LootInitDelegate,LootBehaviorDelegate,LootCollectedDelegate,LootCollisionResponse,lootAABBDelegate>
{
    
}

@end
