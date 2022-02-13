//
//  BoarFighterBasic.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/14/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface BoarFighterBasicContext : NSObject
{
    // config params
    float timeBetweenShots;
    float shotSpeed;
    CGPoint introDoneBotLeft;
    CGPoint introDoneTopRight;
    CGPoint colAreaBotLeft;
    CGPoint colAreaTopRight;
    CGPoint introVel;
    float angularSpeed;
    float launchDelay;
    float launchSpeed;
    BOOL launchLeft;        // TRUE if left, FALSE if right
    float retireDelay; 
    BOOL hasGroupBonus;     // if TRUE, incap the whole group gives the player a bonus
    
    // runtime params
    float timeTillFire;
    unsigned int behaviorState;
    float rot;
    float launchTimer;
    float timeTillRetire;
    BOOL collisionOn;
}
@property (nonatomic,assign) float timeBetweenShots;
@property (nonatomic,assign) float shotSpeed;
@property (nonatomic,assign) CGPoint introDoneBotLeft;
@property (nonatomic,assign) CGPoint introDoneTopRight;
@property (nonatomic,assign) CGPoint colAreaBotLeft;
@property (nonatomic,assign) CGPoint colAreaTopRight;
@property (nonatomic,assign) CGPoint introVel;
@property (nonatomic,assign) float angularSpeed;
@property (nonatomic,assign) float launchDelay;
@property (nonatomic,assign) float launchSpeed;
@property (nonatomic,assign) BOOL launchLeft;
@property (nonatomic,assign) float retireDelay;
@property (nonatomic,assign) BOOL hasGroupBonus;

@property (nonatomic,assign) float timeTillFire;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,assign) float rot;
@property (nonatomic,assign) float launchTimer;
@property (nonatomic,assign) float timeTillRetire;
@property (nonatomic,assign) BOOL collisionOn;
@end

@interface BoarFighterBasic : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemySpawnedDelegate>


@end
