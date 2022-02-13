//
//  StatsManagerUIDelegate.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol StatsManagerUIDelegate <NSObject>
- (void) updateScore:(unsigned int)newScore;
- (void) updateCargo:(unsigned int)newCargo;
- (void) updateHealthBar:(unsigned int)curHealth;
- (void) updateNumKillBullets:(unsigned int)newNum;
- (void) didReceiveNewMultiplier:(unsigned int)newMultiplier hasIncreased:(BOOL)hasIncreased;
@end
