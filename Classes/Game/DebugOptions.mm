//
//  DebugOptions.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/20/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#if defined(DEBUG)

#import "DebugOptions.h"

@implementation DebugOptions
@synthesize isPlayerInvincible;
@synthesize isPlayerMissilesOn;
@synthesize isDebugColOutlineOn;
@synthesize isDebugSpriteOutlineOn;
@synthesize debugNoEnemies = _debugNoEnemies;
@synthesize debugLevelCompletion;
@synthesize debugLevelCompletionTimeout;
@synthesize isAllLevelsUnlocked;
@synthesize areFlyersUnlocked = _areFlyersUnlocked;

- (id) init
{
    self = [super init];
    if(self)
    {
        isPlayerInvincible = NO;
        isPlayerMissilesOn = NO;
        isDebugColOutlineOn = NO;
        isDebugSpriteOutlineOn = NO;
        _debugNoEnemies = NO;
        debugLevelCompletion = NO;
        debugLevelCompletionTimeout = 10.0f;
        isAllLevelsUnlocked = NO;
        _areFlyersUnlocked = NO;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

#pragma mark - UI
- (void) togglePlayerInvincibleOnOff:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        self.isPlayerInvincible = YES;
    }
    else
    {
        self.isPlayerInvincible = NO;
    }
}

- (void) togglePlayerMissilesOnOff:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        self.isPlayerMissilesOn = YES;
    }
    else
    {
        self.isPlayerMissilesOn = NO;
    }
}

- (void) toggleDebugColOutlineOnOff:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        self.isDebugColOutlineOn = YES;
    }
    else
    {
        self.isDebugColOutlineOn = NO;
    }
}

- (void) toggleDebugSpriteOutlineOnOff:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        self.isDebugSpriteOutlineOn = YES;
    }
    else
    {
        self.isDebugSpriteOutlineOn = NO;
    }
}

- (void) toggleDebugNoEnemiesOnOff:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        self.debugNoEnemies = YES;
    }
    else
    {
        self.debugNoEnemies = NO;
    }
}

- (void) toggleDebugLevelCompletion:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        self.debugLevelCompletion = YES;
        self.debugLevelCompletionTimeout = 6.0f;
    }
    else
    {
        self.debugLevelCompletion = NO;
        self.debugLevelCompletionTimeout = 0.0f;
    }
}

- (void) toggleAllLevelsUnlocked:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        self.isAllLevelsUnlocked = YES;
    }
    else
    {
        self.isAllLevelsUnlocked = NO;
    }
}

- (void) toggleFlyersUnlocked:(id)sender
{
    UISwitch* switchButton = sender;
    if([switchButton isOn])
    {
        self.areFlyersUnlocked = YES;
    }
    else
    {
        self.areFlyersUnlocked = NO;
    }
}

#pragma mark - Singleton
static DebugOptions* singleton = nil;
+ (DebugOptions*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[DebugOptions alloc] init] retain];
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

#endif