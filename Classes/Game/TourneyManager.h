//
//  TourneyManager.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/16/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Loot;
@class NPTournamentEndDataContainer;
@interface TourneyManager : NSObject
{
    NSMutableArray* _multiplayerUtilPickups;
    NSDictionary* _tourneyUtilLookup;
    
    // runtime
    float _utilPickupsTimer;
}

// game flow related
- (void) didBeginGameSession;
- (void) didEndGameSession;
- (void) didKillPlayer;

// stats
- (void) didEndTournamentWithResults:(NPTournamentEndDataContainer*)results;

// attacks
- (void) pushAttackForPickup:(Loot*)pickup fromPos:(CGPoint)pos;
- (void) speedUpPickupsTimerBy:(NSTimeInterval)boost;
- (void) spawnAttackPickups;
- (void) updateAttacks:(NSTimeInterval)elapsed;
- (BOOL) isMultiplayerUtilPickup:(NSString*)pickupName;

// singleton
+(TourneyManager*) getInstance;
+(void) destroyInstance;

@end
