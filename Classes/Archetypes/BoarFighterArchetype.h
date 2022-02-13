//
//  BoarFighterArchetype.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/31/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface BoarFighterContext : NSObject
{
    // movement
    float distTillTurn;
    float lastY;
    CGPoint finalSpeed;
    CGPoint accel;
    
    // firing
    float timeTillFire;
    unsigned int firingSlot;
}
@property (nonatomic,assign) float distTillTurn;
@property (nonatomic,assign) float lastY;
@property (nonatomic,assign) CGPoint finalSpeed;
@property (nonatomic,assign) CGPoint accel;
@property (nonatomic,assign) float timeTillFire;
@property (nonatomic,assign) unsigned int firingSlot;
@end


@interface BoarFighterArchetype : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate>

@end
