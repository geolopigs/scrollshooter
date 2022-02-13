//
//  GameOverScreen.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "GameOverScreen.h"
#import "StatsManager.h"
#import "StoreManager.h"
#import "AchievementsManager.h"
#import "PogUIUtility.h"
#import "SoundManager.h"
#import "PogAnalytics+PeterPog.h"
#import "PogUITextLabel.h"
#import "StoreMenu.h"
#import "AppNavController.h"
#import "GoalsMenu.h"
#import "MenuResManager.h"
#include "MathUtils.h"
#import <QuartzCore/QuartzCore.h>
#import <Twitter/Twitter.h>

static const NSTimeInterval SCORE_DELAY = 0.4f;
static const NSTimeInterval CARGOS_DELAY = 0.8f;
static const NSTimeInterval FLIGHTTIME_DELAY = 1.2f;
static const NSTimeInterval COINS_DELAY = 0.8f;
static const NSTimeInterval HIGHSCORE_DELAY = 2.0;
static const NSTimeInterval COINSROLL_DURATION = 1.0f;
static const NSTimeInterval COINSROLL_TIMESTEP = 1.0 / 20.0;
static const NSTimeInterval CONTINUEBUTTON_DELAY = 1.0f;
static const NSTimeInterval MORECOINSBUTTON_DELAY = 1.2f;
static const NSTimeInterval EXITBUTTON_DELAY = 1.2f;

@interface GameOverScreen ()
{
    unsigned int _coinsRoll;
    unsigned int _coinsRollIncr;
    NSTimer* _coinsRollTimer;
}
- (void) updateFlightTime;
- (void) showFlightTime;
- (void) updateCargosDelivered;
- (void) showCargos;
- (void) updateCoinsEarned;
- (void) showCoins;
- (void) updateCoinsRoll:(NSTimer*)timer;
- (void) updateScore;
- (void) showScore;
- (void) showHighscore;
- (void) showContinueButton;
- (void) showMoreCoinsButton;
- (void) showExitButton;
- (void) updateContinueButton;

- (void) handleCoinsChanged:(NSNotification*)note;
@end

