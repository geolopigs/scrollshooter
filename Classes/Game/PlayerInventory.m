//
//  PlayerInventory.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PlayerInventory.h"
#import "StatsManager.h"
#import "PlayerData.h"
#import "PlayerInventoryIds.h"
#import "StoreManager.h"
#import "StatsManager.h"
#import "StatsData.h"
#import "LevelManager.h"
#import "AchievementsManager.h"
#import "PogAnalytics+PeterPog.h"
#if defined(DEBUG)
#import "DebugOptions.h"
#endif

static NSString* const PLAYERINVENTORY_JOURNEY_ENVNAME = @"Homebase";   // for UnlockNextRoute store items, always assume Homebase
                                                                        // as of 03/29/2012, Homebase is the only Journey env
static NSString* const POGCERTIFIED_STRING = @"PogCertified";

// max levels
static const unsigned int WEAPONGRADE_MAX = 4;  // player inventory MAX is inclusive;
                                                // so, for 5 weapon upgrade levels, it's 4, as in (0, 1, 2, 3, 4);
static const unsigned int BOMBSLOTS_MIN = 1;    // this is zero-based; so, it's 2 bomb slots;
static const unsigned int BOMBSLOTS_MAX = 5;
static const unsigned int HEALTHSLOTS_MIN = 2;  // this is the initial value (zero based); so, it's 3 healthslots
static const unsigned int HEALTHSLOTS_MAX = 5;

@interface PlayerInventory ()
- (NSMutableDictionary*) playerInventoryData;
- (NSMutableDictionary*) playerHangarData;
- (PlayerData*) playerData;
- (void) setInventoryLevel:(unsigned int)newLevel forIdentifier:(const NSString* const)identifier;
@end

@implementation PlayerInventory
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _delegate = nil;
    }
    return self;
}

- (void) dealloc
{
    [_delegate release];
    [super dealloc];
}

- (NSMutableDictionary*) playerInventoryData
{
    return [[[StatsManager getInstance] playerData] inventory];
}

- (NSMutableDictionary*) playerHangarData
{
    return [[[StatsManager getInstance] playerData] hangar];
}

- (PlayerData*) playerData
{
    return [[StatsManager getInstance] playerData];
}

// use this on a newly created inventory or a newly loaded inventory to fill in an init-value
// if an entry for this Item does not already exist
- (void) inventory:(NSMutableDictionary*)inventory initItemIdentifier:(const NSString *const)identifier withValue:(unsigned int)value
{
    if(nil == [inventory objectForKey:identifier])
    {
        [inventory setObject:[NSNumber numberWithUnsignedInt:value] forKey:identifier];
    }
}

- (void) setInventoryLevel:(unsigned int)newLevel forIdentifier:(const NSString *const)identifier
{
    NSMutableDictionary* inventory = [self playerInventoryData];
    if([inventory objectForKey:identifier])
    {
        [inventory setObject:[NSNumber numberWithUnsignedInt:newLevel] forKey:identifier];
    }
}

#pragma mark - game object initialization methods
// fixup the inventory dictionary in PlayerData such that it has all the latest entries
- (void) fixupPlayerInventoryForData:(PlayerData *)playerData
{
    NSMutableDictionary* inventory = [playerData inventory];
    
    // upgrades
    [self inventory:inventory initItemIdentifier:UPGRADE_ID_WOODENBULLETS withValue:0];
    [self inventory:inventory initItemIdentifier:UPGRADE_ID_LASER withValue:0];
    [self inventory:inventory initItemIdentifier:UPGRADE_ID_BOOMERANG withValue:0];
    [self inventory:inventory initItemIdentifier:UPGRADE_ID_BOMBSLOTS withValue:BOMBSLOTS_MIN];
    [self inventory:inventory initItemIdentifier:UPGRADE_ID_HEALTHSLOTS withValue:HEALTHSLOTS_MIN];
    
    // utilities
    [self inventory:inventory initItemIdentifier:UTILITY_ID_ADDBOMB withValue:0];
    [self inventory:inventory initItemIdentifier:UTILITY_ID_CARGOMAGNET withValue:0];
    
    // multiplayer utils
    [self inventory:inventory initItemIdentifier:MULTIPLAYERUTIL_ID_DARKCLOUDS withValue:0];
    [self inventory:inventory initItemIdentifier:MULTIPLAYERUTIL_ID_FIREWORKS withValue:0];
    [self inventory:inventory initItemIdentifier:MULTIPLAYERUTIL_ID_MUTE withValue:0];
    
    // freecoins
    [self inventory:inventory initItemIdentifier:FREECOINS_ID_TWEETCOINS withValue:0];
    [self inventory:inventory initItemIdentifier:FREECOINS_ID_FBCOINS withValue:0];
}

