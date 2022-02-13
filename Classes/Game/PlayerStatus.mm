//
//  PlayerStatus.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/26/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "PlayerStatus.h"

@implementation PlayerStatus
@synthesize health;
@synthesize missileGrade = _missileGrade;
@synthesize numKillBulletPacks;
@synthesize weaponGrade = _weaponGrade;
@synthesize cargoMagnetRadius = _cargoMagnetRadius;

- (id) init
{
    self = [super init];
    if(self)
    {
        health = 0;
        _missileGrade = 1;
        numKillBulletPacks = 0;
        _weaponGrade = 0;
        _cargoMagnetRadius = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

@end
