//
//  PlayerInventory.h
//  PeterPog
//
//  This is the game's primary interface to the Player Inventory saved data
//  the game should not directly manipulate PlayerData
//
//  Created by Shu Chiun Cheah on 1/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "PlayerInventoryDelegate.h"

@class PlayerData;
@interface PlayerInventory : NSObject
{
    NSObject<PlayerInventoryDelegate>* _delegate;
}
@property (nonatomic,retain) NSObject<PlayerInventoryDelegate>* delegate;

// game object initialization methods
- (void) fixupPlayerInventoryForData:(PlayerData*)playerData;

// piggybank
- (unsigned int)curPogcoins;

// weapon upgrades
- (void) upgradeForWeaponGradeKey:(const NSString* const)gradeKey;
- (unsigned int) curGradeForWeaponGradeKey:(const NSString* const)gradeKey;
- (unsigned int) maxForWeaponGradeKey:(const NSString* const)gradeKey;
- (BOOL) isMaxForWeaponGradeKey:(const NSString* const)gradeKey;
- (void) resetForWeaponGradeKey:(const NSString* const)gradeKey;
- (void) upgradeWoodenBullets;
- (unsigned int) curWoodenBullets;
- (BOOL) isMaxWoodenBullets;
- (void) resetWoodenBullets;

- (unsigned int) curBombSlots;
- (void) resetBombSlots;
- (unsigned int) curHealthSlots;
- (void) resetHealthSlots;

// single-use
- (unsigned int) curNumBombs;
- (void) clearNumBombs;
- (BOOL) hasCargoMagnet;
- (void) clearCargoMagnet;

// multiplayer utils
- (BOOL) hasMultiplayerUtil:(const NSString* const)utilId;
- (BOOL) hasAnyMultiplayerUtil;
- (void) clearMultiplayerUtil:(const NSString* const)utilId;
- (void) clearAllMultiplayerUtils;

// flyers
- (BOOL) doesHangarHaveFlyer:(const NSString* const)flyerIdentifier;

// free coins
- (unsigned int) getNumFreeCoinPacksRemaining;

// transactions
- (void) buyItemWithCategory:(NSString*)category 
                  identifier:(NSString*)identifier 
                   withPrice:(unsigned int)price;
- (void) recordReceiptForTransaction:(SKPaymentTransaction*)transaction;
- (void) addPogcoins:(unsigned int)addAmount;
- (void) addPogcoinsInt:(int)amount;
- (void) buyFlyerWithIdentifier:(NSString*)identifier;

// for testing purposes
- (void) resetHangar;

// singleton
+(PlayerInventory*) getInstance;
+(void) destroyInstance;

@end
