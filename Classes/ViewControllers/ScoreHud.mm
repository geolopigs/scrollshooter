//
//  ScoreHud.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "ScoreHud.h"
#import "StatsManager.h"
#import "FadeController.h"
#import "Texture.h"
#import "GameModes.h"
#import "GameManager.h"
#import "PogUISlotBar.h"
#import "PlayerInventory.h"
#import "TourneyMessageView.h"
#include "MathUtils.h"
#import <QuartzCore/QuartzCore.h>

static const float LEVELLABEL_FADERATE = 1.5f;  // alpha step per second
static const float LEVELLABEL_TIMEOUT = 1.0f;
static const float MESSAGE_FADERATE = 2.0f;

enum CARGOS_FADESTATE 
{
    CARGOS_FADESTATE_IDLE = 0,
    CARGOS_FADESTATE_HIDDEN,
    CARGOS_FADESTATE_FADEIN,
    CARGOS_FADESTATE_FULLYVISIBLE,
    CARGOS_FADESTATE_FADEOUT,
    
    CARGOS_FADESTATE_NUM
};

@interface ScoreHud (PrivateMethods)
- (void) updateFades:(NSTimeInterval)elapsed;
- (void) setupCargoBars;
- (void) setupHealthBar;
- (void) setupBombSlots;
@end

@implementation ScoreHud
@synthesize achievementsViewFade = _achievementsViewFade;
@synthesize multiplierLabelFade = _multiplierLabelFade;
@synthesize countdownFadeController = _countdownFadeController;
@synthesize levelLabel;
@synthesize messageView;
@synthesize messageLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        willShowMessage = NO;
        _multiplierLabelFade = [[FadeController alloc] initWithFadeDur:0.2f visibleDur:0.3f];
        _cargoMultiplierFade = [[FadeController alloc] initWithFadeDur:0.2f visibleDur:1.0f];
        _achievementsViewFade = [[FadeController alloc] initWithFadeDur:0.3f visibleDur:1.0f];
        _countdownFadeController = [[FadeController alloc] initWithFadeDur:0.2f visibleDur:0.4f];
        _healthBarFade = [[FadeController alloc] initWithFadeDur:0.2f visibleDur:0.2f];
        _doHealthBarBlink = NO;
        _tourneyMessage = nil;
    }
    return self;
}

