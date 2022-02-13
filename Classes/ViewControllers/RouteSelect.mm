//
//  RouteSelect.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/15/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "RouteSelect.h"
#import "AppNavController.h"
#import "GameViewController.h"
#import "SoundManager.h"
#import "RouteInfo.h"
#import "LevelManager.h"
#import "EnvData.h"
#import "StatsManager.h"
#import "MenuResManager.h"
#import "CurryAppDelegate.h"
#import "DebugOptions.h"
#include "MathUtils.h"
#import <QuartzCore/QuartzCore.h>

static const unsigned int NUMROUTEBUTTONS_IN_PAGE = 10;

@interface RouteSelect (PrivateMethods)
- (void) initScrollView;
- (void) shutdownScrollView;
- (void) resetScrollView;
- (void) gotoPage:(unsigned int)pageIndex;
- (void) updateRouteSelectables;
- (void) loadImages;
- (void) showStory;
- (void) initStory;
- (void) shutdownStory;
- (void) loadGameViewControllerFadeInLoading:(BOOL)doFadeLoading animDur:(NSTimeInterval)dur delay:(float)delay;
- (void) gotoGameViewController;
@end

@implementation RouteSelect
@synthesize delegate = _delegate;
@synthesize routeInfos;
@synthesize routePages;
@synthesize storyStarted = _storyStarted;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        _delegate = nil;
    }
    return self;
}

- (void)dealloc 
{
    [[MenuResManager getInstance] removeDelegate:self];
    [self didUnloadFrontendImages];
    [self shutdownStory];
    [loadingScreen release];
    [loadingImageView release];
    [backScrim release];
    [border release];
    [_delegate release];
    [leftArrow release];
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) initScrollView
{
    LevelManager* levelMgr = [LevelManager getInstance];
    self.routeInfos = [NSMutableArray array];

    // init route infos from LevelManager
    NSMutableArray* envNames = [levelMgr getEnvNames];
    unsigned int envIndex = 0;
    for(NSString* curEnvName in envNames)
    {
        if(GAMEMODE_CAMPAIGN == [levelMgr.envData getGameModeForEnvNamed:curEnvName])
        {
            unsigned int numLevels = [levelMgr getNumLevelsForEnv:curEnvName];
            unsigned int nextIncompleteLevel = [[StatsManager getInstance] nextIncompleteLevelForEnv:curEnvName];
#if defined(DEBUG)
            if([[DebugOptions getInstance] isAllLevelsUnlocked])
            {
                nextIncompleteLevel = numLevels;
            }
#endif
            unsigned int levelIndex = 0;
            NSArray* levels = [[levelMgr envData] getLevelsArrayForEnvNamed:curEnvName];
            while(levelIndex < numLevels)
            {
                EnvLevelData* cur = [levels objectAtIndex:levelIndex];
                RouteInfo* info = [[RouteInfo alloc] init];
                info.envName = curEnvName;
                info.envIndex = envIndex;
                info.levelIndex = levelIndex;
                [info setRouteTypeFromName:[cur routeType]];
                info.routeName = [cur routeName];
                info.serviceName = [cur serviceName];
                
                if(levelIndex <= nextIncompleteLevel)
                {
                    info.selectable = YES;
                }
                else
                {
                    info.selectable = NO;
                }
                
                [routeInfos addObject:info];
                [info release];
                
                ++levelIndex;
            }
        }
        ++envIndex;
    }
    
    // scroll view
    numPages = [routeInfos count] / NUMROUTEBUTTONS_IN_PAGE;
    if(([routeInfos count] % NUMROUTEBUTTONS_IN_PAGE) > 0)
    {
        ++numPages;
    }
    currentPage = 0;
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < numPages; i++)
    {
        RouteSelectPage* newController = [[RouteSelectPage alloc] initWithRouteInfosArray:routeInfos fromIndex:(i * NUMROUTEBUTTONS_IN_PAGE)];
        [newController setDelegate:self];
        
        // add the controller's view to the scroll view
        CGRect frame = routeSelectPageView.frame;
        frame.origin.x = frame.size.width * i;
        frame.origin.y = 0;
        newController.view.frame = frame;
        [routeSelectPageView addSubview:newController.view];
        
        [controllers addObject:newController];
        [newController release];
    }
    self.routePages = controllers;
    [controllers release];        
    
    routeSelectPageView.pagingEnabled = YES;
    routeSelectPageView.scrollEnabled = NO;
    routeSelectPageView.contentSize = CGSizeMake(routeSelectPageView.frame.size.width * numPages, routeSelectPageView.frame.size.height);
    routeSelectPageView.showsHorizontalScrollIndicator = NO;
    routeSelectPageView.showsVerticalScrollIndicator = NO;
    routeSelectPageView.scrollsToTop = NO;
    routeSelectPageView.delaysContentTouches = NO;
}

