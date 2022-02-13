//
//  StatsData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const unsigned int STATS_FLAG_COMPLETEDTUTORIAL;
extern const unsigned int STATS_FLAG_COMPLETEDTUTORIALTOURNEY;

@interface StatsData : NSObject<NSCoding>
{    
    // stats    
    unsigned int highscore;
    unsigned int _cargosDelivered;
    NSTimeInterval _flightTime;
    NSMutableDictionary* envScores;
    unsigned int _pogcoinsCollected;
    unsigned int _highMultiplier;
    unsigned int _numTourneyWins;   // number of time ranked #1 in tourneys
    
    // achievements (see AchievementsManager to methods that manage this field)
    NSMutableDictionary* _achievements;
    
    unsigned int _flags;
}
@property (nonatomic,assign) unsigned int highscore;
@property (nonatomic,assign) unsigned int cargosDelivered;
@property (nonatomic,assign) NSTimeInterval flightTime;
@property (nonatomic,assign) unsigned int pogcoinsCollected;
@property (nonatomic,assign) unsigned int highMultiplier;
@property (nonatomic,assign) unsigned int numTourneyWins;
@property (nonatomic,retain) NSMutableDictionary* envScores;
@property (nonatomic,retain) NSMutableDictionary* achievements;
@property (nonatomic,assign) unsigned int flags;

- (void) setHighscore:(unsigned int)newScore forEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (void) setGradeScore:(unsigned int)newScore forEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (unsigned int) getHighscoreForEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (unsigned int) getGradeScoreForEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (void) setHasCompleted:(BOOL)yesNo forEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (BOOL) hasCompletedForEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (void) setFlightTime:(NSTimeInterval)flightTime forEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (NSTimeInterval) getFlightTimeForEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (void) setCargosDelivered:(unsigned int)cargos forEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (unsigned int) getCargosDeliveredForEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (void) resetHighscores;

@end
