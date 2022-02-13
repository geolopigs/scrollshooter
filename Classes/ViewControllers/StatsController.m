//
//  StatsController.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "StatsController.h"
#import "AppNavController.h"
#import "StatsCell.h"
#import "StatsManager.h"
#import "GameCenterManager.h"
#import "SoundManager.h"
#import <QuartzCore/QuartzCore.h>
#import <GameKit/GameKit.h>

enum StatsDisplayItems
{
    STATS_DISPLAY_HIGHSCORE = 0,
    STATS_DISPLAY_PIGGYBANK,
    STATS_DISPLAY_CARGOSDELIVERED,
    STATS_DISPLAY_COINSCOLLECTED,
    STATS_DISPLAY_FLIGHTTIME,
    STATS_DISPLAY_HIGHMULTIPLIER,
    STATS_DISPLAY_TOURNEYWINS,
    
    // Tourney highscore
    STATS_DISPLAY_TOURNEYHIGH_ROUTE1,
    
    // Homebase highscores
    STATS_DISPLAY_HIGHSCORE_ROUTE1,
    STATS_DISPLAY_HIGHSCORE_ROUTE2,
    STATS_DISPLAY_HIGHSCORE_ROUTE3,
    STATS_DISPLAY_HIGHSCORE_ROUTE4,
    STATS_DISPLAY_HIGHSCORE_ROUTE5,
    STATS_DISPLAY_HIGHSCORE_ROUTE6,
    STATS_DISPLAY_HIGHSCORE_ROUTE7,
    STATS_DISPLAY_HIGHSCORE_ROUTE8,
    STATS_DISPLAY_HIGHSCORE_ROUTE9,
    STATS_DISPLAY_HIGHSCORE_ROUTE10,
    
    STATS_DISPLAY_NUM
};

@interface StatsController (PrivateMethods) <GKGameCenterControllerDelegate>
- (void) initTitleNames;
- (NSString*) titleForItem:(unsigned int)itemEnum;
- (void) cell:(StatsCell*)cell refreshContentForItem:(unsigned int)itemEnum;
@end

@implementation StatsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        [self initTitleNames];
    }
    return self;
}

- (void)dealloc 
{
    [_titleNames release];
    [_tableView release];
    [_buttonGameCenter release];
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
}

