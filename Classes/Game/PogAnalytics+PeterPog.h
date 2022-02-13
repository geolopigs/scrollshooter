//
//  PogAnalytics+PeterPog.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogAnalytics.h"

@interface PogAnalytics (PeterPog)

- (void) logJourneyBegan;
- (void) logJourneyCompleted;
- (void) logJourneyAborted;
- (void) logJourneyRestarted;
- (void) logTourneyStarted;
- (void) logTourneyCompleted;
- (void) logRouteCompletedForRoute:(unsigned int)routeIndex;
- (void) logRoutePurchasedForRoute:(unsigned int)routeIndex;
- (void) logIAP:(NSString const*)productId;
- (void) logPogshopPurchase:(NSString const*)itemId;

// button presses
- (void) logStoreFromGameOver;
- (void) logGoalsFromGameOver;
- (void) logStatsFromGameOver;
- (void) logTweetFromGameOver;
- (void) logStoreFromMainMenu;
- (void) logGoalsFromMainMenu;
- (void) logStatsFromMainMenu;
- (void) logMoreFromMainMenu;
- (void) logGameCenterFromGoals;
- (void) logGimmieActivated;
- (void) logGimmieStore;
- (void) logGameCenterFromStats;
- (void) logAchievementId:(NSString*)achievementId;
- (void) logContinueGameButton;
- (void) logGetMoreCoinsGameOver;

@end