- (void) shutdownScrollView
{
    for(RouteSelectPage* cur in routePages)
    {
        [cur setDelegate:nil];
        [cur.view removeFromSuperview];
    }
    self.routePages = nil;
    self.routeInfos = nil;
}

- (void) resetScrollView
{
    [self gotoPage:0];
}

- (void) gotoPage:(unsigned int)pageIndex
{
    if(pageIndex > numPages)
    {
        pageIndex = numPages - 1;
    }
    currentPage = pageIndex;
    CGRect frame = routeSelectPageView.frame;
    frame.origin.x = frame.size.width * currentPage;
    frame.origin.y = 0;
    [routeSelectPageView scrollRectToVisible:frame animated:YES];
    
    if(pageIndex == (numPages - 1))
    {
        // last page, hide the right arrow
        rightArrow.hidden = YES;
        rightArrow.enabled = NO;
    }
    else
    {
        // otherwise, show it
        rightArrow.hidden = NO;
        rightArrow.enabled = YES;
    }
    if(pageIndex == 0)
    {
        // first page, hide left arrow
        leftArrow.hidden = YES;
        leftArrow.enabled = NO;
    }
    else
    {
        // otherwise, show it
        leftArrow.hidden = NO;
        leftArrow.enabled = YES;
    }
}

- (void) updateRouteSelectables
{
    NSMutableArray* envNames = [[LevelManager getInstance] getEnvNames];
    for(RouteInfo* cur in routeInfos)
    {
        NSString* envName = [envNames objectAtIndex:[cur envIndex]];
        unsigned int nextIncomplete = [[StatsManager getInstance] nextIncompleteLevelForEnv:envName];
#if defined(DEBUG)
        if([[DebugOptions getInstance] isAllLevelsUnlocked])
        {
            nextIncomplete = [cur levelIndex];
        }
#endif
        if(nextIncomplete >= [cur levelIndex])
        {
            cur.selectable = YES;
        }
    }
}

- (void) loadImages
{
    if(randomFrac() <= 0.5f)
    {
        // one half probability we'll show the delivered picture
        loadingImageView.image = [[MenuResManager getInstance] loadImage:@"PeterLoadingScreen_2" isIngame:NO];
    }
    else
    {
        loadingImageView.image = [[MenuResManager getInstance] loadImage:@"LoadingScreen_PeterDelivered" isIngame:NO];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[MenuResManager getInstance] addDelegate:self];

    // init round corners
    [[backScrim layer] setCornerRadius:0.5f];
    [[backScrim layer] setMasksToBounds:YES];
    [[backScrim layer] setBorderWidth:1.0f];
    [[backScrim layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[border layer] setCornerRadius:3.0f];
    [[border layer] setMasksToBounds:YES];
    [[border layer] setBorderWidth:3.0f];
    [[border layer] setBorderColor:[[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.8f] CGColor]];
    
    // init hidden items
    loadingScreen.hidden = YES;
    
    _storyStarted = NO;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        CGRect rect = self.view.frame;
        rect.origin = CGPointMake(-120.0, -420.0);
        self.view.frame = rect;
        
        CGRect loadingRect = loadingScreen.frame;
        loadingRect.origin = CGPointMake(225.0, 520.0);
        loadingScreen.frame = loadingRect;

        CGSize loadingSize = loadingScreen.frame.size;
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        const float iPadScale = (loadingSize.height / loadingSize.width) * (screenSize.width / screenSize.height) ;
        CGAffineTransform t = CGAffineTransformMakeScale(iPadScale, iPadScale);
        [loadingScreen setTransform:t];
    }
    else {
        CGRect contentRect = self.contentView.frame;
        contentRect.origin.y = 10.0;
        self.contentView.frame = contentRect;
        loadingScreen.frame = self.view.bounds;
    }
}

