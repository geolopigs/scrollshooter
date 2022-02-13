//
//  ScoreHud.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StatsManagerUIDelegate.h"
#import "GameHudDelegate.h"

@class FadeController;
@class PogUISlotBar;
@class TourneyMessageView;
@interface ScoreHud : UIViewController<StatsManagerUIDelegate,GameHudDelegate>
{
    IBOutlet UILabel* scoreEntry;
    IBOutlet UILabel *tourneyScoreEntry;

    IBOutlet UIView *achievementsView;
    IBOutlet UILabel *achievementName;
    FadeController* _achievementsViewFade;
    
    // kill bullets power
    IBOutlet PogUISlotBar *_bombSlots;
    IBOutlet UIView *_bombSlotsView;
    
    // health bar
    IBOutlet UIImageView *_healthPackIcon;
    IBOutlet PogUISlotBar* _healthBar;
    FadeController* _healthBarFade;
    BOOL _doHealthBarBlink;
    
    // cargo bar
    IBOutlet UIView *_cargoMultiplierView;
    IBOutlet PogUISlotBar *_cargoMultiplierBar;
    IBOutlet UIView *_cargoMultiplierBarCover;
    IBOutlet UILabel *_multiplierLabel;
    IBOutlet UILabel *_multiplierHighlight;
    IBOutlet UILabel *_scoreHighlight;
    FadeController* _multiplierLabelFade;
    FadeController* _cargoMultiplierFade;
    
    // level label
    IBOutlet UILabel* levelLabel;
    float levelLabelFontSize;
    float levelLabelFade;
    float levelLabelTimer;
    IBOutlet UILabel *countdownLabel;
    float countdownLabelFontSize;
    FadeController* _countdownFadeController;
    
    // alert message
    IBOutlet UIView* messageView;
    IBOutlet UILabel* messageLabel;
    float messageLabelFade;
    BOOL    willShowMessage;    // TRUE will show message if message is hidden; FALSE will dismiss message if message is not hidden;
    
    // tourney
    TourneyMessageView* _tourneyMessage;
    TourneyMessageView* _tourneySentMessage;
    
    // loading screen
    IBOutlet UIView* loadingScreenView;
    IBOutlet UIImageView *loadingScreenImageView;
}
@property (nonatomic,retain) FadeController* achievementsViewFade;
@property (nonatomic,assign) FadeController* multiplierLabelFade;
@property (nonatomic,retain) FadeController* countdownFadeController;
@property (nonatomic,retain) UILabel* levelLabel;
@property (nonatomic,retain) UIView* messageView;
@property (nonatomic,retain) UILabel* messageLabel;

- (void) hideForLevelCompletion;
- (void) unhideForLevelCompletion;
- (void) fadeInNoImageLoading:(float)duration delay:(float)delay;
- (void) fadeInLoading:(float)duration;
- (void) fadeOutLoading:(float)duration;
- (void) useTourneyScoreHudEntry;

- (void) setupTourneyComponents;
@end
