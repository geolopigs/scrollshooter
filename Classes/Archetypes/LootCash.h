//
//  LootCash.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/5/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LootProtocols.h"
#import "CollisionProtocols.h"

@interface LootCashContext : NSObject
{
    CGPoint initPos;
    float lifeSpanRemaining;
    float swingParam;
    float swingVel;
    BOOL magnetToPlayer;
}
@property (nonatomic,assign) CGPoint initPos;
@property (nonatomic,assign) float lifeSpanRemaining;
@property (nonatomic,assign) float swingParam;
@property (nonatomic,assign) float swingVel;
@property (nonatomic,assign) BOOL magnetToPlayer;
@end

@interface LootCash : NSObject<LootInitDelegate,LootBehaviorDelegate,LootCollectedDelegate,LootCollisionResponse,lootAABBDelegate>
{
    
}

@end
