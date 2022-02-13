//
//  GoalsMenu.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "GoalsMenu.h"
#import "AchievementsManager.h"
#import "AchievementRegEntry.h"
#import "AchievementsData.h"
#import "MenuResManager.h"
#import "GoalCell.h"
#import "GameCenterManager.h"
#import "SoundManager.h"
#import "AppNavController.h"
#import "PogAnalytics+PeterPog.h"
#import "Reachability.h"
#import "StatsManager.h"
#import "GameManager.h"
#import "GameViewController.h"

@interface GoalsMenu () <GKGameCenterControllerDelegate>
- (void) refreshUnlockRouteAchievements;
- (void) handleGimmieDidInit:(NSNotification*)note;
@end

@implementation GoalsMenu
@synthesize tableView = _tableView;
@synthesize goalCell = _goalCell;
@synthesize initShowGimmie = _initShowGimmie;

- (id) initToGimmie:(BOOL)showGimmie
{
    self = [super initWithNibName:@"GoalsMenu" bundle:nil];
    if (self) 
    {
        _goalCell = nil;
        _selectedRow = 0;
        _initShowGimmie = showGimmie;
    }
    return self;    
}

- (void) dealloc
{
    [_goalCell release];
    [_tableView release];
    [buttonGameCenter release];
    [backScrim release];
    [border release];
    [_contentView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - setup
- (void) refreshUnlockRouteAchievements
{
    unsigned int nextIncomplete = [[StatsManager getInstance] nextIncompleteLevelForEnv:@"Homebase"];
    for(unsigned int i = 0; i < nextIncomplete; ++i)
    {
        [[AchievementsManager getInstance] unlockRoute:i];
    }

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        const float iPadScale = 0.95f * ([[UIScreen mainScreen] bounds].size.height / _contentView.frame.size.height);
        [_contentView setTransform:CGAffineTransformMakeScale(iPadScale, iPadScale)];
        [[_contentView layer] setCornerRadius:6.0f];
        [[_contentView layer] setMasksToBounds:YES];
        [border setTransform:CGAffineTransformMakeScale(iPadScale, iPadScale)];
        [[border layer] setCornerRadius:8.0f];
        [[border layer] setMasksToBounds:YES];
        [[border layer] setBorderWidth:3.0f];
        [[border layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    }
    
    // game center button always starts out enabled
    // when user presses it, it will disable if Game Center is not available
    [buttonGameCenter setEnabled:YES];
    
    // setup border if specified in nib
    if(backScrim && border)
    {
        [[backScrim layer] setCornerRadius:0.5f];
        [[backScrim layer] setMasksToBounds:YES];
        [[backScrim layer] setBorderWidth:1.0f];
        [[backScrim layer] setBorderColor:[[UIColor grayColor] CGColor]];
        [[border layer] setCornerRadius:3.0f];
        [[border layer] setMasksToBounds:YES];
        [[border layer] setBorderWidth:3.0f];
        [[border layer] setBorderColor:[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.8f] CGColor]];
    }
    
    // for backward compatibility, go through and set all unlocked route achievements
    [self refreshUnlockRouteAchievements];
    
    // auto scroll to the next incomplete achievement
    unsigned int nextIncomplete = [[AchievementsManager getInstance] indexOfNextIncompleteFromOrderedAchievement];
    if(0 < nextIncomplete)
    {
        // select the next incomplete entry
        
        [_tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:nextIncomplete inSection:0]
                                animated:YES
                          scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:_tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:nextIncomplete inSection:0]];
    }
}

