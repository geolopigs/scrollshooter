//
//  FlyerLaser.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/21/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "FlyerLaser.h"
#import "FlyerWeapon.h"
#import "Player.h"
#import "FiringPath.h"
#import "BossWeapon.h"
#import "SoundManager.h"
#import "PlayerInventory.h"
#import "PlayerInventoryIds.h"

@implementation FlyerLaser

- (id) init
{
    self = [super init];
    if(self)
    {
        _curPrimary = 0;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

#pragma mark - FlyerWeaponDelegate
- (unsigned int) getInventoryWeaponLevel
{
    unsigned int level = [[PlayerInventory getInstance] curGradeForWeaponGradeKey:UPGRADE_ID_LASER];
    return level;
}

- (BOOL) player:(Player*)player fireWeaponPrimary:(FlyerWeapon*)weapon elapsed:(NSTimeInterval)elapsed;
{
    BOOL fired = NO;
    
    if([weapon primaryWeapon])
    {
        NSArray* primaryWeapon = [weapon primaryWeapon];
        for(BossWeapon* cur in primaryWeapon)
        {
            fired = [cur playerFire:player elapsed:elapsed];  
        }
    }
    
    return fired;
}

- (BOOL) player:(Player *)player fireWeaponSecondary:(FlyerWeapon *)weapon elapsed:(NSTimeInterval)elapsed
{
    BOOL shotsFired = NO;
    if([weapon secondaryWeapon])
    {
        shotsFired = [weapon.secondaryWeapon playerFire:player elapsed:elapsed];  
        if(shotsFired)
        {
            // play sound
            [[SoundManager getInstance] playClip:@"MissileHiss"];
        }
    }
    return shotsFired;
}

@end
