//
//  FlyerWoodenBullets.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/21/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "FlyerWoodenBullets.h"
#import "FlyerWeapon.h"
#import "Player.h"
#import "FiringPath.h"
#import "BossWeapon.h"
#import "SoundManager.h"
#import "PlayerInventory.h"

@implementation FlyerWoodenBullets

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
    unsigned int level = [[PlayerInventory getInstance] curWoodenBullets];
    return level;
}

- (BOOL) player:(Player*)player fireWeaponPrimary:(FlyerWeapon*)weapon elapsed:(NSTimeInterval)elapsed;
{
    BOOL fired = NO;
    
    if([weapon primaryWeapon])
    {
        // alternate weapons 0 and 1
        if(2 <= [weapon.primaryWeapon count])
        {
            FiringPath* cur = [weapon.primaryWeapon objectAtIndex:_curPrimary];
            BOOL curFired = [cur player:player fire:elapsed];
            if(curFired)
            {
                if(_curPrimary)
                {
                    _curPrimary = 0;
                }
                else
                {
                    _curPrimary = 1;
                }
                fired = YES;
            }
            // then fire all of the remaining weapons
            unsigned int index = 2;
            while(index < [weapon.primaryWeapon count])
            {
                FiringPath* cur = [weapon.primaryWeapon objectAtIndex:index];
                BOOL curFired = [cur player:player fire:elapsed];
                fired = (fired || curFired);        
                ++index;
            }
        }
        else if([weapon.primaryWeapon count])
        {
            // single weapon
            FiringPath* cur = [weapon.primaryWeapon objectAtIndex:0];
            BOOL curFired = [cur player:player fire:elapsed];
            fired = (fired || curFired);
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