#pragma mark - piggybank
- (unsigned int)curPogcoins
{
    return [[[StatsManager getInstance] playerData] pogCoins];
}

#pragma mark - weapon upgrades
- (void) upgradeForWeaponGradeKey:(const NSString* const)gradeKey
{
    if(![self isMaxForWeaponGradeKey:gradeKey])
    {
        // special cases where data are not stored in playerInventoryData
        NSString* itemIdentifier = [NSString stringWithFormat:@"%@", gradeKey];
        if([UPGRADE_ID_UNLOCKNEXTROUTE isEqualToString:itemIdentifier])
        {
            unsigned int curLevel = [self curGradeForWeaponGradeKey:gradeKey];
            [[[StatsManager getInstance] statsData] setHasCompleted:YES forEnv:PLAYERINVENTORY_JOURNEY_ENVNAME level:curLevel];
            
            // report achievement
            [[AchievementsManager getInstance] unlockRoute:curLevel];
            [[AchievementsManager getInstance] reportAchievementsToGameCenter];

            // analytics
            [[PogAnalytics getInstance] logRoutePurchasedForRoute:curLevel];
        }
        else 
        {
            unsigned int newGrade = [self curGradeForWeaponGradeKey:gradeKey]+1;
            [self.playerInventoryData setObject:[NSNumber numberWithUnsignedInt:newGrade] forKey:gradeKey];
        }
        
        // analytics
        [[PogAnalytics getInstance] logPogshopPurchase:gradeKey];
    }
}

- (unsigned int) curGradeForWeaponGradeKey:(const NSString* const)gradeKey
{
    unsigned int result = 0;

    // special cases where data not stored in playerInventoryData
    NSString* itemIdentifier = [NSString stringWithFormat:@"%@", gradeKey];
    if([UPGRADE_ID_UNLOCKNEXTROUTE isEqualToString:itemIdentifier])
    {
        result = [[StatsManager getInstance] nextIncompleteLevelForEnv:PLAYERINVENTORY_JOURNEY_ENVNAME];
    }
    else 
    {
        // general case: playerInventoryData
        NSNumber* curGrade = [self.playerInventoryData objectForKey:gradeKey];
        if(curGrade)
        {
            result = [curGrade unsignedIntValue];
        }        
    }
    return result;
}

- (unsigned int) maxForWeaponGradeKey:(const NSString *const)gradeKey
{
    unsigned int max = 0;
    NSString* itemIdentifier = [NSString stringWithFormat:@"%@", gradeKey];
    if(([UPGRADE_ID_WOODENBULLETS isEqualToString:itemIdentifier]) ||
       ([UPGRADE_ID_LASER isEqualToString:itemIdentifier]) ||
       ([UPGRADE_ID_BOOMERANG isEqualToString:itemIdentifier]))
    {
        // weapon trees
        max = WEAPONGRADE_MAX;
    }
    else if([UPGRADE_ID_BOMBSLOTS isEqualToString:itemIdentifier])
    {
        max = BOMBSLOTS_MAX;
    }
    else if([UPGRADE_ID_HEALTHSLOTS isEqualToString:itemIdentifier])
    {
        max = HEALTHSLOTS_MAX;
    }
    else if(([UTILITY_ID_ADDBOMB isEqualToString:itemIdentifier])||
            ([UTILITY_ID_CARGOMAGNET isEqualToString:itemIdentifier]))
    {
        // this is a single-use on/off item
        max = 1;
    }
    else if(([MULTIPLAYERUTIL_ID_DARKCLOUDS isEqualToString:itemIdentifier]) ||
            ([MULTIPLAYERUTIL_ID_FIREWORKS isEqualToString:itemIdentifier]) ||
            ([MULTIPLAYERUTIL_ID_MUTE isEqualToString:itemIdentifier]))
    {
        // multiplayer utils are single-use
        max = 1;
    }
    else if(([FREECOINS_ID_TWEETCOINS isEqualToString:itemIdentifier])||
            ([FREECOINS_ID_FBCOINS isEqualToString:itemIdentifier]))
    {
        // free coins, you only get them once, period.
        max = 1;
    }
    else if([UPGRADE_ID_UNLOCKNEXTROUTE isEqualToString:itemIdentifier])
    {
        max = [[LevelManager getInstance] getNumLevelsForEnv:PLAYERINVENTORY_JOURNEY_ENVNAME];
        max -= 1;   // minus 1 because inventory level range is inclusive (so, 0 - 9 for 9 levels to unlock plus 1 already unlocked)
    }
    return max;
}

