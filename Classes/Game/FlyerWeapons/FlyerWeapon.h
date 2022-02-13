//
//  FlyerWeapon.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/19/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlyerWeaponDelegate.h"

@class BossWeapon;
@class Player;
@interface FlyerWeapon : NSObject
{
    NSMutableSet* _primaryPool;
    NSMutableSet* _secondaryPool;
    NSMutableArray* _primaryConfig;     // weapon configs per level
    NSMutableArray* _secondaryConfig;
    
    // runtime
    NSMutableArray* _primaryWeapon;
    BossWeapon* _secondaryWeapon;
    unsigned int _curLevel;
    NSObject<FlyerWeaponDelegate>* _delegate;
}
@property (nonatomic,retain) NSMutableSet* primaryPool;
@property (nonatomic,retain) NSMutableSet* secondaryPool;
@property (nonatomic,retain) NSMutableArray* primaryConfig;
@property (nonatomic,retain) NSMutableArray* secondaryConfig;
@property (nonatomic,retain) NSMutableArray* primaryWeapon;
@property (nonatomic,retain) BossWeapon* secondaryWeapon;
@property (nonatomic,assign) unsigned int curLevel;
@property (nonatomic,retain) NSObject<FlyerWeaponDelegate>* delegate;

- (BOOL) isPrimaryAtMax;
- (BOOL) isSecondaryAtMax;
- (unsigned int) getResetLevel;
- (void) resetWeaponLevel;
- (void) upgradeWeaponLevel;
- (void) update:(NSTimeInterval)elapsed;
- (BOOL) player:(Player*)player firePrimary:(NSTimeInterval)elapsed;
- (BOOL) player:(Player*)player fireSecondary:(NSTimeInterval)elapsed;
- (void) addDraw;
- (void) removeAllShots;

@end
