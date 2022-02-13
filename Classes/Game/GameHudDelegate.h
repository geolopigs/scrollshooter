//
//  GameHudDelegate.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GameHudDelegate <NSObject>
- (void) showCountdown:(NSString*)text;
- (void) showLevelLabel:(NSString*)name;
- (void) showMessage:(NSString*)text;
- (void) dismissMessage;
- (BOOL) isMessageBeingDisplayed;
- (void) update:(NSTimeInterval)elapsed;
- (void) showAchievementWithName:(NSString*)name;
- (void) setCargoTowardsMultiplier:(unsigned int)num;
- (void) showTourneyMessage:(NSString*)text withIcon:(UIImage*)iconImage;
- (void) showTourneySentMessage:(NSString *)text;

@end