- (void) dealloc
{
    if(_tourneyMessage)
    {
        [_tourneyMessage removeFromSuperview];
        [_tourneyMessage release];
    }
    [_healthBarFade release];
    self.countdownFadeController = nil;
    [_cargoMultiplierFade release];
    self.multiplierLabelFade = nil;
    self.achievementsViewFade = nil;
    [achievementsView release];
    [achievementName release];
    [loadingScreenImageView release];
    [tourneyScoreEntry release];
    [scoreEntry release];
    [countdownLabel release];
    [_cargoMultiplierBar release];
    [_cargoMultiplierBarCover release];
    [_multiplierLabel release];
    [_multiplierHighlight release];
    [_scoreHighlight release];
    [_cargoMultiplierView release];
    [_healthBar release];
    [_bombSlots release];
    [_bombSlotsView release];
    [_healthPackIcon release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // setup fonts
    levelLabelFontSize = levelLabel.font.pointSize;
    UIFont* peter2 = [UIFont fontWithName:@"effigy" size:levelLabelFontSize];
    levelLabel.font = peter2;
    countdownLabelFontSize = countdownLabel.font.pointSize;
    UIFont* countdownFont = [UIFont fontWithName:@"effigy" size:countdownLabelFontSize];
    countdownLabel.font = countdownFont;
    
    // init the cargos and score entries on the UI
    unsigned int score = [[StatsManager getInstance] pointsCurLevel];
    scoreEntry.text = [NSString stringWithFormat:@"%d", score];
    _scoreHighlight.text = [NSString stringWithFormat:@"%d", score];
    tourneyScoreEntry.text = [NSString stringWithFormat:@"%d", score];
    unsigned int multiplier = [[StatsManager getInstance] sessionMultiplier];
    _multiplierLabel.text = [NSString stringWithFormat:@"x%d", multiplier];
    
    // setup kill bullets
    [self setupBombSlots];
    
    // setup cargo-multiplier bar
    [self setupCargoBars];
    
    // setup healthbar
    [self setupHealthBar];
    
    // hide all hud labels by default
    _cargoMultiplierView.hidden = YES;
    _multiplierHighlight.hidden = YES;
    _scoreHighlight.hidden = YES;
    countdownLabel.hidden = YES;
    levelLabel.hidden = YES;
    messageView.hidden = YES;
    messageLabel.hidden = YES;
    willShowMessage = NO;
    loadingScreenView.hidden = YES;
    achievementsView.hidden = YES;
    
    scoreEntry.hidden = NO;
    tourneyScoreEntry.hidden = YES;
    _tourneyMessage = nil;
    _tourneySentMessage = nil;
}

- (void)viewDidUnload
{
    if(_tourneySentMessage)
    {
        [_tourneySentMessage removeFromSuperview];
        [_tourneySentMessage release];
        _tourneySentMessage = nil;
    }
    if(_tourneyMessage)
    {
        [_tourneyMessage removeFromSuperview];
        [_tourneyMessage release];
        _tourneyMessage = nil;
    }
    [_healthBarFade release];
    _healthBarFade = nil;
    self.countdownFadeController = nil;
    [_cargoMultiplierFade release];
    _cargoMultiplierFade = nil;
    self.multiplierLabelFade = nil;
    self.achievementsViewFade = nil;
    [achievementsView release];
    achievementsView = nil;
    [achievementName release];
    achievementName = nil;
    [loadingScreenImageView release];
    loadingScreenImageView = nil;
    [tourneyScoreEntry release];
    tourneyScoreEntry = nil;
    [scoreEntry release];
    scoreEntry = nil;
    [countdownLabel release];
    countdownLabel = nil;
    [_cargoMultiplierBar release];
    _cargoMultiplierBar = nil;
    [_cargoMultiplierBarCover release];
    _cargoMultiplierBarCover = nil;
    [_multiplierLabel release];
    _multiplierLabel = nil;
    [_multiplierHighlight release];
    _multiplierHighlight = nil;
    [_scoreHighlight release];
    _scoreHighlight = nil;
    [_cargoMultiplierView release];
    _cargoMultiplierView = nil;
    [_healthBar release];
    _healthBar = nil;
    [_bombSlots release];
    _bombSlots = nil;
    [_bombSlotsView release];
    _bombSlotsView = nil;
    [_healthPackIcon release];
    _healthPackIcon = nil;
    [super viewDidUnload];
}

/*
- (void) viewWillAppear:(BOOL)animated
{
    // TODO (2/15/2012)
    // This function never gets called!!!
    // Should remove
 
    // init the cargos and score entries on the UI
    unsigned int score = [[StatsManager getInstance] pointsCurLevel];
    scoreEntry.text = [NSString stringWithFormat:@"%d", score];
    _scoreHighlight.text = [NSString stringWithFormat:@"%d", score];
    tourneyScoreEntry.text = [NSString stringWithFormat:@"%d", score];
    unsigned int multiplier = [[StatsManager getInstance] sessionMultiplier];
    _multiplierLabel.text = [NSString stringWithFormat:@"x%d", multiplier];
    
    // reset healthbar
    [self setupHealthBar];
    
    // reset kill-bullets icons
    [self setupBombSlots];
    
    // hide all hud labels by default
    _cargoMultiplierView.hidden = YES;
    _multiplierHighlight.hidden = YES;
    _scoreHighlight.hidden = YES;
    countdownLabel.hidden = YES;
    levelLabel.hidden = YES;
    messageView.hidden = YES;
    messageLabel.hidden = YES;
    willShowMessage = NO;
    loadingScreenView.hidden = YES;
    achievementsView.hidden = YES;
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}
*/
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) useTourneyScoreHudEntry
{
    scoreEntry.hidden = YES;
    tourneyScoreEntry.hidden = NO;
}

#pragma mark - private methods