- (void)viewDidUnload
{
    [[MenuResManager getInstance] removeDelegate:self];
    [self didUnloadFrontendImages];
    [self shutdownStory];

    [loadingScreen release];
    loadingScreen = nil;
    [loadingImageView release];
    loadingImageView = nil;
    [backScrim release];
    backScrim = nil;
    [border release];
    border = nil;
    [_delegate release];
    _delegate = nil;
    [leftArrow release];
    leftArrow = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MenuResManager getInstance] addDelegate:self];
    
    [self loadImages];    

    // hide loading screen
    loadingScreen.hidden = YES;
    
    // route select pages
    [self initScrollView];
    [self resetScrollView];
    [self updateRouteSelectables];
    for(RouteSelectPage* cur in routePages)
    {
        [cur updateWithRoutesInfoArray:routeInfos];
        [cur viewWillAppear:animated];
    }
    [self initStory];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [self shutdownStory];
    for(RouteSelectPage* cur in routePages)
    {
        [cur viewDidDisappear:animated];
    }
    [[MenuResManager getInstance] removeDelegate:self];
    [self didUnloadFrontendImages];
    [self shutdownScrollView];
    [super viewDidDisappear:animated];
}

- (void) storySkipButtonPressed:(id)sender
{
    _storySkipped = YES;
    [self loadGameViewControllerFadeInLoading:NO animDur:0.5f delay:0.0f];
}

- (void) skipStoryNow
{
    if(!_storySkipped)
    {
        _storySkipped = YES;
        [self loadGameViewControllerFadeInLoading:NO animDur:1.0 delay:0.0f];
    }
}

