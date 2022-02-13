//
//  GameCenterManager.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/3/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "GameCenterManagerDelegates.h"
#import "GameCenterCategories.h"

extern NSString* const GKACHIEVEMENTS_UNUSED;

@protocol GameCenterManagerDelegate <NSObject>
- (void) finishedLoadingGameCenterAchievements;
@end

@interface GameCenterManager : NSObject
{
    NSString* leaderboardCategory;
    GKLeaderboardTimeScope leaderboardTimeScope;
    
@private
    BOOL enabled;
    BOOL localPlayerAuthenticated;
    NSString* localPlayerID;
    NSString* gkScoresFilepath;
    NSString* _gkAchievementsFilepath;
    NSMutableDictionary* scoresToReport;
    NSMutableDictionary* _achievementsToReport;
    NSMutableDictionary* _achievementsDict;
}
@property (nonatomic,retain) NSString* leaderboardCategory;
@property (nonatomic,assign) GKLeaderboardTimeScope leaderboardTimeScope;
@property (nonatomic,assign) BOOL enabled;
@property (nonatomic,assign) BOOL localPlayerAuthenticated;
@property (nonatomic,retain) NSString* localPlayerID;
@property (nonatomic,retain) NSString* gkScoresFilepath;
@property (nonatomic,retain) NSString* gkAchievementsFilepath;
@property (nonatomic,retain) NSMutableDictionary* scoresToReport;
@property (nonatomic,retain) NSMutableDictionary* achievementsToReport;
@property (nonatomic,retain) NSMutableDictionary* achievementsDict;
@property (nonatomic,retain) NSObject<GameCenterManagerDelegate>* delegate;
@property (nonatomic,retain) NSObject<GameCenterManagerAuthenticationDelegate>* authenticationDelegate;

// singleton
+ (GameCenterManager*)getInstance;
+ (void) destroyInstance;

// authentication
- (void) checkAndAuthenticate;  // must call this first thing in the game before any Game Center related code is executed

// reporting
- (void) reportScore:(int64_t)score forCategory:(NSString*)category;
- (void) reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent;
- (void) resetAchievements;

// response to app
- (void) appWillTerminate;
- (void) appDidEnterBackground;

- (BOOL) isGameCenterAvailable;
- (BOOL) isAuthenticated;
@end

