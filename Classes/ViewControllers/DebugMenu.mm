//
//  DebugMenu.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/20/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//


#if defined(DEBUG)

#import "DebugMenu.h"
#import "DebugOptions.h"
#import "AppNavController.h"
#import "StatsManager.h"
#import "PlayerData.h"
#import "StatsData.h"
#import "AchievementsManager.h"
#import "GameCenterManager.h"
#import "PlayerInventoryIds.h"
#import "PlayerInventory.h"

@interface DebugMenu (PrivateMethods)
- (void) setupOnOff;
- (void) teardownOnOff;
@end

@implementation DebugMenu

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        
    }
    return self;
}

- (void) dealloc
{
    [self teardownOnOff];
    [noEnemiesOnOff release];
    [_unlockFlyersOnOff release];
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
    [self setupOnOff];
}

- (void)viewDidUnload
{
    [self teardownOnOff];
    [_unlockFlyersOnOff release];
    _unlockFlyersOnOff = nil;
    [super viewDidUnload];
    [self teardownOnOff];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - private methods
- (void) setupOnOff
{
    [playerInvincibleOnOff addTarget:[DebugOptions getInstance] action:@selector(togglePlayerInvincibleOnOff:) forControlEvents:UIControlEventValueChanged];
    playerInvincibleOnOff.on = [[DebugOptions getInstance] isPlayerInvincible];
    [colOutlineOnOff addTarget:[DebugOptions getInstance] action:@selector(toggleDebugColOutlineOnOff:) forControlEvents:UIControlEventValueChanged];
    colOutlineOnOff.on = [[DebugOptions getInstance] isDebugColOutlineOn];
    [noEnemiesOnOff addTarget:[DebugOptions getInstance] action:@selector(toggleDebugNoEnemiesOnOff:) forControlEvents:UIControlEventValueChanged];
    noEnemiesOnOff.on = [[DebugOptions getInstance] debugNoEnemies];
    [unlockAllLevelsOnOff addTarget:[DebugOptions getInstance] action:@selector(toggleAllLevelsUnlocked:) forControlEvents:UIControlEventValueChanged];
    unlockAllLevelsOnOff.on = [[DebugOptions getInstance] isAllLevelsUnlocked];
    [_unlockFlyersOnOff addTarget:[DebugOptions getInstance] action:@selector(toggleFlyersUnlocked:) forControlEvents:UIControlEventValueChanged];
    _unlockFlyersOnOff.on = [[DebugOptions getInstance] areFlyersUnlocked];
}

- (void) teardownOnOff
{
    [playerInvincibleOnOff removeTarget:[DebugOptions getInstance] action:@selector(togglePlayerInvincibleOnOff:) forControlEvents:UIControlEventValueChanged]; 
    [colOutlineOnOff removeTarget:[DebugOptions getInstance] action:@selector(toggleDebugColOutlineOnOff:) forControlEvents:UIControlEventValueChanged];
    [noEnemiesOnOff removeTarget:[DebugOptions getInstance] action:@selector(toggleDebugNoEnemiesOnOff:) forControlEvents:UIControlEventValueChanged];
    [unlockAllLevelsOnOff removeTarget:[DebugOptions getInstance] action:@selector(toggleAllLevelsUnlocked:) forControlEvents:UIControlEventValueChanged];
    [_unlockFlyersOnOff removeTarget:[DebugOptions getInstance] action:@selector(toggleFlyersUnlocked:) forControlEvents:UIControlEventValueChanged];
    
    [playerInvincibleOnOff release];
    playerInvincibleOnOff = nil;
    [colOutlineOnOff release];
    colOutlineOnOff = nil;
    [noEnemiesOnOff release];
    noEnemiesOnOff = nil;
    [unlockAllLevelsOnOff release];
    unlockAllLevelsOnOff = nil;
    [_unlockFlyersOnOff release];
    _unlockFlyersOnOff = nil;
}

#pragma mark - Navigation
- (IBAction)backButtonPressed:(id)sender
{
    [[AppNavController getInstance] popViewControllerAnimated:YES];        
}

- (IBAction)resetHighscorePressed:(id)sender
{
    [[StatsManager getInstance] resetAllHighscores];
    [[StatsManager getInstance] clearCompletedTutorial];
    [[StatsManager getInstance] clearCompletedTutorialTourney];
}

- (IBAction)resetUserDefaultsPressed:(id)sender
{
    [NSUserDefaults resetStandardUserDefaults];
}

- (IBAction)clearPiggybankPressed:(id)sender
{
    [[StatsManager getInstance] playerData].pogCoins = 0;
    [[StatsManager getInstance] statsData].pogcoinsCollected = 0;
}

- (IBAction)addToPiggybankPressed:(id)sender
{
    [[StatsManager getInstance] playerData].pogCoins += 200;
}

- (IBAction)resetGameCenterAchievementsPressed:(id)sender
{
    [[GameCenterManager getInstance] resetAchievements];
}

- (IBAction)resetGameAchievementsPressed:(id)sender
{
    [[AchievementsManager getInstance] resetGameLocalAchievements];
}

- (IBAction)upgradeWeapon:(id)sender
{
    [[PlayerInventory getInstance] upgradeWoodenBullets];
}

- (IBAction)resetWeapon:(id)sender
{
    [[PlayerInventory getInstance] resetWoodenBullets]; 
    [[PlayerInventory getInstance] resetForWeaponGradeKey:UPGRADE_ID_LASER];
    [[PlayerInventory getInstance] resetForWeaponGradeKey:UPGRADE_ID_BOOMERANG];
    [[PlayerInventory getInstance] resetForWeaponGradeKey:UTILITY_ID_ADDBOMB];
    [[PlayerInventory getInstance] resetBombSlots];
    [[PlayerInventory getInstance] resetHangar];
    [[PlayerInventory getInstance] resetForWeaponGradeKey:FREECOINS_ID_FBCOINS];
    [[PlayerInventory getInstance] resetForWeaponGradeKey:FREECOINS_ID_TWEETCOINS];
}

#pragma mark -
#pragma mark AppEventDelegate
- (void) appWillResignActive
{
	// do nothing
}

- (void) appDidBecomeActive
{
	// do nothing
}

- (void) appDidEnterBackground
{
	// do nothing
}

- (void) appWillEnterForeground
{
    // do nothing
}

- (void) abortToRootViewControllerNow
{
    [[AppNavController getInstance] popToRootViewControllerAnimated:NO];
}

@end

#endif // defined(DEBUG)