//
//  StatsManager.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StatsManagerUIDelegate.h"

// Notifications
extern NSString* const kStatsManagerNoteDidChangeCoins;

@class EnemyRegistryData;
@class LootRegistryData;
@class StatsData;
@class PlayerData;
@class RouteInfo;

enum ScoreGrades
{
    SCOREGRADE_NONE = 0,
    SCOREGRADE_CMINUS,
    SCOREGRADE_C,
    SCOREGRADE_BMINUS,
    SCOREGRADE_B,
    SCOREGRADE_AMINUS,
    SCOREGRADE_A
};

@interface StatsManager : NSObject
{
    // registries for looking up info
    EnemyRegistryData* enemyReg;
    LootRegistryData* lootReg;
    int initialContinues;
    
    // ui delegate
    NSObject<StatsManagerUIDelegate>* delegate;
    
    // live data for current session
    NSString* curEnvName;
    unsigned int curLevel;
    unsigned int pointsCurLevel;
    unsigned int gradeScoreLevelComplete;   // for computing the grade at the LevelComplete screen
    unsigned int cargosCurLevel;
    unsigned int pointsTotal;
    unsigned int cargosCollectCount;    // different from cargosTotal, this is the number of cagos
                                        // the player has collected from the beginning of the level till level-end or game-over
                                        // regardless of whether player has dropped them
    NSTimeInterval _sessionFlightTime;
    NSTimeInterval _flightTimeCurLevel;
    unsigned int _sessionCargosDelivered;
    unsigned int _sessionCashEarned;
    unsigned int _sessionScore;
    unsigned int _accCompletedMultiplier;
    unsigned int _accMultiplier;
    unsigned int _curLevelMultiplier;
    unsigned int continuesRemaining;
    int curHealth;
    unsigned int _sessionContinueCount;
    
    // committed data
    NSString* statsFilepath;
    NSString* playerFilepath;
    StatsData* statsData;
    PlayerData* playerData;
    
    // internal
    // stats for the level completion screen (only valid between StatsManager::completeLevel and the display of the screen)
    unsigned int deliveryCargoNum;
    unsigned int deliveryCashEarned;
    BOOL wasLastScoreHighscore;
    unsigned int previousHighscore;
    
    // game center related
    unsigned int lastReportedHighscore;
    unsigned int lastReportedPiggybank;
    unsigned int _lastReportedTourneyHigh;
    unsigned int _lastReportedTourneyWins;
}
@property (nonatomic,retain) EnemyRegistryData* enemyReg;
@property (nonatomic,retain) LootRegistryData* lootReg;
@property (nonatomic,retain) NSObject<StatsManagerUIDelegate>* delegate;
@property (nonatomic,retain) NSString* curEnvName;
@property (nonatomic,assign) unsigned int curLevel;
@property (nonatomic,assign) unsigned int pointsCurLevel;
@property (nonatomic,assign) unsigned int gradeScoreLevelComplete;
@property (nonatomic,assign) unsigned int cargosCurLevel;
@property (nonatomic,assign) unsigned int pointsTotal;
@property (nonatomic,assign) unsigned int cargosCollectCount;
@property (nonatomic,readonly) NSTimeInterval sessionFlightTime;
@property (nonatomic,readonly) unsigned int sessionCargosDelivered;
@property (nonatomic,readonly) unsigned int sessionCashEarned;
@property (nonatomic,readonly) unsigned int sessionScore;
@property (nonatomic,readonly) unsigned int sessionMultiplier;
@property (nonatomic,assign) unsigned int curLevelMultiplier;
@property (nonatomic,readonly) unsigned int highestMultiplier;
@property (nonatomic,assign) NSTimeInterval flightTimeCurLevel;
@property (nonatomic,assign) unsigned int continuesRemaining;
@property (nonatomic,assign) unsigned int sessionContinueCount;
@property (nonatomic,retain) NSString* statsFilepath;
@property (nonatomic,retain) NSString* playerFilepath;
@property (nonatomic,retain) StatsData* statsData;
@property (nonatomic,retain) PlayerData* playerData;
@property (nonatomic,readonly) BOOL wasLastScoreHighscore;
@property (nonatomic,assign) unsigned int previousHighscore;


// singleton
+(StatsManager*) getInstance;
+(void) destroyInstance;

// save load
- (void) loadPlayerData;
- (void) savePlayerData;
- (void) loadStatsData;
- (void) saveStatsData;

// management
- (void) setupForEnvNamed:(NSString*)envName level:(unsigned int)levelNum;
- (void) setupForNewGame;
- (void) resetPointsCur;
- (void) resetPointsTotal;
- (void) resetCargosCur;
- (void) resetScoreMultiplier;
- (void) resetCurLevel;
- (void) resetFlightTime;
- (void) resetSessionCash;
- (void) commitHighScore;
- (void) completeLevel;
- (void) completeTimebasedLevel;
- (void) completeGameSessionWithCoins:(BOOL)creditCoins;
- (void) resetAllHighscores;
- (void) reportScoresToGameCenter;

// per frame updates
- (void) updateFlightTime:(NSTimeInterval)elapsed;

// points accessors
- (void) destroyedEnemyNamed:(NSString*)name andNumShots:(unsigned int)numShots;
- (void) creditBulletHits:(unsigned int)num;
- (void) creditCollection:(unsigned int)num;
- (void) creditBonusForGroupNamed:(NSString*)groupName;
- (unsigned int) currentHighscore;
- (void) incrementScoreMultiplier;
- (void) dropScoreMultiplier;
- (void) accTourneyWins:(unsigned int)num;
- (unsigned int) getTourneyWins;

// loots accessors
- (void) collectedLootNamed:(NSString*)name;
- (void) dropLootNamed:(NSString*)name;
- (void) collectedCargo:(unsigned int)num;
- (void) droppedCargo:(unsigned int)num;

// health accessors
- (void) updateHealth:(int)newHealth;

// power accessors
- (void) updateNumKillBullets:(unsigned int)newNum;

// cash accessors
- (unsigned int) getTotalCash;
- (void) collectCoinsFromGameOver;
- (void) commitCoins:(int)newAmount;
- (void) commitAddCoins:(int)addAmount;

// delivery screen
- (unsigned int) deliveryGetCargoNum;
- (unsigned int) deliveryGetCashEarned;

// progression queries
- (unsigned int) nextIncompleteLevelForEnv:(NSString*)envName;
- (enum ScoreGrades) gradeForEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (enum ScoreGrades) gradeForScore:(unsigned int)givenScore env:(NSString*)envName level:(unsigned int)levelIndex;
- (NSString*) gradeStringForScore:(unsigned int)givenScore env:(NSString*)envName level:(unsigned int)levelIndex;

// continues
- (void) incrContinueCount;

// queries
- (NSTimeInterval) getTotalFlightTime;
- (unsigned int) getHighscore;
- (unsigned int) getCargosDelivered;
- (unsigned int) getHighscoreForEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (unsigned int) getCoinsCollected;

// one time flags
- (BOOL) hasCompletedTutorial;
- (void) setCompletedTutorial;
- (void) clearCompletedTutorial;
- (BOOL) hasCompletedTutorialTourney;
- (void) setCompletedTutorialTourney;
- (void) clearCompletedTutorialTourney;
@end