- (void) updateFades:(NSTimeInterval)elapsed
{
    BOOL updateAchievementsFade = NO;
    updateAchievementsFade = [_achievementsViewFade update:elapsed];
    if(updateAchievementsFade)
    {
        achievementsView.alpha = [_achievementsViewFade alpha];
    }
    else if((![achievementsView isHidden]) && ([_achievementsViewFade alpha] < 1.0f))
    {
        achievementsView.hidden = YES;
    }
    
    BOOL updateCountdownFade = NO;
    updateCountdownFade = [_countdownFadeController update:elapsed];
    if(updateCountdownFade)
    {
        countdownLabel.alpha = 0.4f * [_countdownFadeController alpha];
    }
    else if((![countdownLabel isHidden]) && ([_countdownFadeController alpha] < 1.0f))
    {
        countdownLabel.hidden = YES;
    }
    
    BOOL updateMultiplierFade = NO;
    updateMultiplierFade = [_multiplierLabelFade update:elapsed];
    if(updateMultiplierFade)
    {
        _multiplierHighlight.alpha = [_multiplierLabelFade alpha];
        _scoreHighlight.alpha = [_multiplierHighlight alpha];
    }
    else if([_multiplierLabelFade alpha] < 1.0f)
    {
        if(![_multiplierHighlight isHidden])
        {
            _multiplierHighlight.hidden = YES;
        }
        if(![_scoreHighlight isHidden])
        {
            _scoreHighlight.hidden = YES;
        }
    }
    
    BOOL updateCargoMultiplierFade = NO;
    updateCargoMultiplierFade = [_cargoMultiplierFade update:elapsed];
    if(updateCargoMultiplierFade)
    {
        _cargoMultiplierView.alpha = [_cargoMultiplierFade alpha];
    }
    else if([_cargoMultiplierFade alpha] < 1.0f)
    {
        if(![_cargoMultiplierView isHidden])
        {
            _cargoMultiplierView.hidden = YES;
        }
    }
    
    // blink health bar when low
    BOOL updateFade = NO;
    updateFade = [_healthBarFade update:elapsed];
    if(updateFade)
    {
        _healthBar.alpha = [_healthBarFade alpha];
    }
    else if((![_healthBarFade isActive]) &&([_healthBar numFilled] < 2))
    {
        // continue the blink if health bar is still at 1
        [_healthBarFade triggerFade];
    }
}

- (void) setupCargoBars
{
    [_cargoMultiplierBar setNumSlots:NUM_CARGOS_PER_MULT];
    [_cargoMultiplierBar setNumFilled:0];
    [_cargoMultiplierBarCover setHidden:YES];
    
    [[_cargoMultiplierBarCover layer] setCornerRadius:8.0f];
    [[_cargoMultiplierBarCover layer] setMasksToBounds:YES];
    [[_cargoMultiplierBarCover layer] setBorderWidth:0.5f];
    
    UIColor* coverColor = [UIColor colorWithRed:(212.0f/255.0f) green:(12.0f/255.0f) blue:(12.0f/255.0f) alpha:0.7f];
    [[_cargoMultiplierBarCover layer] setBorderColor:[coverColor CGColor]];
}

- (void) setupHealthBar
{
    CGAffineTransform t = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_4);
    [_healthPackIcon setTransform:t];

    [_healthBar setNumSlots:[[PlayerInventory getInstance] curHealthSlots]];
    [_healthBar setNumFilled:[[PlayerInventory getInstance] curHealthSlots]];
    [_healthBar setSlotSpacing:0.75f];
    [_healthBar setFillFrameInset:0.75f];
    [_healthBar setOutFrameInset:0.0f];
    [_healthBar setOutlineWidth:0.5f];
    [_healthBar setOutlineColorWithRed:(255.0f/255.0f) green:(255.0f/255.0f) blue:(255.0f/255.0f) alpha:1.0f];

    _doHealthBarBlink = NO;
}

- (void) setupBombSlots
{
    [_bombSlots setNumSlots:[[PlayerInventory getInstance] curBombSlots]];
    [_bombSlots setNumFilled:0];
    [_bombSlots setFillColorWithRed:(0.0f/255.0f) green:(255.0f/255.0f) blue:(255.0f/255.0f) alpha:1.0f];    
    [_bombSlots setSlotSpacing:0.75f];
    [_bombSlots setFillFrameInset:0.75f];
    [_bombSlots setOutFrameInset:0.0f];
    [_bombSlots setOutlineWidth:0.5f];
    [_bombSlots setOutlineColorWithRed:(255.0f/255.0f) green:(255.0f/255.0f) blue:(255.0f/255.0f) alpha:1.0f];
}

