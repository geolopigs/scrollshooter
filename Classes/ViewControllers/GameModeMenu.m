//
//  GameModeMenu.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/30/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "GameModeMenu.h"
#import "GameModes.h"
#import <QuartzCore/QuartzCore.h>

@implementation GameModeMenu
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
    [backScrim release];
    [border release];
    [buttonNextpeerMultiplayer release];
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

    buttonNextpeerMultiplayer.enabled = YES;
    
    // init round corners
    [[backScrim layer] setCornerRadius:0.5f];
    [[backScrim layer] setMasksToBounds:YES];
    [[backScrim layer] setBorderWidth:1.0f];
    [[backScrim layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[border layer] setCornerRadius:3.0f];
    [[border layer] setMasksToBounds:YES];
    [[border layer] setBorderWidth:3.0f];
    [[border layer] setBorderColor:[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.8f] CGColor]];
}

- (void)viewDidUnload
{
    [_delegate release];
    _delegate = nil;
    [backScrim release];
    backScrim = nil;
    [border release];
    border = nil;
    [buttonNextpeerMultiplayer release];
    buttonNextpeerMultiplayer = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - buttons
- (IBAction) nextpeerMultiplayerPressed:(id)sender
{
    if(_delegate)
    {
        [_delegate dismissAndGoToGameMode:GAMEMODE_TIMEBASED];
    }
}

- (IBAction) campaignPressed:(id)sender
{
    if(_delegate)
    {
        [_delegate dismissAndGoToGameMode:GAMEMODE_CAMPAIGN];
    }
}

@end
