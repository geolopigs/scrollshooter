//
//  AchievementsManager.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/22/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "AchievementsManager.h"
#import "AchievementsData.h"
#import "StatsManager.h"
#import "StatsData.h"
#import "AchievementRegEntry.h"
#import "GameCenterCategories.h"
#import "GameManager.h"
#import "Enemy.h"
#import "DuaSeatoArchetype.h"
#import "BossArchetype.h"
#import "Boss2.h"
#import "BoarSpeedo.h"
#import "CargoBoat.h"
#import "Player.h"
#import "PlayerInventory.h"
#import "PogAnalyticsEvents.h"
#import "PogAnalytics+PeterPog.h"

@interface AchievementsManager (PrivateMethods)
- (void) initOrderedKeys;
- (void) initRegistry;
- (void) initRouteAchievements;
- (AchievementsData*) getAchievementDataForIdentifier:(NSString*)identifier;
- (void) syncWithGameCenterLoadedAchievements;
- (void) markAllDirty;
- (void) completeOneShotAchievement:(NSString*)identifier;
- (void) reportAchievementToGimmieWorldFor:(AchievementsData*)achData;
@end

@implementation AchievementsManager
@synthesize orderedAchievementKeys = _orderedAchievementKeys;
@synthesize achievementsRegistry = _achievementsRegistry;
@synthesize routeAchievements = _routeAchievements;
@synthesize continueCount = _continueCount;
@synthesize routeCount = _routeCount;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.achievementsRegistry = [NSMutableDictionary dictionary];
        [self initOrderedKeys];
        [self initRegistry];
        [self initRouteAchievements];
        _continueCount = 0;
        _routeCount = 0;
        
        // register myself as a delegate to GameCenterManager to receive calls when achievements are finished loading
        [GameCenterManager getInstance].delegate = self;
    }
    return self;
}

- (void) dealloc
{
    self.routeAchievements = nil;
    self.achievementsRegistry = nil;
    self.orderedAchievementKeys = nil;
    [super dealloc];
}

- (void) initOrderedKeys
{
    _orderedAchievementKeys = [[NSArray arrayWithObjects:
                                GAMECENTER_ACHIEVEMENT_MULTX3,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE2,
                                GAMECENTER_ACHIEVEMENT_BLIMP,
                                GAMECENTER_ACHIEVEMENT_10CARGOS,
                                GAMECENTER_ACHIEVEMENT_MULTX10,
                                GAMECENTER_ACHIEVEMENT_ROUTE1A,
//                                GAMECENTER_ACHIEVEMENT_1TOURNEYWIN,
                                GAMECENTER_ACHIEVEMENT_30MINS,
                                GAMECENTER_ACHIEVEMENT_50CARGOS,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE3,
                                GAMECENTER_ACHIEVEMENT_SUB,
                                GAMECENTER_ACHIEVEMENT_ROUTE2A,
                                GAMECENTER_ACHIEVEMENT_MAXGUNS,
                                GAMECENTER_ACHIEVEMENT_POGWING1ROUTE,
                                GAMECENTER_ACHIEVEMENT_POGRANG1ROUTE,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE4,
                                GAMECENTER_ACHIEVEMENT_ROUTE3A,
                                GAMECENTER_ACHIEVEMENT_3ROUTES,
                                GAMECENTER_ACHIEVEMENT_PUMPKIN,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE5,
                                GAMECENTER_ACHIEVEMENT_ROUTE4A,
                                GAMECENTER_ACHIEVEMENT_POGWINGMAX,
                                GAMECENTER_ACHIEVEMENT_POGRANGMAX,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE6,
                                GAMECENTER_ACHIEVEMENT_ROUTE5A,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE7,
                                GAMECENTER_ACHIEVEMENT_ROUTE6A,
                                GAMECENTER_ACHIEVEMENT_6ROUTES,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE8,
                                GAMECENTER_ACHIEVEMENT_ROUTE7A,
                                GAMECENTER_ACHIEVEMENT_MULTX20,
                                GAMECENTER_ACHIEVEMENT_100MINS,
                                GAMECENTER_ACHIEVEMENT_HOVER,
                                GAMECENTER_ACHIEVEMENT_300MINS,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE9,
                                GAMECENTER_ACHIEVEMENT_ROUTE8A,
                                GAMECENTER_ACHIEVEMENT_8ROUTES,
                                GAMECENTER_ACHIEVEMENT_UNLOCKROUTE10,
                                GAMECENTER_ACHIEVEMENT_ROUTE9A,
                                GAMECENTER_ACHIEVEMENT_ROUTE10A,
                                GAMECENTER_ACHIEVEMENT_ACE,
                                GAMECENTER_ACHIEVEMENT_FULLHEALTH,
                                GAMECENTER_ACHIEVEMENT_500WATERBOARS,
                                GAMECENTER_ACHIEVEMENT_500LANDBOARS,
                                GAMECENTER_ACHIEVEMENT_500AIRBOARS,
                                GAMECENTER_ACHIEVEMENT_100CARGOS,
                                GAMECENTER_ACHIEVEMENT_250k,
                                GAMECENTER_ACHIEVEMENT_500k,
                                GAMECENTER_ACHIEVEMENT_1M,
                                nil] retain];

}