- (BOOL) isMaxForWeaponGradeKey:(const NSString *const)gradeKey
{
    unsigned int max = [self maxForWeaponGradeKey:gradeKey];
    BOOL result = NO;
    if([self curGradeForWeaponGradeKey:gradeKey] >= max)
    {
        result = YES;
    }
    return result;
}

- (void) resetForWeaponGradeKey:(const NSString* const)gradeKey
{
    [self setInventoryLevel:0 forIdentifier:gradeKey];
}

#pragma mark - weapon specific methods

- (void) upgradeWoodenBullets
{
    [self upgradeForWeaponGradeKey:UPGRADE_ID_WOODENBULLETS];
}

- (unsigned int) curWoodenBullets
{
    unsigned int result = [self curGradeForWeaponGradeKey:UPGRADE_ID_WOODENBULLETS];
    return result;
}

- (BOOL) isMaxWoodenBullets
{
    BOOL result = [self isMaxForWeaponGradeKey:UPGRADE_ID_WOODENBULLETS];
    return result;
}

- (void) resetWoodenBullets
{
    [self resetForWeaponGradeKey:UPGRADE_ID_WOODENBULLETS];
}

- (unsigned int) curBombSlots
{
    // plus 1 because upgrade-level is 0-based
    unsigned int result = [self curGradeForWeaponGradeKey:UPGRADE_ID_BOMBSLOTS] + 1;
    return result;
}

- (void) resetBombSlots
{
    [self setInventoryLevel:BOMBSLOTS_MIN forIdentifier:UPGRADE_ID_BOMBSLOTS];
}

- (unsigned int) curHealthSlots
{
    // plus 1 because upgrade-level is 0-based
    unsigned int result = [self curGradeForWeaponGradeKey:UPGRADE_ID_HEALTHSLOTS] + 1;
    return result;
}

- (void) resetHealthSlots
{
    [self setInventoryLevel:HEALTHSLOTS_MIN forIdentifier:UPGRADE_ID_HEALTHSLOTS];
}

#pragma mark - single use

- (unsigned int) curNumBombs
{
    unsigned int result = 0;
    if(0 < [self curGradeForWeaponGradeKey:UTILITY_ID_ADDBOMB])
    {
        // if user purchased ADDBOMB single-use, fill up all the bomb slots
        result = [self curBombSlots];
    }
    return result;
}

- (void) clearNumBombs
{
    [self setInventoryLevel:0 forIdentifier:UTILITY_ID_ADDBOMB];
}

- (BOOL) hasCargoMagnet
{
    BOOL result = NO;
    
    if(0 < [self curGradeForWeaponGradeKey:UTILITY_ID_CARGOMAGNET])
    {
        result = YES;
    }
    return result;
}

- (void) clearCargoMagnet
{
    [self setInventoryLevel:0 forIdentifier:UTILITY_ID_CARGOMAGNET];
}

#pragma mark - multiplayer utils
- (BOOL) hasMultiplayerUtil:(const NSString *const)utilId
{
    BOOL result = NO;
    if(0 < [self curGradeForWeaponGradeKey:utilId])
    {
        result = YES;
    }
    return result;
}

- (BOOL) hasAnyMultiplayerUtil
{
    BOOL result = NO;
    if(([self hasMultiplayerUtil:MULTIPLAYERUTIL_ID_DARKCLOUDS]) ||
       ([self hasMultiplayerUtil:MULTIPLAYERUTIL_ID_FIREWORKS]) ||
       ([self hasMultiplayerUtil:MULTIPLAYERUTIL_ID_MUTE]))
    {
        result = YES;
    }
    return result;
}