- (void)viewDidUnload
{
    // remove myself as gimmie notifications observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_goalCell release];
    _goalCell = nil;
    [_tableView release];
    _tableView = nil;
    [buttonGameCenter release];
    buttonGameCenter = nil;
    [backScrim release];
    backScrim = nil;
    [border release];
    border = nil;
    [_contentView release];
    _contentView = nil;
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    // remove myself as gimmie notifications observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark UITableViewDataSource Methods 
- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray* orderedAchievementKeys = [[AchievementsManager getInstance] orderedAchievementKeys];
	GoalCell *cell = nil;
    
    if(indexPath.row < [orderedAchievementKeys count])
    {
        static NSString *cellIdentifier = @"GoalCell";
        
        cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
        if( nil == cell ) 
        {
            cell = [[GoalCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        UILabel* mainLabel = cell.textLabel;
        UIImageView* checkbox = cell.imageView;
        
        NSString* curKey = [orderedAchievementKeys objectAtIndex:indexPath.row];
        AchievementRegEntry* curAchievementInfo = [[AchievementsManager getInstance].achievementsRegistry objectForKey:curKey];
        [mainLabel setText:[curAchievementInfo name]];
        
        // checkbox if goal completed
        AchievementsData* curData = [[[AchievementsManager getInstance] getGameAchievementsData] objectForKey:curKey];
        if([curData isCompleted])
        {
            [checkbox setImage:[[MenuResManager getInstance] loadImage:@"checkMark" isIngame:NO]];
            [cell hideGimmiePoints];
        }
        else
        {
            [checkbox setImage:[[MenuResManager getInstance] loadImage:@"checkBox" isIngame:NO]];
        }
        
        // detailText setup based on selection
        if(indexPath.row == _selectedRow)
        {
            [cell selectedForAchievementId:curKey];
        }
        else
        {
            [cell deselectedForAchievementId:curKey];
        }
    }    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	NSInteger numSections = 1;	
	return numSections;
}


- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = 0;
	if(0 == section)
    {
        numRows = [[[AchievementsManager getInstance] orderedAchievementKeys] count];
    }
    return numRows;
}

#pragma mark UITableViewDelegate Methods

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tv
didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSString* deselKey = [[[AchievementsManager getInstance] orderedAchievementKeys] objectAtIndex:_selectedRow];
    GoalCell* deselCell = (GoalCell*) [tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedRow inSection:0]];
    [deselCell deselectedForAchievementId:deselKey];

    _selectedRow = [indexPath row];
    NSString* selKey = [[[AchievementsManager getInstance] orderedAchievementKeys] objectAtIndex:_selectedRow];
    GoalCell* selCell = (GoalCell*) [tv cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedRow inSection:0]];
    [selCell selectedForAchievementId:selKey];
 
    [tv deselectRowAtIndexPath:indexPath animated:YES];
    
    // this causes the rows to animate-adjust when the selected row's height changes
    [tv beginUpdates];
    [tv endUpdates];
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = 40.0f;
    if([indexPath row] == _selectedRow)
    {
        rowHeight = 90.0f;
    }
    return rowHeight;
}

#pragma mark - notifications observer
- (void) handleGimmieDidInit:(NSNotification *)note
{
    [_tableView reloadData];    
    [_tableView setNeedsDisplay];
}

#pragma mark - button actions
- (IBAction)buttonClosePressed:(id)sender
{
    [GameCenterManager getInstance].authenticationDelegate = nil;

    // if we had been pushed by GameViewController, and it had been unloaded because of memory warning
    // then just pop all the way out to the main menu
    UINavigationController* nav = [self navigationController];
    unsigned int stackCount = [[nav viewControllers] count];
    if((stackCount >= 2) && 
       ([[[nav viewControllers] objectAtIndex:(stackCount-2)] isMemberOfClass:[GameViewController class]]) &&
       ([[GameManager getInstance] gameMode] == GAMEMODE_FRONTEND))
    {
        [[AppNavController getInstance] popToRootViewControllerAnimated:YES];
    }
    else 
    {
        [[AppNavController getInstance] popToRightViewControllerAnimated:YES];
    }
}

- (IBAction)buttonGameCenterAchievementsPressed:(id)sender
{
    if(![[GameCenterManager getInstance] isGameCenterAvailable] ||
       ![[GameCenterManager getInstance] isAuthenticated])
    {
        [buttonGameCenter setEnabled:NO];
        [GameCenterManager getInstance].authenticationDelegate = self;
        [[GameCenterManager getInstance] checkAndAuthenticate];        
    }
    
    if([[GameCenterManager getInstance] isGameCenterAvailable])
    {
        if([[GameCenterManager getInstance] isAuthenticated])
        {
            // try to report any achievements that exist locally but not on Game Center
            [[AchievementsManager getInstance] reportAchievementsToGameCenter];
            GKGameCenterViewController* gcViewController = [[GKGameCenterViewController alloc] init];
//            gcViewController.viewState = GKGameCenterViewControllerStateAchievements;
//            gcViewController.gameCenterDelegate = self;
            
            [[SoundManager getInstance] playClip:@"BackForwardButton"];
            [self presentViewController:gcViewController animated:YES completion:nil];
            
            [gcViewController release];
        }
    }    
}

#pragma mark - GameCenterManagerAuthenticationDelegate
- (void) showAuthenticationDialog:(UIViewController *)authViewController {
    [self presentViewController:authViewController animated:YES completion:nil];
}

- (void) didSucceedAuthentication
{
    [buttonGameCenter setEnabled:YES];
}

#pragma mark - GKGameCenterControllerDelegate
- (void) gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self dismissViewControllerAnimated:gameCenterViewController completion:^{
//        gameCenterViewController.gameCenterDelegate = nil;
    }];
}

#pragma mark - AppEventDelegate
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
