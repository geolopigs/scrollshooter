//
//  DebugMenu.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/20/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEventDelegate.h"
#if defined(DEBUG)
@interface DebugMenu : UIViewController<AppEventDelegate>
{
    IBOutlet UISwitch* playerInvincibleOnOff;
    IBOutlet UISwitch* colOutlineOnOff;
    IBOutlet UISwitch *noEnemiesOnOff;
    IBOutlet UISwitch* unlockAllLevelsOnOff;
    IBOutlet UISwitch *_unlockFlyersOnOff;
}
- (IBAction)backButtonPressed:(id)sender;
- (IBAction)resetHighscorePressed:(id)sender;
- (IBAction)clearPiggybankPressed:(id)sender;
- (IBAction)addToPiggybankPressed:(id)sender;
- (IBAction)resetGameCenterAchievementsPressed:(id)sender;
- (IBAction)resetGameAchievementsPressed:(id)sender;
- (IBAction)upgradeWeapon:(id)sender;
- (IBAction)resetWeapon:(id)sender;

@end
#endif  // defined(DEBUG)
