//
//  TourneyManager.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TourneyManager.h"
#import "GameManager.h"
#import "StatsManager.h"
#import "AchievementsManager.h"
#import "SoundManager.h"
#import "Loot.h"
#import "LootFactory.h"
#import "EffectFactory.h"
#import "PlayerInventoryIds.h"
#import "PlayerInventory.h"
#include "MathUtils.h"

typedef enum
{
    TOURNEY_ATTACK_INVALID = 0,
    TOURNEY_ATTACK_DARKCLOUDS,
    TOURNEY_ATTACK_FIREWORKS,
    TOURNEY_ATTACK_MUTE,
    TOURNEY_ATTACK_NUM = TOURNEY_ATTACK_MUTE,
    
    TOURNEY_ATTACK_RANDOM,
} TourneyAttack;

static const float TOURNEY_UTILPICKUPS_INTERVAL_DEFAULT = 32.0f;
static const float TOURNEY_UTILPICKUPS_INTERVAL_EQUIPPED = 18.0f;
static const float TOURNEY_UTILPICKUPS_INTERVAL_RANDOMOFFSET = 4.0f;

@implementation TourneyManager

- (id) init
{
    self = [super init];
    if(self)
    {
        // multiplayer util pickups
        _multiplayerUtilPickups = [[NSMutableArray array] retain];
        
        _tourneyUtilLookup = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                   [NSNumber numberWithInt:TOURNEY_ATTACK_DARKCLOUDS],
                                                                   [NSNumber numberWithInt:TOURNEY_ATTACK_FIREWORKS],
                                                                   [NSNumber numberWithInt:TOURNEY_ATTACK_MUTE],
                                                                   [NSNumber numberWithInt:TOURNEY_ATTACK_RANDOM],nil] 
                                                          forKeys:[NSArray arrayWithObjects:
                                                                   MULTIPLAYERUTIL_ID_DARKCLOUDS,
                                                                   MULTIPLAYERUTIL_ID_FIREWORKS,
                                                                   MULTIPLAYERUTIL_ID_MUTE,
                                                                   MULTIPLAYERUTIL_ID_RANDOM, nil]] retain];
        _utilPickupsTimer = TOURNEY_UTILPICKUPS_INTERVAL_DEFAULT;
    }
    return self;
}

- (void) dealloc
{
    [_tourneyUtilLookup release];
    [_multiplayerUtilPickups release];
    [super dealloc];
}

#pragma mark - game flow
- (void) didBeginGameSession
{
    if([[PlayerInventory getInstance] hasAnyMultiplayerUtil])
    {
        _utilPickupsTimer = TOURNEY_UTILPICKUPS_INTERVAL_EQUIPPED;
    }
    else
    {
        _utilPickupsTimer = TOURNEY_UTILPICKUPS_INTERVAL_DEFAULT;
    }
}

- (void) didEndGameSession
{
    // clean up any remaining pickups
    for(Loot* cur in _multiplayerUtilPickups)
    {
        if([cur isAlive])
        {
            [cur kill];
        }
    }
    [_multiplayerUtilPickups removeAllObjects];    
}

- (void) didKillPlayer
{
}

#pragma mark - stats
- (void) didEndTournamentWithResults:(NPTournamentEndDataContainer*)results
{
    if(results)
    {
        unsigned int rank = [results playerRankInTournament];
        
        // update Rank#1 stats
        if(rank == 1)
        {
            [[StatsManager getInstance] accTourneyWins:1];
//            [[AchievementsManager getInstance] tourneyWon];
        }
    }
}


#pragma mark - attacks
- (BOOL) isMultiplayerUtilPickup:(NSString *)pickupName
{
    BOOL result = NO;
    
    NSNumber* attackEnum = [_tourneyUtilLookup objectForKey:pickupName];
    if(attackEnum)
    {
        result = YES;
    }
    return result;
}