@implementation GameOverScreen
@synthesize delegate = _delegate;
@synthesize contentView = _contentView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        _delegate = nil;
        _coinsRollTimer = nil;
    }
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if([_coinsRollTimer isValid])
    {
        [_coinsRollTimer invalidate];
    }
    [_coinsRollTimer release];
    [_delegate release];
    _delegate = nil;
    [_flightTimeLabel release];
    [_cargosDeliveredLabel release];
    [_pogcoinsLabel release];
    [_scoreLabel release];
    [_newHighscoreLabel release];
    [backScrim release];
    [border release];
    [_coinsView release];
    [_flightTimeView release];
    [_cargosView release];
    [_twitterButton release];
    [_textLabelStats release];
    [_textLabelGoals release];
    [_continueButtonView release];
    [_continuePriceLabel release];
    [_moreCoinsButtonView release];
    [_contentView release];
    [_exitButtonView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // init round corners
    [[backScrim layer] setCornerRadius:3.0f];
    [[backScrim layer] setMasksToBounds:YES];
    [[backScrim layer] setBorderWidth:1.0f];
    [[backScrim layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [backScrim setBackgroundColor:[UIColor colorWithRed:0.1f green:0.158f blue:0.158f alpha:1.0f]];
    [[border layer] setCornerRadius:4.0f];
    [[border layer] setMasksToBounds:YES];
    [[border layer] setBorderWidth:1.5f];
    [[border layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    [[_continueButtonView layer] setCornerRadius:20.0f];
    [[_continueButtonView layer] setMasksToBounds:YES];
    [[_continueButtonView layer] setBorderWidth:1.5f];
    [[_continueButtonView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    [[_moreCoinsButtonView layer] setCornerRadius:20.0f];
    [[_moreCoinsButtonView layer] setMasksToBounds:YES];
    [[_moreCoinsButtonView layer] setBorderWidth:1.5f];
    [[_moreCoinsButtonView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    [[_exitButtonView layer] setCornerRadius:15.0f];
    [[_exitButtonView layer] setMasksToBounds:YES];
    [[_exitButtonView layer] setBorderWidth:1.5f];
    [[_exitButtonView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    
    // set button texts
    [_textLabelGoals setText:@"GOALS"];
    [_textLabelGoals setBackgroundColor:[UIColor clearColor]];
    [_textLabelStats setText:@"STATS"];
    [_textLabelStats setBackgroundColor:[UIColor clearColor]];
    
    [self updateCoinsEarned];
    [self updateScore];
    [self updateContinueButton];
    
    // observe pogcoins changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCoinsChanged:) 
                                                 name:kStatsManagerNoteDidChangeCoins object:nil];
    
    // animate them in
    [self showScore];
    [self showCoins];
    [self showHighscore];
    [self showContinueButton];
    //[self showMoreCoinsButton];
    [self showExitButton];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if([_coinsRollTimer isValid])
    {
        [_coinsRollTimer invalidate];
    }
    [_coinsRollTimer release];
    _coinsRollTimer = nil;
    [_flightTimeLabel release];
    _flightTimeLabel = nil;
    [_cargosDeliveredLabel release];
    _cargosDeliveredLabel = nil;
    [_pogcoinsLabel release];
    _pogcoinsLabel = nil;
    [_scoreLabel release];
    _scoreLabel = nil;
    [_newHighscoreLabel release];
    _newHighscoreLabel = nil;
    [backScrim release];
    backScrim = nil;
    [border release];
    border = nil;
    [_coinsView release];
    _coinsView = nil;
    [_flightTimeView release];
    _flightTimeView = nil;
    [_cargosView release];
    _cargosView = nil;
    [_twitterButton release];
    _twitterButton = nil;
    [_textLabelStats release];
    _textLabelStats = nil;
    [_textLabelGoals release];
    _textLabelGoals = nil;
    [_continueButtonView release];
    _continueButtonView = nil;
    [_continuePriceLabel release];
    _continuePriceLabel = nil;
    [_moreCoinsButtonView release];
    _moreCoinsButtonView = nil;
    [_contentView release];
    _contentView = nil;
    [_exitButtonView release];
    _exitButtonView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UI values
static const float kSecondsPerHour = 3600.0;
static const float kSecondsPerMinute = 60.0;
- (void) updateFlightTime
{
    NSTimeInterval value = [[StatsManager getInstance] sessionFlightTime];
    
    NSTimeInterval hoursValue = floor(value / kSecondsPerHour);
    NSTimeInterval minutesValue = floor((value - (hoursValue * kSecondsPerHour)) / kSecondsPerMinute);
    NSTimeInterval secondsValue = floor(value - (hoursValue * kSecondsPerHour) - (minutesValue * kSecondsPerMinute));
    
    unsigned int hoursInt = static_cast<unsigned int>(hoursValue);
    unsigned int minutesInt = static_cast<unsigned int>(minutesValue);
    unsigned int secondsInt = static_cast<unsigned int>(secondsValue);
    
    NSString* minutesString = [NSString stringWithFormat:@"%d", minutesInt];
    if(10 > minutesInt)
    {
        minutesString = [NSString stringWithFormat:@"0%d", minutesInt];
    }
    NSString* secondsString = [NSString stringWithFormat:@"%d", secondsInt];
    if(10 > secondsInt)
    {
        secondsString = [NSString stringWithFormat:@"0%d", secondsInt];
    }
    NSString* flightTimeString = [NSString stringWithFormat:@"%@:%@", minutesString, secondsString];
    if(0 < hoursInt)
    {
        flightTimeString = [NSString stringWithFormat:@"%d:%@:%@", hoursInt, minutesString, secondsString];
    }
    [_flightTimeLabel setText:flightTimeString];
}

- (void) updateCargosDelivered
{
    unsigned int value = [[StatsManager getInstance] sessionCargosDelivered];
    NSString* cargosString = [NSString stringWithFormat:@"%d", value];
    [_cargosDeliveredLabel setText:cargosString];
}

- (void) updateCoinsEarned
{
    _coinsRoll = [[StatsManager getInstance] getTotalCash] - [[StatsManager getInstance] sessionCashEarned];
    [_pogcoinsLabel setText:[StoreManager pogcoinsStringForAmount:_coinsRoll]];
    float incr = (float)[[StatsManager getInstance] sessionCashEarned] * COINSROLL_TIMESTEP;
    if(incr < 1.0f)
    {
        _coinsRollIncr = 1;
    }
    else 
    {
        _coinsRollIncr = (float) floorf(incr);
    }    
}

- (void) updateScore
{
    unsigned int value = [[StatsManager getInstance] sessionScore];
    NSString* valueString = [StoreManager pogcoinsStringForAmount:value];
    [_scoreLabel setText:valueString];
    if([[StatsManager getInstance] wasLastScoreHighscore])
    {
        [_newHighscoreLabel setHidden:NO];
    }
    else
    {
        [_newHighscoreLabel setHidden:YES];
    }
}

- (void) updateContinueButton
{
    unsigned int price = [[StoreManager getInstance] priceForContinueGame];
    [_continuePriceLabel setText:[StoreManager pogcoinsStringForAmount:price]];
}

- (void) handleCoinsChanged:(NSNotification *)note
{
    unsigned int totalCash = [[StatsManager getInstance] getTotalCash];
    [_pogcoinsLabel setText:[StoreManager pogcoinsStringForAmount:totalCash]];
}

- (void) updateCoinsRoll:(NSTimer*)timer
{
    if(_coinsRoll < [[StatsManager getInstance] getTotalCash])
    {
        _coinsRoll += _coinsRollIncr;
        [_pogcoinsLabel setText:[StoreManager pogcoinsStringForAmount:_coinsRoll]];
    }
    else 
    {
        _coinsRoll = [[StatsManager getInstance] getTotalCash];
        [_pogcoinsLabel setText:[StoreManager pogcoinsStringForAmount:_coinsRoll]];
        [timer invalidate];
    }
}

- (void) showFlightTime
{
    [_flightTimeView setAlpha:0.0f];
    [UIView animateWithDuration:0.2f 
                          delay:FLIGHTTIME_DELAY 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
                         [_flightTimeView setAlpha:1.0f];
                     }
                     completion:NULL];
}

- (void) showCargos
{
    [_cargosView setAlpha:0.0f];
    [UIView animateWithDuration:0.2f 
                          delay:CARGOS_DELAY 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
                         [_cargosView setAlpha:1.0f];
                     }
                     completion:NULL];
    
}

- (void) showCoins
{
    [_coinsView setAlpha:0.0f];
    [UIView animateWithDuration:0.2f 
                          delay:COINS_DELAY 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
                         [_coinsView setAlpha:1.0f];
                     }
                     completion:^(BOOL finished){
                         _coinsRollTimer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) COINSROLL_TIMESTEP
                                                                            target:self 
                                                                          selector:@selector(updateCoinsRoll:) 
                                                                          userInfo:nil 
                                                                           repeats:YES] retain];
                     }];    
}

- (void) showScore
{
    [_scoreLabel setAlpha:0.0f];
    [UIView animateWithDuration:0.2f 
                          delay:SCORE_DELAY
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
                         [_scoreLabel setAlpha:1.0f];
                     }
                     completion:NULL];
}

- (void) showHighscore
{
    [_newHighscoreLabel setAlpha:0.0f];
    [UIView animateWithDuration:0.5f 
                          delay:HIGHSCORE_DELAY
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
                         [_newHighscoreLabel setAlpha:1.0f];
                     }
                     completion:NULL];
    
}

- (void) showContinueButton
{
    [_continueButtonView setAlpha:0.0f];
    [UIView animateWithDuration:0.2f 
                          delay:CONTINUEBUTTON_DELAY 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
                         [_continueButtonView setAlpha:1.0f];
                     }
                     completion:NULL];
}

- (void) showMoreCoinsButton
{
    [_moreCoinsButtonView setAlpha:0.0f];
    [UIView animateWithDuration:0.2f 
                          delay:MORECOINSBUTTON_DELAY 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
                         [_moreCoinsButtonView setAlpha:1.0f];
                     }
                     completion:NULL];
}

