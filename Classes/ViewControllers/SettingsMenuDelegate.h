//
//  SettingsMenuDelegate.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/29/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SettingsMenuDelegate <NSObject>
- (void) handleButtonLeaderboards;
- (void) handleButtonGoals;
- (void) handleButtonCredits;
- (void) handleMore;
- (void) handleFacebook;
@end
