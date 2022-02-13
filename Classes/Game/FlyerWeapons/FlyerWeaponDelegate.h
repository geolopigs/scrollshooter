//
//  FlyerWeaponDelegate.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/21/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Player;
@class FlyerWeapon;
@protocol FlyerWeaponDelegate <NSObject>
- (unsigned int) getInventoryWeaponLevel;
- (BOOL) player:(Player*)player fireWeaponPrimary:(FlyerWeapon*)weapon elapsed:(NSTimeInterval)elapsed;
- (BOOL) player:(Player*)player fireWeaponSecondary:(FlyerWeapon*)weapon elapsed:(NSTimeInterval)elapsed;
@end
