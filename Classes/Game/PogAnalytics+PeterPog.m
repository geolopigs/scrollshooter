//
//  PogAnalytics+PeterPog.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogAnalytics+PeterPog.h"
#import "PogAnalyticsEvents.h"
#import "LevelManager.h"
#import "GameManager.h"

@implementation PogAnalytics (PeterPog)

- (void) logJourneyBegan
{
    unsigned int levelIndex = [[LevelManager getInstance] getSelectedLevelIndex]+1;
//    NSLog(@"Journey Began level %d with %@", levelIndex, [[GameManager getInstance] flyerType]);
    [self logTimedEvent:PogAnalyticsEvent_JourneyStarted withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   [NSNumber numberWithUnsignedInt:levelIndex],
                                                                   @"Route",
                                                                   [[GameManager getInstance] flyerType],
                                                                   @"Flyer",
                                                                   nil]];
}

- (void) logJourneyCompleted
{
    unsigned int levelIndex = [[LevelManager getInstance] getCurLevelIndex]+1;
//    NSLog(@"Journey Completed level %d with %@", levelIndex, [[GameManager getInstance] flyerType]);
    [self logTimedEventEnd:PogAnalyticsEvent_JourneyStarted withInfo:nil];
    [self logEvent:PogAnalyticsEvent_JourneyCompleted withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithUnsignedInt:levelIndex],
                                                                @"Route",
                                                                [[GameManager getInstance] flyerType],
                                                                @"Flyer",
                                                                nil]];
}

- (void) logJourneyAborted
{
    unsigned int levelIndex = [[LevelManager getInstance] getCurLevelIndex]+1;
//    NSLog(@"Journey Aborted level %d with %@", levelIndex, [[GameManager getInstance] flyerType]);
    [self logTimedEventEnd:PogAnalyticsEvent_JourneyStarted withInfo:nil];
    [self logEvent:PogAnalyticsEvent_JourneyAborted withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithUnsignedInt:levelIndex],
                                                                @"Route",
                                                                [[GameManager getInstance] flyerType],
                                                                @"Flyer",
                                                                nil]];
}

- (void) logJourneyRestarted
{
    unsigned int levelIndex = [[LevelManager getInstance] getCurLevelIndex]+1;
//    NSLog(@"Journey Restarted level %d with %@", levelIndex, [[GameManager getInstance] flyerType]);
    [self logEvent:PogAnalyticsEvent_JourneyRestarted withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithUnsignedInt:levelIndex],
                                                                @"Route",
                                                                [[GameManager getInstance] flyerType],
                                                                @"Flyer",
                                                                nil]];    
}

- (void) logTourneyStarted
{
    [self logTimedEvent:PogAnalyticsEvent_TourneyStarted withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   [[GameManager getInstance] flyerType],
                                                                   @"Flyer",
                                                                   nil]];
}

- (void) logTourneyCompleted
{
    [self logTimedEventEnd:PogAnalyticsEvent_TourneyStarted withInfo:nil];
    [self logEvent:PogAnalyticsEvent_TourneyCompleted withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              [[GameManager getInstance] flyerType],
                                                              @"Flyer",
                                                              nil]];
}

- (void) logAchievementId:(NSString *)achievementId
{
    NSArray* components = [achievementId componentsSeparatedByString:@"."];
    if(0 < [components count])
    {
        NSString* name = [components objectAtIndex:[components count]-1];
        [self logEvent:PogAnalyticsEvent_ReportAchievement withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     name,
                                                                     @"Achievement",
                                                                     nil]];
    }
}

- (void) logRouteCompletedForRoute:(unsigned int)routeIndex
{
    [self logEvent:PogAnalyticsEvent_RouteCompleted withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              [NSNumber numberWithUnsignedInt:routeIndex],
                                                              @"RouteIndex", 
                                                              nil]];
}

- (void) logRoutePurchasedForRoute:(unsigned int)routeIndex
{
    [self logEvent:PogAnalyticsEvent_RoutePurchased withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              [NSNumber numberWithUnsignedInt:routeIndex],
                                                              @"RouteIndex", 
                                                              nil]];
}

- (void) logIAP:(const NSString *)productId
{
    [self logEvent:PogAnalyticsEvent_IAP withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              productId,
                                                              @"Product", 
                                                              nil]];    
}

- (void) logPogshopPurchase:(const NSString *)itemId
{
    [self logEvent:PogAnalyticsEvent_PogshopPurchase withInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   itemId,
                                                   @"Item", 
                                                   nil]];        
}
#pragma mark - button presses

- (void) logStoreFromGameOver
{
    [self logEvent:PogAnalyticsEvent_StoreGameOver];
}

- (void) logGoalsFromGameOver
{
    [self logEvent:PogAnalyticsEvent_GoalsGameOver];
}

- (void) logStatsFromGameOver
{
    [self logEvent:PogAnalyticsEvent_StatsGameOver];
}

- (void) logTweetFromGameOver
{
    [self logEvent:PogAnalyticsEvent_TweetGameOver];
}

- (void) logStoreFromMainMenu
{
    [self logEvent:PogAnalyticsEvent_StoreMainMenu];
}

- (void) logGoalsFromMainMenu
{
    [self logEvent:PogAnalyticsEvent_GoalsMainMenu];
}

- (void) logStatsFromMainMenu
{
    [self logEvent:PogAnalyticsEvent_StatsMainMenu];
}

- (void) logMoreFromMainMenu
{
    [self logEvent:PogAnalyticsEvent_MoreMenu];
}

- (void) logGameCenterFromGoals
{
    [self logEvent:PogAnalyticsEvent_GoalsGameCenter];
}

- (void) logGimmieActivated
{
    [self logEvent:PogAnalyticsEvent_GimmieActivated];
}

- (void) logGimmieStore
{
    [self logEvent:PogAnalyticsEvent_GimmieStore];
}

- (void) logGameCenterFromStats
{
    [self logEvent:PogAnalyticsEvent_StatsGameCenter];
}

- (void) logContinueGameButton
{
    [self logEvent:PogAnalyticsEvent_ContinueGameButton];
}

- (void) logGetMoreCoinsGameOver
{
    [self logEvent:PogAnalyticsEvent_GetMoreCoinsGameOver];
}

@end