- (void) showExitButton
{
    [_exitButtonView setAlpha:0.0f];
    [UIView animateWithDuration:0.2f 
                          delay:EXITBUTTON_DELAY 
                        options:UIViewAnimationOptionCurveEaseIn 
                     animations:^{
                         [_exitButtonView setAlpha:1.0f];
                     }
                     completion:NULL];
}

#pragma mark - buttons
- (void) buttonExitPressed:(id)sender
{
    if([self delegate])
    {
        [[SoundManager getInstance] playClip:@"ButtonPressed"];
        
        // randomly go to Main Menu, Store, or Goals
        // (TODO: use some heuristics to decide where to lead player)
        // now, it's just 20% Main Menu, 40% Store, 40% Goals
        float frac = randomFrac();
        if(0.2f >= frac)
        {
            // Main Menu
            [self.delegate dismissGameOverScreen];
        }
        else if(0.6f >= frac)
        {
            // Store
            [[PogAnalytics getInstance] logStoreFromGameOver];
            [self.delegate gotoStore];
        }
        else 
        {
            // Goals
            [[PogAnalytics getInstance] logGoalsFromGameOver];
            [self.delegate gotoGoals];
        }
    }
}

- (void) buttonStorePressed:(id)sender
{
    [[PogAnalytics getInstance] logStoreFromGameOver];
    StoreMenu* controller = [[StoreMenu alloc] initWithGetMoreCoins:NO];
    [[AppNavController getInstance] pushFromLeftViewController:controller animated:YES];
    [controller release];
/*
    if([self delegate])
    {
        [[PogAnalytics getInstance] logStoreFromGameOver];
        [[SoundManager getInstance] playClip:@"ButtonPressed"];
        [self.delegate gotoStore];
    }
 */
}

