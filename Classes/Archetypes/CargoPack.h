//
//  CargoPack.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/12/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LootProtocols.h"
#import "CollisionProtocols.h"

@interface CargoPackContext : NSObject
{
    CGPoint initPos;
    float lifeSpanRemaining;
    float swingParam;
    float swingVel;
    BOOL willRelease;
    BOOL magnetToPlayer;
}
@property (nonatomic,assign) CGPoint initPos;
@property (nonatomic,assign) float lifeSpanRemaining;
@property (nonatomic,assign) float swingParam;
@property (nonatomic,assign) float swingVel;
@property (nonatomic,assign) BOOL willRelease;
@property (nonatomic,assign) BOOL magnetToPlayer;
@end

@interface CargoPack : NSObject<LootInitDelegate,LootBehaviorDelegate,LootCollectedDelegate,LootCollisionResponse,lootAABBDelegate>
{
    
}

@end
