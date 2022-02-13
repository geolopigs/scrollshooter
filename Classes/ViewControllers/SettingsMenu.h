//
//  SettingsMenu.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/29/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsMenuDelegate.h"

@class PogUITextLabel;
@interface SettingsMenu : UIViewController
{
    // border
    IBOutlet UIView *backScrim;
    IBOutlet UIView *border;
    
    IBOutlet UIImageView *soundButtonOn;
    IBOutlet UIImageView *soundButtonOff;
    IBOutlet UIButton *buttonLeaderboards;
    IBOutlet UIButton *buttonAchievements;
    IBOutlet PogUITextLabel *_textLabelStats;
    IBOutlet PogUITextLabel *_textLabelGoals;
    IBOutlet PogUITextLabel *_textLabelMore;
    IBOutlet PogUITextLabel *_textLabelCredits;
    
    NSObject<SettingsMenuDelegate>* _delegate;
}
@property (nonatomic,retain) NSObject<SettingsMenuDelegate>* delegate;

- (IBAction)buttonLeaderboardsPressed:(id)sender;
- (IBAction)buttonCreditsPressed:(id)sender;
- (IBAction)buttonGoalsPressed:(id)sender;
- (IBAction)buttonMorePressed:(id)sender;
@end