- (void) animateStoryPanView
{
    // designate originX and originY to be the left-most position
    // going to the right is going in the negative X direction
    CGFloat originY = [_storyPanSubview frame].size.height * 0.5f;
    CGFloat originX = [_storyPanSubview frame].size.width * 0.5f;
    CGFloat sectionWidth = [_storyPanSubview frame].size.width / 3.0f;

    // for some reason when the CATransaction is finished, it snaps back to an opaque storyPanSubview sitting
    // at the origin position causing annoying one frame anomaly
    // so, just add a timer to skip it before it ends
    [NSTimer scheduledTimerWithTimeInterval:9.0f target:self selector:@selector(skipStoryNow) userInfo:nil repeats:NO];  	
    _storyStarted = YES;
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        if(!_storySkipped)
        {
            _storySkipped = YES;
            
            // go straight to in-game now
            // we get here if the player goes in and out of background
            loadingScreen.hidden = NO;
            loadingScreen.alpha = 1.0f;
            _storyView.hidden = YES;
            _storyStarted = NO;
            [self gotoGameViewController];
        }
    }];
    
    // fade in
    CABasicAnimation* fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.beginTime = 0.0f;
    fadeIn.duration = 0.5f;
    fadeIn.fromValue = [NSNumber numberWithFloat:0.0f];
    fadeIn.toValue = [NSNumber numberWithFloat:1.0f];
    fadeIn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    
    // missing cargo??
    CABasicAnimation* missingCargo = [CABasicAnimation animationWithKeyPath:@"position"];
    missingCargo.beginTime = 1.5f;
    missingCargo.duration = 1.5f;
    missingCargo.fromValue = [NSValue valueWithCGPoint:CGPointMake(originX, originY)];
    missingCargo.toValue = [NSValue valueWithCGPoint:CGPointMake(originX - 160.0f, originY)];
    missingCargo.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    // hold on
    CABasicAnimation* holdOn = [CABasicAnimation animationWithKeyPath:@"position"];
    holdOn.beginTime = 3.0f;
    holdOn.duration = 0.8f;
    holdOn.fromValue = [NSValue valueWithCGPoint:CGPointMake(originX - 160.0f, originY)];
    holdOn.toValue = [NSValue valueWithCGPoint:CGPointMake(originX - 160.0f, originY)];
    
    // look right
    CABasicAnimation* lookRight = [CABasicAnimation animationWithKeyPath:@"position"];
    lookRight.beginTime = 3.8f;
    lookRight.duration = 1.5f;
    lookRight.fromValue = [NSValue valueWithCGPoint:CGPointMake(originX - 160.0f, originY)];
    lookRight.toValue = [NSValue valueWithCGPoint:CGPointMake(originX - (2.0f * sectionWidth), originY)];
    lookRight.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    // look for ship
    CABasicAnimation* lookForShip = [CABasicAnimation animationWithKeyPath:@"position"];
    lookForShip.beginTime = 5.3f;
    lookForShip.duration = 0.4f;
    lookForShip.fromValue = [NSValue valueWithCGPoint:CGPointMake(originX - (2.0f * sectionWidth), originY)];
    lookForShip.toValue = [NSValue valueWithCGPoint:CGPointMake(originX - (1.4f * sectionWidth), originY)];
    lookForShip.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    // found ship
    CABasicAnimation* foundShip = [CABasicAnimation animationWithKeyPath:@"position"];
    foundShip.beginTime = 5.7f;
    foundShip.duration = 0.3f;
    foundShip.fromValue = [NSValue valueWithCGPoint:CGPointMake(originX - (1.4f * sectionWidth), originY)];
    foundShip.toValue = [NSValue valueWithCGPoint:CGPointMake(originX - (1.7f * sectionWidth), originY)];
    foundShip.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    // lookAtShip
    CABasicAnimation* lookAtShip = [CABasicAnimation animationWithKeyPath:@"position"];
    lookAtShip.beginTime = 6.0f;
    lookAtShip.duration = 0.15f;
    lookAtShip.fromValue = [NSValue valueWithCGPoint:CGPointMake(originX - (1.7f * sectionWidth), originY)];
    lookAtShip.toValue = [NSValue valueWithCGPoint:CGPointMake(originX - (1.6f * sectionWidth), originY)];
    lookAtShip.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    // end delay
    CABasicAnimation* endDelay = [CABasicAnimation animationWithKeyPath:@"position"];
    endDelay.beginTime = 6.15f;
    endDelay.duration = 4.5f;
    endDelay.fromValue = [NSValue valueWithCGPoint:CGPointMake(originX - (1.6f * sectionWidth), originY)];
    endDelay.toValue = [NSValue valueWithCGPoint:CGPointMake(originX - (1.6f * sectionWidth), originY)];
    endDelay.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    
    // create an animation group and add the keyframe animation
    CAAnimationGroup *animGroup = [CAAnimationGroup animation];
    animGroup.animations = [NSArray arrayWithObjects:
                            fadeIn, 
                            missingCargo, 
                            holdOn, 
                            lookRight, 
                            lookForShip, 
                            foundShip,
                            lookAtShip,
                            endDelay,
                            nil];
    
    // set the timing function for the group and the animation duration
    animGroup.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animGroup.duration = 10.65f;

    [[_storyPanSubview layer] addAnimation:animGroup forKey:@"animateStory"];

    [CATransaction commit];
}

- (void) showStory
{
    _storyView.hidden = NO;
    NSArray* imageNames = [NSArray arrayWithObjects:@"IntroCutScene_1_01.png", 
                           @"IntroCutScene_1_02.png", 
                           @"IntroCutScene_1_03.png", 
                           nil];
    
    unsigned int index = 0;
    for(UIImageView* cur in [_storyPanSubview subviews])
    {
        cur.image = [[MenuResManager getInstance] loadImage:[imageNames objectAtIndex:index] isIngame:NO];
        ++index;
        if(2 < index)
        {
            index = 2;
        }
    }

    // hook up skip button
    _storySkipped = NO;
    [_storyView addSubview:_storySkipButton];
    
    _storyView.alpha = 1.0f;
    [self animateStoryPanView];
}