- (void) initRegistry
{
    // Multipliers
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Multiplier x3"
                                                          description:@"Collect 10 cargos without getting hit"
                                                          targetValue:1 
                                                             supports:(SERVER_TYPE_GAMECENTER|SERVER_TYPE_GIMMIEWORLD)
                                                             gimmieID:@"10"]
                              forKey:GAMECENTER_ACHIEVEMENT_MULTX3];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Multiplier x10" 
                                                          description:@"Collect 45 cargos without getting hit"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_MULTX10];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Multiplier x20" 
                                                          description:@"Collect 95 cargos without getting hit"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_MULTX20];

    // weapons
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Missile Maxer" 
                                                          description:@"Upgrade weapons to max level"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_MAXMISSILES];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Gunner Maxer" 
                                                          description:@"Upgrade weapons to max level"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_MAXGUNS];

    // enemies
    AchievementRegEntry* waterBoarEntry = [AchievementRegEntry newWithName:@"Water Boar Nemesis" 
                                                               description:@"Take out 500 boars on water"
                                                               targetValue:500];
    waterBoarEntry.progressFormat = @"%d boars to go";
    [_achievementsRegistry setObject:waterBoarEntry
                              forKey:GAMECENTER_ACHIEVEMENT_500WATERBOARS];
    AchievementRegEntry* landBoarEntry = [AchievementRegEntry newWithName:@"Land Boar Nemesis" 
                                                              description:@"Take out 500 boars on land"
                                                              targetValue:500];
    landBoarEntry.progressFormat = @"%d boars to go";
    [_achievementsRegistry setObject:landBoarEntry
                              forKey:GAMECENTER_ACHIEVEMENT_500LANDBOARS];
    AchievementRegEntry* airBoarEntry = [AchievementRegEntry newWithName:@"Air Boar Nemesis" 
                                                             description:@"Take out 500 boars in the air"
                                                             targetValue:500];
    airBoarEntry.progressFormat = @"%d boars to go";
    [_achievementsRegistry setObject:airBoarEntry
                              forKey:GAMECENTER_ACHIEVEMENT_500AIRBOARS];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Blimp Popper" 
                                                          description:@"Destroy a Blimp"
                                                          targetValue:1 
                                                             supports:(SERVER_TYPE_GAMECENTER|SERVER_TYPE_GIMMIEWORLD)
                                                             gimmieID:@"11"]
                              forKey:GAMECENTER_ACHIEVEMENT_BLIMP];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Sub Sinker" 
                                                          description:@"Destroy a Submarine Boss"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_SUB];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Pumpkin Smasher" 
                                                          description:@"Destroy a Pumpkin Boss"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_PUMPKIN];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Hover Downer" 
                                                          description:@"Destroy a Hover Fighter"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_HOVER];

    // cargos
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Trainee Courier" 
                                                          description:@"Deliver 10 cargos in one route"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_10CARGOS];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Semi-pro Courier" 
                                                          description:@"Deliver 50 cargos in one route"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_50CARGOS];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Professional Courier" 
                                                          description:@"Deliver 100 cargos in one route"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_100CARGOS];

    // piggybank
    AchievementRegEntry* entry250k = [AchievementRegEntry newWithName:@"250k Club" 
                                                          description:@"Earn 250k Pogcoins"
                                                          targetValue:250000];
    entry250k.progressFormat = @"$%d to go";
    [_achievementsRegistry setObject:entry250k
                              forKey:GAMECENTER_ACHIEVEMENT_250k];
    AchievementRegEntry* entry500k = [AchievementRegEntry newWithName:@"500k Club" 
                                                          description:@"Earn 500k Pogcoins"
                                                          targetValue:500000];
    entry500k.progressFormat = @"$%d to go";
    [_achievementsRegistry setObject:entry500k
                              forKey:GAMECENTER_ACHIEVEMENT_500k];
    AchievementRegEntry* entry1m = [AchievementRegEntry newWithName:@"Millionaire" 
                                                        description:@"Earn 1 million Pogcoins"
                                                        targetValue:1000000];
    entry1m.progressFormat = @"$%d to go";
    [_achievementsRegistry setObject:entry1m
                              forKey:GAMECENTER_ACHIEVEMENT_1M];
    
    // simple route unlocks
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 2" 
                                                          description:@"Complete Route 1 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE2];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 3" 
                                                          description:@"Complete Route 2 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE3];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 4" 
                                                          description:@"Complete Route 3 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE4];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 5" 
                                                          description:@"Complete Route 4 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE5];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 6" 
                                                          description:@"Complete Route 5 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE6];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 7" 
                                                          description:@"Complete Route 6 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE7];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 8" 
                                                          description:@"Complete Route 7 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE8];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 9" 
                                                          description:@"Complete Route 8 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE9];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Unlock Route 10" 
                                                          description:@"Complete Route 9 or unlock in Pogshop"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE10];

    // route completion with distinction
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Courier Dude" 
                                                          description:@"Finish 3 routes without continuing"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_3ROUTES];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Courier Mini Marathon" 
                                                          description:@"Finish 6 routes without continuing"
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_6ROUTES];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Courier Marathon" 
                                                          description:@"Finish 8 routes without continuing"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_8ROUTES];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 1 Expert" 
                                                          description:@"Get an A in route 1"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE1A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 2 Expert" 
                                                          description:@"Get an A in route 2"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE2A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 3 Expert" 
                                                          description:@"Get an A in route 3"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE3A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 4 Expert" 
                                                          description:@"Get an A in route 4"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE4A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 5 Expert" 
                                                          description:@"Get an A in route 5"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE5A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 6 Expert" 
                                                          description:@"Get an A in route 6"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE6A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 7 Expert" 
                                                          description:@"Get an A in route 7"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE7A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 8 Expert" 
                                                          description:@"Get an A in route 8"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE8A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 9 Expert" 
                                                          description:@"Get an A in route 9"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE9A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Route 10 Expert" 
                                                          description:@"Get an A in route 10"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ROUTE10A];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Super Pog" 
                                                          description:@"Get A's in all routes"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_ACE];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Scratch Free" 
                                                          description:@"Finish one route without getting hit"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_FULLHEALTH];
    
    // flighttime
    AchievementRegEntry* entry30mins = [AchievementRegEntry newWithName:@"Trainee Pilot" 
                                                          description:@"Gain 30 minutes Flight Time"
                                                          targetValue:30];
    entry30mins.progressFormat = @"%d minutes to go";
    [_achievementsRegistry setObject:entry30mins
                              forKey:GAMECENTER_ACHIEVEMENT_30MINS];
    AchievementRegEntry* entry100mins = [AchievementRegEntry newWithName:@"Amateur Pilot" 
                                                            description:@"Gain 100 minutes Flight Time"
                                                            targetValue:100];
    entry100mins.progressFormat = @"%d minutes to go";
    [_achievementsRegistry setObject:entry100mins
                              forKey:GAMECENTER_ACHIEVEMENT_100MINS];
    AchievementRegEntry* entry300mins = [AchievementRegEntry newWithName:@"Pro Pilot" 
                                                            description:@"Gain 300 minutes Flight Time"
                                                            targetValue:300];
    entry300mins.progressFormat = @"%d minutes to go";
    [_achievementsRegistry setObject:entry300mins
                              forKey:GAMECENTER_ACHIEVEMENT_300MINS];
    
    // tourney
