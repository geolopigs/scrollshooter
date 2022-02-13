//
//  BossWeapon.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/23/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"


@class Enemy;
@class Player;
@interface BossWeapon : NSObject<EnemyKilledDelegate>
{
    // scatter config
    float scatterBegin;
    float scatterInterval;
    unsigned int scatterShotsPerRound;
    float shotSpeed;
    unsigned overheatRounds;
    float cooldownDelay;
    NSDictionary* scatterBombContext;

    // homing missile config
    unsigned int missilesPerRound;
    float missileAngleBegin;
    float missileAngleSpan;
    NSDictionary* missileContext;
    NSString* _missileType;      // PlayerMissile or BlueMissile
    
    // laser config
    NSDictionary* laserContext;
    
    // scatter runtime
    float timeTillFire;
    unsigned int roundsFired;
    
    // missile runtime
    NSMutableArray* activeMissiles;
    
    // runtime
    NSMutableArray* activeComponents;
    float _startupTimer;
    
    // config
    float shotDelay;
    CGPoint shotPos;
    
    CGPoint localPos;
    NSDictionary* config;
    unsigned int weaponType;
}
@property (nonatomic,retain) NSDictionary* scatterBombContext;
@property (nonatomic,retain) NSDictionary* missileContext;
@property (nonatomic,retain) NSString* missileType;
@property (nonatomic,retain) NSDictionary* laserContext;
@property (nonatomic,assign) float timeTillFire;
@property (nonatomic,retain) NSMutableArray* activeMissiles;
@property (nonatomic,retain) NSMutableArray* activeComponents;
@property (nonatomic,assign) float startupTimer;

// configs
@property (nonatomic,assign) float shotDelay;
@property (nonatomic,assign) float startupDelay;
@property (nonatomic,assign) CGPoint localPos;
@property (nonatomic,retain) NSDictionary* config;
@property (nonatomic,assign) unsigned int weaponType;

- (id) initFromConfig:(NSDictionary*)givenConfig;
- (void) reset;
- (BOOL) enemyFire:(Enemy*)enemy elapsed:(NSTimeInterval)elapsed;
- (BOOL) enemyFire:(Enemy*)enemy fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed;
- (BOOL) playerFire:(Player*)player elapsed:(NSTimeInterval)elapsed;
- (BOOL) playerFire:(Player*)player fromPos:(CGPoint)pos elapsed:(NSTimeInterval)elapsed;
- (void) playerUpdateWeapon:(NSTimeInterval)elapsed;
- (void) killRetiredMissiles;
- (void) killAllMissiles;
- (void) killAllComponents;
+ (void) enemyFireScatterBomb:(Enemy*)enemy fromPos:(CGPoint)pos withVel:(CGPoint)vel triggerContext:(NSDictionary*)triggerContext;
@end