- (void) initStory
{
    CGRect windowFrame = self.view.window.frame;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        // this is basically 320x480 res in iPad aspect-ratio
        windowFrame = CGRectMake(-20.0f, -30.0f, 360.0f, 540.0f);
    }
    CGRect storyFrame = CGRectMake(0.0f, 0.0f, windowFrame.size.width * 3.0f, windowFrame.size.height);
    
    _storyView = [[UIView alloc] initWithFrame:windowFrame];
    _storyPanSubview = [[UIView alloc] initWithFrame:storyFrame];
    for(unsigned int index = 0; index < 3; ++index)
    {
        CGRect myFrame = windowFrame;
        myFrame.origin.x = (windowFrame.size.width * index);
        myFrame.origin.y = 0.0f;
        UIImageView* storyPage = [[UIImageView alloc] initWithFrame:myFrame];
        [_storyPanSubview addSubview:storyPage];
        [storyPage release];
    }

    [_storyView addSubview:_storyPanSubview];
    _storySkipButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    [_storySkipButton addTarget:self action:@selector(storySkipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _storySkipButton.frame = windowFrame;
    [self.view insertSubview:_storyView aboveSubview:loadingScreen];
    
    [_storyView setHidden:YES];
    
    _storyStarted = NO;
}

- (void) shutdownStory
{
    if(_storyPanSubview)
    {
        [_storyPanSubview removeFromSuperview];
        [_storyPanSubview release];
        _storyPanSubview = nil;
    }
    if(_storySkipButton)
    {
        [_storySkipButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [_storySkipButton removeFromSuperview];
        [_storySkipButton release];
        _storySkipButton = nil;
    }
    if(_storyView)
    {
        [_storyView removeFromSuperview];
        [_storyView release];
        _storyView = nil;
    }
}

- (void) gotoGameViewController
{
    // unload frontend images
    [[MenuResManager getInstance] unloadFrontendImages];
    
    // load game
    GameViewController* controller = [[GameViewController alloc] init];
    [[AppNavController getInstance] pushViewController:controller animated:NO];
    [controller release]; 
}

- (void) loadGameViewControllerFadeInLoading:(BOOL)doFadeLoading animDur:(NSTimeInterval)dur delay:(float)delay
{
    // show loading screen
    loadingScreen.hidden = NO;
    _storyStarted = NO;
    if(doFadeLoading)
    {
        loadingScreen.alpha = 0.0f;
        [UIView animateWithDuration:dur
                              delay:delay
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ 
                             loadingScreen.alpha = 1.0f;
                             _storyView.alpha = 0.0f;
                         }
                         completion:^(BOOL finished){
                             _storyView.hidden = YES;
                             [self gotoGameViewController];
                         }];
    }
    else
    {
        loadingScreen.alpha = 1.0f;
        [UIView animateWithDuration:dur
                              delay:delay
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{ 
                             _storyView.alpha = 0.0f;
                         }
                         completion:^(BOOL finished){
                             _storyView.hidden = YES;
                             [self gotoGameViewController];
                         }];
    }
}

#pragma mark - RouteSelectPageDelegate

- (void) selectRouteNum:(unsigned int)num
{
    if(num < [routeInfos count])
    {
        RouteInfo* curInfo = [routeInfos objectAtIndex:num];
        if([curInfo selectable])
        {
            NSString* selectedEnvName = [[[LevelManager getInstance] getEnvNames] objectAtIndex:[curInfo envIndex]];
            [[LevelManager getInstance] selectEnvNamed:selectedEnvName level:num];
            
            // play button
            [[SoundManager getInstance] playClip:@"ButtonPressed"];
            
            // start in-game music
            [[SoundManager getInstance] playMusic:@"Ingame0" doLoop:YES];
            [[SoundManager getInstance] playMusic2:@"Ambient1" doLoop:YES];
            
//            if(0 == num)
//            {
//                // if first route, show story then load game
//                [self showStory];
//            }
//            else
            {
                // otherwise, load game straight away
                [self loadGameViewControllerFadeInLoading:YES animDur:0.5f delay:0.0f];
            }
        }
    }
}


#pragma mark - Navigation
- (IBAction)dismissButtonPressed:(id)sender
{
    if([self delegate])
    {
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
        [self.delegate dismissRouteSelectAnimated:YES];
    }    
}

- (IBAction)backButtonPressed:(id)sender
{
    if(currentPage > 0)
    {
        [self gotoPage:currentPage-1];
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
    }
}

- (IBAction)nextPage:(id)sender
{
    if(currentPage < numPages)
    {
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
        [self gotoPage:currentPage+1];
    }
}

#pragma mark - MenuResDelegate
- (void) didUnloadFrontendImages
{
    if(loadingImageView)
    {
        loadingImageView.image = nil;
    }
    for(RouteSelectPage* cur in routePages)
    {
        [cur unloadButtonImages];
    }
    for(UIImageView* cur in _storyPanSubview.subviews)
    {
        cur.image = nil;
    }
}

- (void) didUnloadIngameImages
{
    
}

@end