- (IBAction)twitterButtonPressed:(id)sender 
{
    /*
    [[PogAnalytics getInstance] logTweetFromGameOver];
    [[SoundManager getInstance] playClip:@"ButtonPressed"];
    if([TWTweetComposeViewController canSendTweet])
    {
        TWTweetComposeViewController* tweet = [[TWTweetComposeViewController alloc] init];
        
        NSString* scoreString = [PogUIUtility commaSeparatedStringFromUnsignedInt:[[StatsManager getInstance] sessionScore]];
        unsigned int routeCompleted = [[AchievementsManager getInstance] routeCount];
        if(0 < routeCompleted)
        {
            if(1 < routeCompleted)
            {
                [tweet setInitialText:[NSString stringWithFormat:@"I got %@ points in #PeterPog, delivered %d routes. Top that! @GeoloPigs",
                                       scoreString, [[AchievementsManager getInstance] routeCount]]];
            }
            else
            {
                [tweet setInitialText:[NSString stringWithFormat:@"I got %@ points in #PeterPog, delivered %d route. Top that! @GeoloPigs",
                                       scoreString, [[AchievementsManager getInstance] routeCount]]];
            }
        }
        else
        {
            [tweet setInitialText:[NSString stringWithFormat:@"I got %@ points in #PeterPog. Awesome. @GeoloPigs", scoreString]];
        }
        [tweet addURL:[NSURL URLWithString:@"http://itunes.apple.com/app/peterpog/id470032238"]];
        [self presentModalViewController:tweet animated:YES];
    }
    else
    {
        // if can't send tweet, then go to GeoloPigs twitter profile
        [PogUIUtility followUsOnTwitter];
    }
     */
}

- (IBAction)buttonGoalsPressed:(id)sender 
{
    GoalsMenu* controller = [[GoalsMenu alloc] initToGimmie:YES];
    [[AppNavController getInstance] pushFromRightViewController:controller animated:YES];
    [controller release];  
/*
    if([self delegate])
    {
        [[PogAnalytics getInstance] logGoalsFromGameOver];
        [[SoundManager getInstance] playClip:@"ButtonPressed"];
        [self.delegate gotoGoals];
    }
 */
}

- (IBAction)buttonStatsPressed:(id)sender 
{
    if([self delegate])
    {    
        [[PogAnalytics getInstance] logStatsFromGameOver];
        [[SoundManager getInstance] playClip:@"ButtonPressed"];
        [self.delegate gotoStats];
    }
}

- (IBAction)buttonContinuePressed:(id)sender 
{
    if([self delegate])
    {
        [[PogAnalytics getInstance] logContinueGameButton];

        unsigned int continuePrice = [[StoreManager getInstance] priceForContinueGame];
        unsigned int curPogcoins = [[StatsManager getInstance] getTotalCash];
        if(curPogcoins > continuePrice)
        {
            [[SoundManager getInstance] playClip:@"ButtonPressed"];
            
            // deduct coins
            [[StatsManager getInstance] commitAddCoins:-continuePrice];

            // proceed to continue
            [self.delegate continueGame];
        }
        else 
        {
            // not enough coins; show alert;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not enough Pogcoins" 
                                                            message:@"Get More Pogcoins?"
                                                           delegate:self 
                                                  cancelButtonTitle:@"No" 
                                                  otherButtonTitles:@"Yes", nil];
            [MenuResManager getInstance].alertView = alert;
            [alert show];
            [alert release];  
        }
    }
}

- (IBAction)buttonGetMoreCoinsPressed:(id)sender 
{
    [[PogAnalytics getInstance] logGetMoreCoinsGameOver];
    StoreMenu* controller = [[StoreMenu alloc] initWithGetMoreCoins:YES];
    [[AppNavController getInstance] pushFromLeftViewController:controller animated:YES];
    [controller release];
}

- (IBAction)buttonExitToMainMenuPressed:(id)sender 
{
    if([self delegate])
    {
        [[SoundManager getInstance] playClip:@"ButtonPressed"];
        [self.delegate dismissGameOverScreen];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // unretain the view; it's being dismissed;
    [MenuResManager getInstance].alertView = nil;
    
    if([alertView cancelButtonIndex] == buttonIndex)
    {
        // canceled, do nothing
    }
    else if([alertView firstOtherButtonIndex] == buttonIndex)
    {
        // yes, get more pogcoins
        [self buttonGetMoreCoinsPressed:nil];
    }
}


@end
