//
//  FlyerWeapon.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/19/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "FlyerWeapon.h"
#import "BossWeapon.h"
#import "FiringPath.h"
#import "SoundManager.h"

@interface FlyerWeapon (PrivateMethods)
- (void) equipCurPrimaryWeapon;
- (void) equipCurSecondaryWeapon;
@end

@implementation FlyerWeapon
@synthesize primaryPool = _primaryPool;
@synthesize secondaryPool = _secondaryPool;
@synthesize primaryConfig = _primaryConfig;
@synthesize secondaryConfig = _secondaryConfig;
@synthesize primaryWeapon = _primaryWeapon;
@synthesize secondaryWeapon = _secondaryWeapon;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    if(self)
    {
        _primaryPool = [[NSMutableSet set] retain];
        _secondaryPool = [[NSMutableSet set] retain];
        _primaryConfig = [[NSMutableArray array] retain];
        _secondaryConfig = [[NSMutableArray array] retain];
        _primaryWeapon = nil;
        _secondaryWeapon = nil;
        _curLevel = 0;
        _delegate = nil;
    }
    return self;
}

- (void) dealloc
{
    [_delegate release];
    [_secondaryWeapon release];
    [_primaryWeapon release];
    [_secondaryConfig release];
    [_primaryConfig release];
    [_secondaryPool release];
    [_primaryPool release];
    [super dealloc];
}

- (void) equipCurPrimaryWeapon
{
    if([self.primaryConfig objectAtIndex:_curLevel] == [NSNull null])
    {
        self.primaryWeapon = nil;
    }
    else
    {
        self.primaryWeapon = [self.primaryConfig objectAtIndex:_curLevel];
        for(id cur in [self primaryWeapon])
        {
            if([cur isMemberOfClass:[BossWeapon class]])
            {
                [cur reset];
            }
        }
    }
}

- (void) equipCurSecondaryWeapon
{
    if([self.secondaryConfig objectAtIndex:_curLevel] == [NSNull null])
    {
        self.secondaryWeapon = nil;
    }
    else
    {
        self.secondaryWeapon = [self.secondaryConfig objectAtIndex:_curLevel];
    }
}

- (BOOL) isPrimaryAtMax
{
    BOOL result = ((_curLevel + 1) == [self.primaryConfig count]);
    return result;
}

- (BOOL) isSecondaryAtMax
{
    BOOL result = ((_curLevel +1 ) == [self.secondaryConfig count]);
    return result;
}

- (unsigned int) getResetLevel
{
    unsigned int result = 0;
    if([self delegate])
    {
        result = [self.delegate getInventoryWeaponLevel];
    }
    return result;
}

- (void) resetWeaponLevel
{
    _curLevel = [self getResetLevel];
    [self equipCurPrimaryWeapon];
    [self equipCurSecondaryWeapon];
}

- (void) upgradeWeaponLevel
{
    int nextLevel = _curLevel + 1;
    if((nextLevel < [self.primaryConfig count]) && (nextLevel < [self.secondaryConfig count]))
    {
        _curLevel = nextLevel;
        [self equipCurPrimaryWeapon];
        [self equipCurSecondaryWeapon];
    }
}

- (unsigned int) curLevel
{
    return _curLevel;
}

- (void) setCurLevel:(unsigned int)curLevel
{
    if(curLevel >= [self.primaryConfig count])
    {
        curLevel = [self.primaryConfig count] - 1;
    }
    if(curLevel >= [self.secondaryConfig count])
    {
        curLevel = [self.secondaryConfig count] - 1;
    }
    _curLevel = curLevel;
    [self equipCurPrimaryWeapon];
    [self equipCurSecondaryWeapon];
}

- (void) update:(NSTimeInterval)elapsed
{
    for(BossWeapon* curSec in [self secondaryPool])
    {
        [curSec playerUpdateWeapon:elapsed];
    }
    for(id cur in [self primaryPool])
    {
        if([cur isMemberOfClass:[FiringPath class]])
        {
            [cur update:elapsed];
        }
        else if([cur isMemberOfClass:[BossWeapon class]])
        {
            [cur playerUpdateWeapon:elapsed];
        }
    }
}

- (BOOL) player:(Player*)player firePrimary:(NSTimeInterval)elapsed
{
    BOOL fired = NO;
    
    if([self primaryWeapon])
    {
        if([self delegate])
        {
            fired = [self.delegate player:player fireWeaponPrimary:self elapsed:elapsed];
        }
        else
        {
            for(FiringPath* cur in [self primaryWeapon])
            {
                BOOL curFired = [cur player:player fire:elapsed];
                fired = (fired || curFired);
            }
        }
    }
    
    return fired;
}

- (BOOL) player:(Player*)player fireSecondary:(NSTimeInterval)elapsed
{
    BOOL shotsFired = NO;
    if([self delegate])
    {
        shotsFired = [self.delegate player:player fireWeaponSecondary:self elapsed:elapsed];
    }
    return shotsFired;
}

- (void) addDraw
{
    // draw all firing paths so that shots don't just disappear or pop-in when weapons are switched
    for(id cur in [self primaryPool])
    {
        if([cur isMemberOfClass:[FiringPath class]])
        {
            [cur addDraw];
        }
        // else non-FiringPath weapons know how to add themselves to draw; so, no need to do it here
    }
}

- (void) removeAllShots
{
    for(id cur in [self primaryPool])
    {
        if([cur isMemberOfClass:[FiringPath class]])
        {
            [cur removeAllShots];
        }
        else if([cur isMemberOfClass:[BossWeapon class]])
        {
            [cur killAllMissiles];
            [cur killAllComponents];
        }
    }
    
    for(BossWeapon* curSec in [self secondaryPool])
    {
        [curSec killAllMissiles];
        [curSec killAllComponents];
    }
}
@end