#pragma mark - GameHudDelegate

- (void) showCountdown:(NSString *)text
{
    countdownLabel.hidden = NO;
    countdownLabel.alpha = 0.0f;
    [countdownLabel setText:text];
    [_countdownFadeController triggerFade];
}

- (void) showLevelLabel:(NSString *)name
{
    levelLabel.hidden = NO;
    levelLabel.alpha = 0.0f;
    [levelLabel setText:name];
    levelLabelFade = LEVELLABEL_FADERATE;
    levelLabelTimer = 0.0f;
}

- (void) showMessage:(NSString *)text
{
    messageView.hidden = NO;
    messageLabel.hidden = NO;
    messageView.alpha = 0.0f;
    messageLabel.alpha = 1.0f;
    messageLabel.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f];
    [messageLabel setText:text];
    willShowMessage = YES;
    messageLabelFade = MESSAGE_FADERATE;
}

- (void) dismissMessage
{
    if(!(messageLabel.hidden))
    {
        willShowMessage = NO;
        messageLabelFade = -MESSAGE_FADERATE;
    }
}

- (BOOL) isMessageBeingDisplayed
{
    BOOL result = !(messageView.hidden);
    return result;
}

- (void) update:(NSTimeInterval)elapsed
{
    if(!(levelLabel.hidden))
    {
        if(0.0f < levelLabelTimer)
        {
            levelLabelTimer -= elapsed;
        }
        else
        {
            float newAlpha = levelLabel.alpha + (elapsed * levelLabelFade);
            if((0.0f < levelLabelFade) && (1.0f <= newAlpha))
            {
                // flip fade
                levelLabelFade = -LEVELLABEL_FADERATE;
                levelLabelTimer = LEVELLABEL_TIMEOUT;
            }
            else if((0.0f > levelLabelFade) && (0.0f >= newAlpha))
            {
                // done fade
                levelLabelFade = 0.0f;
                levelLabel.hidden = YES;
                levelLabelTimer = 0.0f;
            }
            levelLabel.alpha = newAlpha;
        }
    }
    
    if((willShowMessage) && (messageView.alpha < 1.0f))
    {
        float newAlpha = messageView.alpha + (elapsed * messageLabelFade);
        if(newAlpha < 1.0f)
        {
            // message is hidden and willShowMessage true; fade in message
            messageView.alpha = newAlpha;
        }
        else
        {
            messageView.alpha = 1.0f;
        }
    }
    else if((!willShowMessage) && (messageView.alpha > 0.0f))
    {
        float newAlpha = messageView.alpha + (elapsed * messageLabelFade);
        if(newAlpha > 0.0f)
        {
            // message is hidden and willShowMessage true; fade in message
            messageView.alpha = newAlpha;
        }
        else
        {
            messageView.alpha = 0.0f;
            messageLabel.hidden = YES;
            messageView.hidden = YES;
        }        
    }
    
    [self updateFades:elapsed];
}

- (void) showAchievementWithName:(NSString *)name
{
    achievementsView.alpha = 0.0f;
    achievementsView.hidden = NO;
    [achievementName setText:name];
    [_achievementsViewFade triggerFade];
}

- (void) setCargoTowardsMultiplier:(unsigned int)num
{
    if(GAMEMODE_CAMPAIGN == [[GameManager getInstance] gameMode])
    {
        // only show the cargo-multiplier bar in singleplayer because
        // multiplayer is on the verge of info overload already
        [_cargoMultiplierBar setNumFilled:num];
        [_cargoMultiplierBar setNeedsDisplay];
        
        if([_cargoMultiplierView isHidden])
        {
            [_cargoMultiplierView setHidden:NO];
            [_cargoMultiplierView setAlpha:0.0f];        
        }
        [_cargoMultiplierFade triggerFade];
    }
}