- (void)viewDidUnload
{
    [_tableView release];
    _tableView = nil;
    [_buttonGameCenter release];
    _buttonGameCenter = nil;
    [border release];
    border = nil;
    [_contentView release];
    _contentView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - buttons

- (IBAction)buttonBackPressed:(id)sender 
{
    [GameCenterManager getInstance].authenticationDelegate = nil;
    [[AppNavController getInstance] popToRightViewControllerAnimated:YES];
}

- (IBAction)buttonGameCenterPressed:(id)sender 
{
    if(![[GameCenterManager getInstance] isGameCenterAvailable] ||
       ![[GameCenterManager getInstance] isAuthenticated])
    {
        [_buttonGameCenter setEnabled:NO];
        [GameCenterManager getInstance].authenticationDelegate = self;
        [[GameCenterManager getInstance] checkAndAuthenticate];        
    }

    if([[GameCenterManager getInstance] isGameCenterAvailable])
    {
        if([[GameCenterManager getInstance] isAuthenticated])
        {
            // report any outstanding scores
            [[StatsManager getInstance] reportScoresToGameCenter];
            GKGameCenterViewController* gcViewController = [GKGameCenterViewController new];
//            gcViewController.viewState = GKGameCenterViewControllerStateDefault;
//            gcViewController.gameCenterDelegate = self;
            
            [[SoundManager getInstance] playClip:@"BackForwardButton"];
            [self presentViewController:gcViewController animated:YES completion:nil];

            [gcViewController release];
        }
    }
}

#pragma mark - interface with StatsManager

- (void) initTitleNames
{
    _titleNames = [[NSArray arrayWithObjects:@"High Score:",
                    @"Pogcoins Stash:",
                    @"Cargos Delivered:",
                    @"Pogcoins Earned:",
                    @"Flight Time:",
                    @"Highest Multiplier:",
                    @"Tourney Wins:",
                    @"Tourney High Score:",
                    @"Route 1 High Score:",
                    @"Route 2 High Score:",
                    @"Route 3 High Score:",
                    @"Route 4 High Score:",
                    @"Route 5 High Score:",
                    @"Route 6 High Score:",
                    @"Route 7 High Score:",
                    @"Route 8 High Score:",
                    @"Route 9 High Score:",
                    @"Route 10 High Score:",
                    nil] retain];
}

- (void) cell:(StatsCell*)cell refreshContentForItem:(unsigned int)itemEnum
{
    if(itemEnum < STATS_DISPLAY_NUM)
    {
        StatsManager* statsMgr = [StatsManager getInstance];
        [cell setTitleText:[_titleNames objectAtIndex:itemEnum]];
        [cell hideCoinIcon];
        switch (itemEnum) {
            case STATS_DISPLAY_FLIGHTTIME:
                [cell setValueWithTime:[statsMgr getTotalFlightTime]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE:
                [cell setValueWithInt:[statsMgr getHighscore]];
                 break;
                 
            case STATS_DISPLAY_PIGGYBANK:
                [cell setValueWithInt:[statsMgr getTotalCash]];
                [cell showCoinIcon];
                break;
                
            case STATS_DISPLAY_CARGOSDELIVERED:
                [cell setValueWithInt:[statsMgr getCargosDelivered]];
                break;
                
            case STATS_DISPLAY_COINSCOLLECTED:
                [cell setValueWithInt:[statsMgr getCoinsCollected]];
                [cell showCoinIcon];
                break;
                
            case STATS_DISPLAY_HIGHMULTIPLIER:
                [cell setValueWithMultiplier:[statsMgr highestMultiplier]];
                break;
                
            case STATS_DISPLAY_TOURNEYWINS:
                [cell setValueWithInt:[statsMgr getTourneyWins]];
                break;
                
            case STATS_DISPLAY_TOURNEYHIGH_ROUTE1:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Tourney" level:0]];
                 break;
                 
            case STATS_DISPLAY_HIGHSCORE_ROUTE1:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:0]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE2:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:1]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE3:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:2]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE4:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:3]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE5:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:4]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE6:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:5]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE7:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:6]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE8:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:7]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE9:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:8]];
                break;
                
            case STATS_DISPLAY_HIGHSCORE_ROUTE10:
                [cell setValueWithInt:[statsMgr getHighscoreForEnv:@"Homebase" level:9]];
                break;
                                
            default:
                [cell setValueWithInt:0];
                break;
        }
    }
}

#pragma mark UITableViewDataSource Methods 



- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"StatsCell";
    StatsCell* cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
    if( nil == cell ) 
    {
        cell = [[StatsCell alloc] initWithReuseIdentifier:cellIdentifier 
                                                 cellSize:CGSizeMake(tv.bounds.size.width, STATSCELL_HEIGHT)];
    }

    // alternate row colors
    if(0 == ([indexPath row] % 2))
    {
        [cell.contentView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.2f]];
    }
    else
    {
        [cell.contentView setBackgroundColor:[UIColor clearColor]];
    }
  
    // refresh the content
    [self cell:cell refreshContentForItem:[indexPath row]];
    
    return (UITableViewCell*) cell;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = STATS_DISPLAY_NUM;
    return numRows;
}


#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // do nothing
}




- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat result = STATSCELL_HEIGHT;
    return result;
}

#pragma mark - GameCenterManagerAuthenticationDelegate
- (void) showAuthenticationDialog:(UIViewController *)authViewController {
    [self presentViewController:authViewController animated:YES completion:nil];
}

- (void) didSucceedAuthentication
{
    [_buttonGameCenter setEnabled:YES];
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

#pragma mark - GKGameCenterControllerDelegate
- (void) gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self dismissViewControllerAnimated:gameCenterViewController completion:^{
//        gameCenterViewController.gameCenterDelegate = nil;
    }];
}

@end