//    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Win Tourney" 
//                                                          description:@"Place #1 in one online Tourney"   
//                                                          targetValue:1]
//                              forKey:GAMECENTER_ACHIEVEMENT_1TOURNEYWIN];
    
    // different flyers
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Pogwing Route" 
                                                          description:@"Complete any route with Pogwing"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_POGWING1ROUTE];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Pograng Route" 
                                                          description:@"Complete any route with Pograng"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_POGRANG1ROUTE];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Pogwing Max Weapons" 
                                                          description:@"Max out Pogwing's weapons in game"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_POGWINGMAX];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Pograng Max Weapons" 
                                                          description:@"Max out Pograng's weapons in game"   
                                                          targetValue:1]
                              forKey:GAMECENTER_ACHIEVEMENT_POGRANGMAX];
    
    
    
    // simple route completion
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Complete Route 1" 
                                                          description:@"Complete Route 1"
                                                          targetValue:1 
                                                             supports:SERVER_TYPE_GIMMIEWORLD 
                                                             gimmieID:@"6"]
                              forKey:GAME_GOAL_ROUTE1];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Complete Route 2" 
                                                          description:@"Complete Route 2"
                                                          targetValue:1 
                                                             supports:SERVER_TYPE_GIMMIEWORLD 
                                                             gimmieID:@"7"]
                              forKey:GAME_GOAL_ROUTE2];
    [_achievementsRegistry setObject:[AchievementRegEntry newWithName:@"Complete Route 3" 
                                                          description:@"Complete Route 3"
                                                          targetValue:1 
                                                             supports:SERVER_TYPE_GIMMIEWORLD 
                                                             gimmieID:@"8"]
                              forKey:GAME_GOAL_ROUTE3];
}

