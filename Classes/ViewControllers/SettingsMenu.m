//
//  SettingsMenu.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/29/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "SettingsMenu.h"
#import "SoundManager.h"
#import "GameCenterManager.h"
#import "PogUIUtility.h"
#import "PogUITextLabel.h"
#import <QuartzCore/QuartzCore.h>

@interface SettingsMenu (PrivateMethods)
- (void) setupGameCenterButtons;
@end

@implementation SettingsMenu
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        _delegate = nil;
    }
    return self;
}

- (void) dealloc
{
    [_delegate release];
    [buttonAchievements release];
    [buttonLeaderboards release];
    [backScrim release];
    [border release];
    [_textLabelStats release];
    [_textLabelGoals release];
    [_textLabelMore release];
    [_textLabelCredits release];
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
    
    // init round corners
    [[backScrim layer] setCornerRadius:0.5f];
    [[backScrim layer] setMasksToBounds:YES];
    [[backScrim layer] setBorderWidth:1.0f];
    [[backScrim layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[border layer] setCornerRadius:3.0f];
    [[border layer] setMasksToBounds:YES];
    [[border layer] setBorderWidth:1.5f];
    [[border layer] setBorderColor:[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.8f] CGColor]];
    
    // set button texts
    [_textLabelStats setText:@"STATS"];
    [_textLabelStats setBackgroundColor:[UIColor clearColor]];
    [_textLabelGoals setText:@"GOALS"];
    [_textLabelGoals setBackgroundColor:[UIColor clearColor]];
    [_textLabelMore setText:@"MORE"];
    [_textLabelMore setBackgroundColor:[UIColor clearColor]];
    [_textLabelCredits setText:@"CREDITS"];
    [_textLabelCredits setBackgroundColor:[UIColor clearColor]];
}

- (void)viewDidUnload
{
    self.delegate = nil;
    [buttonAchievements release];
    buttonAchievements = nil;
    [buttonLeaderboards release];
    buttonLeaderboards = nil;
    [backScrim release];
    backScrim = nil;
    [border release];
    border = nil;
    [_textLabelStats release];
    _textLabelStats = nil;
    [_textLabelGoals release];
    _textLabelGoals = nil;
    [_textLabelMore release];
    _textLabelMore = nil;
    [_textLabelCredits release];
    _textLabelCredits = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - private methods

- (void) setupGameCenterButtons
{
    if(([[GameCenterManager getInstance] isGameCenterAvailable]) &&
       ([[GameCenterManager getInstance] isAuthenticated]))
    {
        buttonAchievements.enabled = YES;
        buttonLeaderboards.enabled = YES;
    }
    else
    {
        buttonAchievements.enabled = NO;
        buttonLeaderboards.enabled = NO;        
    }
}


#pragma mark - button actions

- (IBAction) buttonLeaderboardsPressed:(id)sender
{
    if([self delegate])
    {
        [self.delegate handleButtonLeaderboards];
    }
}

- (IBAction)buttonCreditsPressed:(id)sender
{
    if([self delegate])
    {
        [self.delegate handleButtonCredits];
    }
}

- (IBAction)buttonGoalsPressed:(id)sender
{
    if([self delegate])
    {
        [self.delegate handleButtonGoals];
    }
}

- (IBAction)buttonMorePressed:(id)sender 
{
    if([self delegate])
    {
        [self.delegate handleMore];
    }
}


@end