- (void) showTourneyMessage:(NSString *)text withIcon:(UIImage *)iconImage
{
    if(_tourneyMessage && [_tourneyMessage isHidden])
    {
        [_tourneyMessage setHidden:NO];
        [_tourneyMessage setAlpha:0.0f];
        [_tourneyMessage setMessageText:text];
        [_tourneyMessage setIconImage:iconImage];
        CGAffineTransform initTransform = CGAffineTransformScale(CGAffineTransformIdentity, 10.0f, 10.0f);
        CGAffineTransform outwardTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1f, 1.1f);
        [_tourneyMessage setTransform:initTransform];
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [_tourneyMessage setAlpha:1.0f]; 
                             [_tourneyMessage setTransform:CGAffineTransformIdentity];
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:1.0f 
                                                   delay:1.0f 
                                                 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                                              animations:^{
                                                  [_tourneyMessage setAlpha:0.0f];
                                                  [_tourneyMessage setTransform:outwardTransform];
                                              }
                                              completion:^(BOOL finished){
                                                  [_tourneyMessage setHidden:YES];
                                                  [_tourneyMessage setIconImage:nil];
                                              }];
                         }];
    }
}

- (void) showTourneySentMessage:(NSString *)text
{
    if(_tourneySentMessage && [_tourneySentMessage isHidden])
    {
        [_tourneySentMessage setHidden:NO];
        [_tourneySentMessage setAlpha:0.0f];
        [_tourneySentMessage setMessageText:text];
        CGAffineTransform initTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0f, 380.0f);
        CGAffineTransform outwardTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1.05f, 1.05f);
        [_tourneySentMessage setTransform:initTransform];
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [_tourneySentMessage setAlpha:1.0f]; 
                             [_tourneySentMessage setTransform:CGAffineTransformIdentity];
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:1.0f 
                                                   delay:1.0f 
                                                 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                                              animations:^{
                                                  [_tourneySentMessage setAlpha:0.0f];
                                                  [_tourneySentMessage setTransform:outwardTransform];
                                              }
                                              completion:^(BOOL finished){
                                                  [_tourneySentMessage setHidden:YES];
                                                  [_tourneySentMessage setIconImage:nil];
                                              }];
                         }];
    }
}


#pragma mark - public methods

- (void) hideForLevelCompletion
{
    scoreEntry.hidden = YES;
}

- (void) unhideForLevelCompletion
{
    scoreEntry.hidden = NO;
}

- (void) fadeInNoImageLoading:(float)duration delay:(float)delay
{
    if([loadingScreenView isHidden])
    {
        loadingScreenView.hidden = NO;
        loadingScreenImageView.image = nil;
        if(0.0f < duration)
        {
            loadingScreenView.alpha = 0.0f;
            [UIView animateWithDuration:duration
                                  delay:delay
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{ 
                                 loadingScreenView.alpha = 1.0f;
                             }
                             completion:^(BOOL finished){
                             }];    
        }
        else
        {
            loadingScreenView.alpha = 1.0f;
        }
    }
}

- (void) fadeInLoading:(float)duration
{
    if([loadingScreenView isHidden])
    {
        loadingScreenView.hidden = NO;
        if(0.0f < duration)
        {
            loadingScreenView.alpha = 0.0f;
            [UIView animateWithDuration:duration
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{ 
                                 loadingScreenView.alpha = 1.0f;
                             }
                             completion:^(BOOL finished){
                             }];    
        }
        else
        {
            loadingScreenView.alpha = 1.0f;
        }
    }
}

- (void) fadeOutLoading:(float)duration
{
    // hide loading screen
    if(![loadingScreenView isHidden])
    {
        loadingScreenView.alpha = 1.0f;
        [UIView animateWithDuration:duration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ 
                             loadingScreenView.alpha = 0.0f;
                         }
                         completion:^(BOOL finished){
                             loadingScreenImageView.image = nil;
                             loadingScreenView.hidden = YES;
                         }];
    }
}

