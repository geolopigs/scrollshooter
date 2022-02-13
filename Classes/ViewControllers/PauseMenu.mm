//
//  PauseMenu.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/9/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "PauseMenu.h"
#import "SoundManager.h"
#import "MenuResManager.h"

@interface PauseMenu (PrivateMethods)
- (void) setupSoundButtons;
@end


@implementation PauseMenu
@synthesize pauseButton;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        self.delegate = nil;
    }
    return self;
}

- (void) dealloc
{
    self.pauseButton = nil;
    [soundButton release];
    [soundButtonOn release];
    [soundButtonOff release];
    self.delegate = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Private Methods

- (void) setupSoundButtons
{
    if([[SoundManager getInstance] enabled])
    {
        soundButtonOn.hidden = NO;
        soundButtonOff.hidden = YES;
    }
    else
    {
        soundButtonOn.hidden = YES;
        soundButtonOff.hidden = NO;
    }
}

#pragma mark - UI
- (IBAction)resumeGame:(id)sender
{
    // play one shot sound
    [[SoundManager getInstance] playClip:@"BackForwardButton"];
    
    [delegate resumeGameFromPauseMenu:self];
}

- (IBAction)quitGame:(id)sender
{
    // play one shot sound
    [[SoundManager getInstance] playClip:@"ButtonPressed"];
    
    [delegate quitGameFromPauseMenu:self];
}

- (IBAction)restartLevel:(id)sender
{
    // play one shot sound
    [[SoundManager getInstance] playClip:@"ButtonPressed"];
    
    [delegate restartLevelFromPauseMenu:self];
}


- (IBAction) soundButtonPressed:(id)sender
{
    [[SoundManager getInstance] toggleSound];
    [self setupSoundButtons];
}

- (IBAction)helpButtonPressed:(id)sender 
{
    [[SoundManager getInstance] playClip:@"ButtonPressed"];
    [delegate showTutorialFromPauseMenu:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup sub-components
    [self setupSoundButtons];
}

- (void)viewDidUnload
{
    self.pauseButton = nil;
    [soundButton release];
    soundButton = nil;
    [soundButtonOn release];
    soundButtonOn = nil;
    [soundButtonOff release];
    soundButtonOff = nil;
    self.delegate = nil;
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