- (void) initRouteAchievements
{
    self.routeAchievements = [NSArray arrayWithObjects:
                              GAMECENTER_ACHIEVEMENT_ROUTE1A,
                              GAMECENTER_ACHIEVEMENT_ROUTE2A,
                              GAMECENTER_ACHIEVEMENT_ROUTE3A,
                              GAMECENTER_ACHIEVEMENT_ROUTE4A,
                              GAMECENTER_ACHIEVEMENT_ROUTE5A,
                              GAMECENTER_ACHIEVEMENT_ROUTE6A,
                              GAMECENTER_ACHIEVEMENT_ROUTE7A,
                              GAMECENTER_ACHIEVEMENT_ROUTE8A,
                              GAMECENTER_ACHIEVEMENT_ROUTE9A,
                              GAMECENTER_ACHIEVEMENT_ROUTE10A, 
                              nil];
}

- (void) reportAchievementsToGameCenter
{
    NSDictionary* achievementsDataDict = [[[StatsManager getInstance] statsData] achievements];
    for(NSString* curKey in achievementsDataDict)
    {
        if([self supportsGameCenterForIdentifier:curKey])
        {
            AchievementsData* curData = [achievementsDataDict objectForKey:curKey];
            [curData reportToGameCenter];
        }
    }
}