- (void) setupTourneyComponents
{
    // received message
    {
        CGFloat frameX = 0.1f * self.view.frame.size.width;
        CGFloat frameY = 0.2f * self.view.frame.size.height;
        CGFloat frameWidth = 0.8f * self.view.frame.size.width;
        CGFloat frameHeight = 0.1f * self.view.frame.size.height;
        CGRect tourneyMessageFrame = CGRectMake(frameX, frameY, frameWidth, frameHeight);
        _tourneyMessage = [[TourneyMessageView alloc] initWithFrame:tourneyMessageFrame];
        _tourneyMessage.hidden = YES;
        [self.view addSubview:_tourneyMessage];
    }
    
    // sent message
    {
        CGFloat frameX = 0.1f * self.view.frame.size.width;
        CGFloat frameY = 0.85f * self.view.frame.size.height;
        CGFloat frameWidth = 0.8f * self.view.frame.size.width;
        CGFloat frameHeight = 0.1f * self.view.frame.size.height;
        CGRect tourneyMessageFrame = CGRectMake(frameX, frameY, frameWidth, frameHeight);
        _tourneySentMessage = [[TourneyMessageView alloc] initWithFrame:tourneyMessageFrame];
        _tourneySentMessage.hidden = YES;
        [self.view addSubview:_tourneySentMessage];
    }
}


#pragma mark - StatsManagerUIDelegate
- (void) updateScore:(unsigned int)newScore
{
    scoreEntry.text = [NSString stringWithFormat:@"%d", newScore];
    _scoreHighlight.text = [NSString stringWithFormat:@"%d", newScore];
    tourneyScoreEntry.text = [NSString stringWithFormat:@"%d", newScore];
    [self.view setNeedsDisplay];
}

- (void) updateCargo:(unsigned int)newCargo
{
}

- (void) updateHealthBar:(unsigned int)curHealth
{
    [_healthBar setNumFilled:curHealth];
    if(curHealth > 1)
    {
        [_healthBarFade gotoHidden];
        [_healthBar setAlpha:1.0f];
        
        float frac = static_cast<float>(curHealth) / static_cast<float>([[PlayerInventory getInstance] curHealthSlots]);
        if(0.7f < frac)
        {
            [_healthBar setFillColor:[UIColor greenColor]];
        }
        else
        {
            [_healthBar setFillColor:[UIColor yellowColor]];
        }
    }
    else
    {
        // trigger blink
        [_healthBarFade triggerFade];
        [_healthBar setAlpha:0.0f];
        [_healthBar setFillColorWithRed:(212.0f/255.0f) green:(12.0f/255.0f) blue:(12.0f/255.0f) alpha:1.0f];
    }
    [_healthBar setNeedsDisplay];
}

- (void) updateNumKillBullets:(unsigned int)newNum
{
    if(0 < newNum)
    {
        [_bombSlotsView setHidden:NO];
    }
    else
    {
        [_bombSlotsView setHidden:YES];
    }
    [_bombSlots setNumFilled:newNum];
    [_bombSlots setNeedsDisplay];
}

- (void) didReceiveNewMultiplier:(unsigned int)newMultiplier hasIncreased:(BOOL)hasIncreased
{
    if(GAMEMODE_CAMPAIGN == [[GameManager getInstance] gameMode])
    {
        // only show the cargo-multiplier bar in singleplayer because
        // multiplayer is on the verge of info overload already

        // update label
        NSString* newMultiplierText = [NSString stringWithFormat:@"x%d", newMultiplier];
        [_multiplierHighlight setText:newMultiplierText];
        [_multiplierLabel setText:newMultiplierText];
        
        if(hasIncreased)
        {
            // show highlight
            [_cargoMultiplierBarCover setHidden:NO];
            [_cargoMultiplierBarCover setAlpha:0.0f];
            [_multiplierLabelFade triggerFade];
            [_multiplierHighlight setHidden:NO];
            [_multiplierHighlight setAlpha:0.0f];
            [_scoreHighlight setHidden:NO];
            [_scoreHighlight setAlpha:0.0f];
            [UIView animateWithDuration:0.2f 
                                  delay:0.0f 
                                options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 [_cargoMultiplierBarCover setAlpha:0.7f];
                             }
                             completion:^(BOOL finished){
                                 [UIView animateWithDuration:0.5f 
                                                       delay:0.2f 
                                                     options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                                                  animations:^{
                                                      [_cargoMultiplierBarCover setAlpha:0.0f];
                                                  }
                                                  completion:^(BOOL finished){
                                                      [_cargoMultiplierBarCover setHidden:YES];
                                                  }];
                                 
                             }];
        }
    }
}

@end
