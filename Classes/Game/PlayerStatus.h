//
//  PlayerStatus.h
//  PeterPog
//
//  PlayerStatus contains the states that persist on players across levels in a given game session
//
//  Created by Shu Chiun Cheah on 9/26/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayerStatus : NSObject
{
    int health;
    unsigned int numKillBulletPacks;
    unsigned int _weaponGrade;
    float _cargoMagnetRadius;
}
@property (nonatomic,assign) int health;
@property (nonatomic,assign) unsigned int missileGrade;
@property (nonatomic,assign) unsigned int numKillBulletPacks;
@property (nonatomic,assign) unsigned int weaponGrade;
@property (nonatomic,assign) float cargoMagnetRadius;

@end