- (void) resetGameLocalAchievements
{
    [[[[StatsManager getInstance] statsData] achievements] removeAllObjects];
}

- (NSDictionary*) getGameAchievementsData
{
    return [[[StatsManager getInstance] statsData] achievements];
}

- (BOOL) supportsGameCenterForIdentifier:(NSString *)identifier
{
    BOOL result = NO;
    AchievementRegEntry* info = [_achievementsRegistry objectForKey:identifier];
    if(info)
    {
        result = [info supportsGameCenter];
    }
    return result;
}

- (BOOL) supportsGimmieWorldForIdentifier:(NSString *)identifier
{
    BOOL result = NO;
    AchievementRegEntry* info = [_achievementsRegistry objectForKey:identifier];
    if(info)
    {
        result = [info supportsGimmieWorld];
    }
    return result;    
}


- (void) completeOneShotAchievement:(NSString *)identifier
{
    AchievementsData* ach = [self getAchievementDataForIdentifier:identifier];
    [ach updateCurrentValue:1];
    if([ach isNewlyCompleted])
    {
        [[GameManager getInstance] showAchievementCompletedForIdentifier:[ach identifier]];
        [[PogAnalytics getInstance] logAchievementId:identifier];
    }
}

- (void) incrementAchievement:(NSString*)identifier byNum:(unsigned int)incr
{
    AchievementsData* ach = [self getAchievementDataForIdentifier:identifier];
    [ach incrByValue:incr];
    if([ach isNewlyCompleted])
    {
        [[GameManager getInstance] showAchievementCompletedForIdentifier:[ach identifier]];
        [[PogAnalytics getInstance] logAchievementId:identifier];
    }
}

- (void) watermarkAchievement:(NSString*)identifier withNum:(unsigned int)newValue
{
    AchievementsData* ach = [self getAchievementDataForIdentifier:identifier];
    [ach updateWatermarkValue:newValue];
    if([ach isNewlyCompleted])
    {
        [[GameManager getInstance] showAchievementCompletedForIdentifier:[ach identifier]];
        [[PogAnalytics getInstance] logAchievementId:identifier];
    }    
}

- (unsigned int) indexOfNextIncompleteFromOrderedAchievement
{
    unsigned int nextIndex = 0;
    for(NSString* cur in _orderedAchievementKeys)
    {
        AchievementsData* curData = [[self getGameAchievementsData] objectForKey:cur];
        if(![curData isCompleted])
        {
            break;
        }
        ++nextIndex;
    }
    if(nextIndex >= [_orderedAchievementKeys count])
    {
        // return 0 if all achievements are completed
        nextIndex = 0;
    }
    
    return nextIndex;
}


#pragma mark - Multipliers
- (void) updateMultiplier:(unsigned int)newValue
{
    if(20 <= newValue)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_MULTX20];
    }
    if(10 <= newValue)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_MULTX10];
    }
    if(3 <= newValue)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_MULTX3];
    }
}

#pragma mark - Weapons
- (void) maxMissilesCompleted
{
    [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_MAXMISSILES];
}

- (void) maxGunsCompleted
{
    // set flyer specific completion achievements
    FlyerType flyerType = [[[GameManager getInstance] playerShip] flyerType];
    switch(flyerType)
    {
        case FlyerTypePograng:
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_POGRANGMAX];
            break;
            
        case FlyerTypePogwing:
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_POGWINGMAX];
            break;
            
        default:
        case FlyerTypePoglider:
            // default assumes Poglider
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_MAXGUNS];
            break;             
    }
}

#pragma mark - enemies
- (void) blimpKilled
{
    [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_BLIMP];
}

- (void) subKilled
{
    [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_SUB];
}

