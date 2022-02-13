//
//  GameOverScreen.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GameOverScreenDelegate <NSObject>
- (void) dismissGameOverScreen;
- (void) gotoStore;
- (void) gotoStats;
- (void) gotoGoals;
- (void) continueGame;
@end

@class PogUITextLabel;
@interface GameOverScreen : UIViewController<UIAlertViewDelegate>
{
    NSObject<GameOverScreenDelegate>* _delegate;
    IBOutlet UIView *backScrim;
    IBOutlet UIView *border;
    IBOutlet UIView *_contentView;
    
    IBOutlet UIButton *_twitterButton;
    IBOutlet UILabel *_cargosDeliveredLabel;
    IBOutlet UILabel *_flightTimeLabel;
    IBOutlet UILabel *_pogcoinsLabel;
    IBOutlet UILabel *_scoreLabel;
    IBOutlet UILabel *_newHighscoreLabel;
    IBOutlet UIView *_coinsView;
    IBOutlet UIView *_flightTimeView;
    IBOutlet UIView *_cargosView;
    IBOutlet PogUITextLabel *_textLabelStats;
    IBOutlet PogUITextLabel *_textLabelGoals;
    IBOutlet UIView *_continueButtonView;
    IBOutlet UILabel *_continuePriceLabel;
    IBOutlet UIView *_moreCoinsButtonView;
    IBOutlet UIView *_exitButtonView;
}
@property (nonatomic,retain) NSObject<GameOverScreenDelegate>* delegate;
@property (nonatomic,retain) UIView* contentView;

- (IBAction)buttonExitPressed:(id)sender;
- (IBAction)buttonStorePressed:(id)sender;
- (IBAction)twitterButtonPressed:(id)sender;
- (IBAction)buttonGoalsPressed:(id)sender;
- (IBAction)buttonStatsPressed:(id)sender;
- (IBAction)buttonContinuePressed:(id)sender;
- (IBAction)buttonGetMoreCoinsPressed:(id)sender;
- (IBAction)buttonExitToMainMenuPressed:(id)sender;

@end