- (void) tourneyPushAttackForPickupType:(NSString*)pickupType fromPos:(CGPoint)pos
{
    NSNumber* attackEnum = [_tourneyUtilLookup objectForKey:pickupType];
    NSString* attackString = nil;
    NSString* effectName = nil;
    if(attackEnum)
    {
        int selectedAttack = [attackEnum intValue];
        if(TOURNEY_ATTACK_RANDOM == selectedAttack)
        {
            selectedAttack = (arc4random() % TOURNEY_ATTACK_NUM);
            selectedAttack += 1;    // plus one because attack enums are 1 based
        }
        switch(selectedAttack)
        {
            case TOURNEY_ATTACK_DARKCLOUDS:
                attackString = @"Dark Clouds attack sent";
                effectName = MULTIPLAYERUTIL_ID_DARKCLOUDS;
                break;
                
            case TOURNEY_ATTACK_FIREWORKS:
                attackString = @"Fireworks attack sent";
                effectName = MULTIPLAYERUTIL_ID_FIREWORKS;
                break;
                
            case TOURNEY_ATTACK_MUTE:
                attackString = @"Mute Weapon attack sent";
                effectName = MULTIPLAYERUTIL_ID_MUTE;
                break;
        }
        if(attackString)
        {
            // play spawn effect
            NSString* multiplayerEffectName = [NSString stringWithFormat:@"%@Sent",effectName];
            [EffectFactory effectNamed:multiplayerEffectName atPos:pos];
            
            if([[GameManager getInstance] hudDelegate])
            {
                [[[GameManager getInstance] hudDelegate] showTourneySentMessage:attackString];
            }
        }
    }
}

// returns the attackString to be displayed by the caller
- (void) pushAttackForPickup:(Loot *)pickup fromPos:(CGPoint)pos
{
    // dismiss the other multiplayer utils
    for(Loot* cur in _multiplayerUtilPickups)
    {
        if(cur != pickup)
        {
            [cur kill];
        }
    }
    [_multiplayerUtilPickups removeAllObjects];
    
    // play sound
    [[SoundManager getInstance] playClip:@"KillBullets"];

    // wipe out all bullets
    [[GameManager getInstance] killAllBullets:0.5f];
    
    // send the attack
    NSString* pickupName = [[pickup behaviorDelegate] getTypeName];
    [self tourneyPushAttackForPickupType:pickupName fromPos:pos]; 
}

- (void) spawnAttackPickups
{
    // dismiss the other multiplayer utils first
    for(Loot* cur in _multiplayerUtilPickups)
    {
        if([cur isAlive])
        {
            [cur kill];
        }
    }

    // then spawn a new set
    CGSize playAreaSize = [[GameManager getInstance] getPlayArea].size;
    float spamX = playAreaSize.width * 0.3f;
    float spamY = playAreaSize.height * 1.1f;
    float spamSpacing = playAreaSize.width * 0.2f;
    
    unsigned int spawnCount = 0;
    for(NSString* cur in _tourneyUtilLookup)
    {
        if([[PlayerInventory getInstance] hasMultiplayerUtil:cur])
        {
            Loot* multiplayerUtil = nil;
            multiplayerUtil = [LootFactory spawnDynamicLootFromKey:cur 
                                                             atPos:CGPointMake(spamX + (spamSpacing * spawnCount), 
                                                                               spamY)];
            [_multiplayerUtilPickups addObject:multiplayerUtil];   
            ++spawnCount;
        }
    }
    
    if(spawnCount < TOURNEY_ATTACK_NUM)
    {
        CGPoint spawnPos = CGPointMake(spamX + (spamSpacing * spawnCount), spamY);
        if(0 == spawnCount)
        {
            spawnPos.x = 0.5f * playAreaSize.width;
        }
        // if player didn't purchase the full set of utils, spawn a random one
        Loot* multiplayerUtil = nil;
        multiplayerUtil = [LootFactory spawnDynamicLootFromKey:MULTIPLAYERUTIL_ID_RANDOM 
                                                         atPos:spawnPos];
        [_multiplayerUtilPickups addObject:multiplayerUtil];   
        ++spawnCount;            
    }

    if(0 < spawnCount)
    {
        if([[PlayerInventory getInstance] hasAnyMultiplayerUtil])
        {
            _utilPickupsTimer = TOURNEY_UTILPICKUPS_INTERVAL_EQUIPPED;
        }
        else
        {
            _utilPickupsTimer = TOURNEY_UTILPICKUPS_INTERVAL_DEFAULT;
        }
        // adjust next spawn by a random offset
        float adjustment = randomFrac() * TOURNEY_UTILPICKUPS_INTERVAL_RANDOMOFFSET;
        if(0.5f >= randomFrac())
        {
            adjustment = -adjustment;
        }
        _utilPickupsTimer += adjustment;
    }
}

- (void) updateAttacks:(NSTimeInterval)elapsed
{
    _utilPickupsTimer -= elapsed;
    
    if(0.0f >= _utilPickupsTimer)
    {
        [self spawnAttackPickups];
    }
}

- (void) speedUpPickupsTimerBy:(NSTimeInterval)boost
{
    _utilPickupsTimer -= boost;
}

#pragma mark - Singleton
static TourneyManager* singleton = nil;
+ (TourneyManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[TourneyManager alloc] init] retain];
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