- (void) pumpkinKilled
{
    [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_PUMPKIN];
}

- (void) waterBoarKilled
{
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_500WATERBOARS byNum:1];
}

- (void) landBoarKilled
{
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_500LANDBOARS byNum:1];
}

- (void) airBoarKilled
{
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_500AIRBOARS byNum:1];
}

- (void) hoverKilled
{
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_HOVER byNum:1];
}

- (void) checkBoarAchievementsForEnemy:(Enemy *)enemy
{
    Enemy* parentEnemy = [enemy parentEnemy];
    if(parentEnemy)
    {
        id behaviorDelegate = [parentEnemy behaviorDelegate];
        if([behaviorDelegate isMemberOfClass:[DuaSeatoArchetype class]])
        {
            [self airBoarKilled];
        }
        else if([behaviorDelegate isMemberOfClass:[BossArchetype class]])
        {
            [self airBoarKilled];
        }
        else if([behaviorDelegate isMemberOfClass:[BoarSpeedo class]])
        {
            [self waterBoarKilled];
        }
        else if([behaviorDelegate isMemberOfClass:[CargoBoat class]])
        {
            [self waterBoarKilled];
        }
        else if([behaviorDelegate isMemberOfClass:[Boss2 class]])
        {
            Boss2* boss2 = (Boss2*)behaviorDelegate;
            if(([[boss2 typeName] isEqualToString:@"BoarSubL2"]) ||
               ([[boss2 typeName] isEqualToString:@"BoarSubL6"]))
            {
                [self waterBoarKilled];
            }
            else
            {
                [self airBoarKilled];
            }
        }
        else
        {
            // in all other cases, credit the land boar
            [self landBoarKilled];
        }
    }
    else
    {
        [self landBoarKilled];
    }
}

#pragma mark - Piggybank
- (void) incrCoins:(unsigned int)incr
{
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_250k byNum:incr];
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_500k byNum:incr];
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_1M byNum:incr];
}

#pragma mark - progression
- (void) incrContinueCount
{
    _continueCount++;
}

- (void) resetContinueCount
{
    _continueCount = 0;
}

- (void) incrRouteCount
{
    _routeCount++;
    if(0 == _continueCount)
    {
        if(3 <= _routeCount)
        {
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_3ROUTES];
        }
        if(6 <= _routeCount)
        {
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_6ROUTES];
        }
        if(8 <= _routeCount)
        {
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_8ROUTES];
        }
    }
}

- (void) resetRouteCount
{
    _routeCount = 0;
}

- (void) deliveredCargos:(unsigned int)cargos
{
    if(0 == _continueCount)
    {
        if(10 <= cargos)
        {
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_10CARGOS];
        }
        if(50 <= cargos)
        {
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_50CARGOS];
        }
        if(100 <= cargos)
        {
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_100CARGOS];
        }
    }
}

- (void) completeRouteWithFullHealth:(int)playerHealth
{
    if((0 == _continueCount) && ([[PlayerInventory getInstance] curHealthSlots] == playerHealth))
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_FULLHEALTH];
    }
}

- (void) completeGradeAOnRoute:(unsigned int)routeIndex
{
    if(0 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE1A];
    }
    else if(1 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE2A];
    }
    else if(2 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE3A];
    }
    else if(3 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE4A];
    }
    else if(4 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE5A];
    }
    else if(5 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE6A];
    }
    else if(6 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE7A];
    }
    else if(7 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE8A];
    }
    else if(8 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE9A];
    }
    else if(9 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ROUTE10A];
    }
    
    // check if all Routes have been aced
    BOOL completed = YES;
    for(NSString* cur in _routeAchievements)
    {
        AchievementsData* curData = [self getAchievementDataForIdentifier:cur];
        if(![curData isCompleted])
        {
            completed = NO;
            break;
        }
    }
    if(completed)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_ACE];
    }
}

