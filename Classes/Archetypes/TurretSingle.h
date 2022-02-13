//
//  TurretSingle.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface TurretSingleContext : NSObject
{
    float timeTillFire;
    unsigned int shotsFired;
    unsigned int hitCounts;
    int   fireSlot;
    float layerDistance;
    float rotateParamTarget;
    float rotateParam;
    float rotateSpeed;
    unsigned int behaviorState;
}
@property (nonatomic,assign) float  timeTillFire;
@property (nonatomic,assign) unsigned int shotsFired;
@property (nonatomic,assign) unsigned int hitCounts;
@property (nonatomic,assign) int    fireSlot;
@property (nonatomic,assign) float  layerDistance;
@property (nonatomic,assign) float  rotateParamTarget;
@property (nonatomic,assign) float  rotateParam;
@property (nonatomic,assign) float  rotateSpeed;
@property (nonatomic,assign) unsigned int behaviorState;
- (void) setupRotationParamsForSrc:(float)srcAngle target:(float)tgtAngle;
@end

@interface TurretSingle : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyAABBDelegate,EnemyKilledDelegate>

@end