- (void) clearMultiplayerUtil:(const NSString *const)utilId
{
    [self setInventoryLevel:0 forIdentifier:utilId];
}

- (void) clearAllMultiplayerUtils
{
    [self setInventoryLevel:0 forIdentifier:MULTIPLAYERUTIL_ID_DARKCLOUDS];
    [self setInventoryLevel:0 forIdentifier:MULTIPLAYERUTIL_ID_FIREWORKS];
    [self setInventoryLevel:0 forIdentifier:MULTIPLAYERUTIL_ID_MUTE];
}

#pragma mark - flyers
- (BOOL) doesHangarHaveFlyer:(const NSString *const)flyerIdentifier
{
    BOOL result = NO;
    
    NSString* flyerId = (NSString*)flyerIdentifier;
    if([flyerId isEqualToString:(NSString*)FLYER_ID_POGLIDER])
    {
        // default poglider is always available
        result = YES;
    }
    else
    {    
        // look into hangar for purchased flyers
        NSMutableDictionary* hangar = [self playerHangarData];
        NSString* flyerValue = [hangar objectForKey:flyerIdentifier];
        if(flyerValue && [flyerValue isEqualToString:POGCERTIFIED_STRING])
        {
            result = YES;
        }
    }
    
#if defined(DEBUG)
    if([[DebugOptions getInstance] areFlyersUnlocked])
    {
        result = YES;
    }
#endif
    
    return result;
}

#pragma mark - free coins
- (unsigned int) getNumFreeCoinPacksRemaining
{
    int result = [[StoreManager getInstance] numItemsForCategory:CATEGORY_ID_FREECOINS];
    
    // minus the ones that player already obtained
    if([self isMaxForWeaponGradeKey:FREECOINS_ID_TWEETCOINS])
    {
        --result;
    }
    if([self isMaxForWeaponGradeKey:FREECOINS_ID_FBCOINS])
    {
        --result;
    }
    if(0 > result)
    {
        result = 0;
    }
    
    return ((unsigned int) result);
}

#pragma mark - transactions

- (void) buyItemWithCategory:(NSString*)category 
                  identifier:(NSString*)identifier
                   withPrice:(unsigned int)price
{
    if(price <= [self curPogcoins])
    {
        // debit piggybank
        int newCoinsAmount = [self curPogcoins] - price;
        [[StatsManager getInstance] commitCoins:newCoinsAmount];
        
        // update inventory
        [self upgradeForWeaponGradeKey:identifier];
        if(_delegate)
        {
            [_delegate playerInventoryDidChange];
        }
    }
}

// record and commit transaction receipt
- (void) recordReceiptForTransaction:(SKPaymentTransaction *)transaction
{
//    [self.playerData.transactionReceipts addObject:[transaction transactionReceipt]];
    [[StatsManager getInstance] savePlayerData];
}

- (void) addPogcoins:(unsigned int)addAmount
{
    unsigned int newAmount = [self curPogcoins] + addAmount;
    [[StatsManager getInstance] commitCoins:newAmount];    
}

- (void) addPogcoinsInt:(int)amount
{
    int cur = [self curPogcoins];
    if((0 > amount) && ((cur + amount) < 0))
    {
        // if negative amount, clamp it at 0
        amount = -cur;
    }    
        
    [[StatsManager getInstance] commitAddCoins:amount];    
}

- (void) buyFlyerWithIdentifier:(NSString *)identifier
{
    NSMutableDictionary* hangar = [self playerHangarData];
    [hangar setObject:POGCERTIFIED_STRING forKey:identifier];
    [[StatsManager getInstance] savePlayerData];
}

#pragma mark - for testing
- (void) resetHangar
{
    NSMutableDictionary* hangar = [self playerHangarData];
    
    // remove the purchasable flyers
    [hangar removeObjectForKey:FLYER_ID_POGWING];
    [hangar removeObjectForKey:FLYER_ID_POGRANG];
}


#pragma mark - Singleton
static PlayerInventory* singleton = nil;
+ (PlayerInventory*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[PlayerInventory alloc] init] retain];
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