- (void) completeRoute:(unsigned int)routeIndex
{
    // set flyer specific completion achievements
    FlyerType flyerType = [[[GameManager getInstance] playerShip] flyerType];
    switch(flyerType)
    {
        case FlyerTypePograng:
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_POGRANG1ROUTE];
             break;
             
        case FlyerTypePogwing:
            [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_POGWING1ROUTE];
            break;
            
        default:
            // do nothing
            break;             
    }
    
    // set route unlock achievements
    [self unlockRoute:routeIndex];
}

// the unlockRoute function takes the index of the completed-route and unlocks
// the subsequent route
- (void) unlockRoute:(unsigned int)routeIndex
{
    // set route unlock achievements
    if(0 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE2];
    }
    else if(1 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE3];
    }
    else if(2 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE4];
    }
    else if(3 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE5];
    }
    else if(4 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE6];
    }
    else if(5 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE7];
    }
    else if(6 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE8];
    }
    else if(7 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE9];
    }
    else if(8 == routeIndex)
    {
        [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_UNLOCKROUTE10];
    }    
}

- (void) incrFlightTime:(NSTimeInterval)flightTime
{
    unsigned int iTime = static_cast<unsigned int>(flightTime);
    unsigned int mins = (iTime / 60);
    if(40 < (iTime % 60))
    {
        // round up more than 40 seconds to one minute
        mins += 1;
    }
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_30MINS byNum:mins];
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_100MINS byNum:mins];
    [self incrementAchievement:GAMECENTER_ACHIEVEMENT_300MINS byNum:mins];
}

//- (void) tourneyWon
//{
//    [self completeOneShotAchievement:GAMECENTER_ACHIEVEMENT_1TOURNEYWIN];
//}

#pragma mark - private methods
- (AchievementsData*) getAchievementDataForIdentifier:(NSString *)identifier
{
    AchievementsData* result = [[[[StatsManager getInstance] statsData] achievements] objectForKey:identifier];
    if(!result)
    {
        AchievementRegEntry* info = [_achievementsRegistry objectForKey:identifier];
        AchievementsData* newData = [[AchievementsData alloc] initWithIdentifier:identifier 
                                                                     targetValue:[info targetValue]];
        [[[[StatsManager getInstance] statsData] achievements] setObject:newData forKey:identifier];
        result = newData;
        [newData release];
    }
    return result;
}

- (void) markAllDirty
{
    NSMutableDictionary* gameLocalAchievements = [[[StatsManager getInstance] statsData] achievements];
    for(NSString* cur in gameLocalAchievements)
    {
        AchievementsData* curData = [gameLocalAchievements objectForKey:cur];
        [curData markDirty];
    }
}

- (void) syncWithGameCenterLoadedAchievements
{
    // mark all local entries as dirty first
    [self markAllDirty];
    
    // then, sync them with loaded Game Center achievements (the sync method unmarks them)
    NSDictionary* gameCenterAchievements = [[GameCenterManager getInstance] achievementsDict];
    NSArray* achievementKeys = [gameCenterAchievements allKeys];
    for(NSString* cur in achievementKeys)
    {
        if([cur isEqualToString:GKACHIEVEMENTS_UNUSED])
        {
            // skip the unused Achievement entry
            // do nothing
        }
        else
        {
            AchievementsData* curData = [self getAchievementDataForIdentifier:cur];
            GKAchievement* curGameCenterAchievement = [gameCenterAchievements objectForKey:cur];
            [curData syncWithGKAchievement:curGameCenterAchievement];
        }
    }
}

#pragma mark - GameCenterManagerDelegate
- (void) finishedLoadingGameCenterAchievements
{
    [self syncWithGameCenterLoadedAchievements];
}


#pragma mark - Singleton
static AchievementsManager* singleton = nil;
+ (AchievementsManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[AchievementsManager alloc] init] retain];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singleton release];
		singleton = nil;
	}
}


@end
