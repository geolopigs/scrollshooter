//
//  AchievementsManager.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/22/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameCenterManager.h"

@class Enemy;
@interface AchievementsManager : NSObject<GameCenterManagerDelegate>
{
    NSArray* _orderedAchievementKeys;
    NSMutableDictionary* _achievementsRegistry;
    NSArray* _routeAchievements;
}
@property (nonatomic,retain) NSArray* orderedAchievementKeys;
@property (nonatomic,retain) NSMutableDictionary* achievementsRegistry;
@property (nonatomic,retain) NSArray* routeAchievements;
@property (nonatomic,assign) unsigned int continueCount;
@property (nonatomic,assign) unsigned int routeCount;

- (void) reportAchievementsToGameCenter;
- (void) resetGameLocalAchievements;
- (NSDictionary*) getGameAchievementsData;
- (BOOL) supportsGameCenterForIdentifier:(NSString *)identifier;
- (BOOL) supportsGimmieWorldForIdentifier:(NSString *)identifier;
- (unsigned int) indexOfNextIncompleteFromOrderedAchievement;

// Multipliers
- (void) updateMultiplier:(unsigned int)newValue;

// weapons
- (void) maxMissilesCompleted;
- (void) maxGunsCompleted;

// enemies
- (void) blimpKilled;
- (void) subKilled;
- (void) pumpkinKilled;
- (void) waterBoarKilled;
- (void) landBoarKilled;
- (void) airBoarKilled;
- (void) hoverKilled;
- (void) checkBoarAchievementsForEnemy:(Enemy*)enemy;

// piggybank
- (void) incrCoins:(unsigned int)incr;

// progression
- (void) incrContinueCount;
- (void) resetContinueCount;
- (void) incrRouteCount;
- (void) resetRouteCount;
- (void) deliveredCargos:(unsigned int)cargos;
- (void) completeRouteWithFullHealth:(int)playerHealth;
- (void) completeGradeAOnRoute:(unsigned int)routeIndex;
- (void) completeRoute:(unsigned int)routeIndex;
- (void) unlockRoute:(unsigned int)routeIndex;
- (void) incrFlightTime:(NSTimeInterval)flightTime;
//- (void) tourneyWon;

// singleton
+(AchievementsManager*) getInstance;
+(void) destroyInstance;


@end
