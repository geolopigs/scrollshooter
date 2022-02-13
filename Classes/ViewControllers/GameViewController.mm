//
//  GameViewController.mm
//
//

#import "GameViewController.h"
#import "AppNavController.h"
#import "AppRendererConfig.h"
#import "GameGLView.h"
#import "RendererGLView.h"
#import "AnimProcessor.h"
#import "MenuResManager.h"
#import "GameManager.h"
#import "PlayerInventory.h"
#import "PlayerInventoryIds.h"
#import "LevelManager.h"
#import "DynamicManager.h"
#import "RenderBucketsManager.h"
#import "PanController.h"
#import "CollisionManager.h"
#import "LevelCompletedScreen.h"
#import "SoundManager.h"
#import "ScoreHud.h"
#import "GameOverScreen.h"
#import "StatsManager.h"
#import "AchievementsManager.h"
#import "CurryAppDelegate.h"
#import "StoreMenu.h"
#import "StatsController.h"
#import "GoalsMenu.h"
#import "TutorialController.h"
#import "PogAnalytics+PeterPog.h"
#import "GimmieEventIds.h"
#import "StatsManager.h"
#if defined(DEBUG)
#import "DebugOptions.h"
#endif
#import <iAd/iAd.h>

// constants
static const float GAMEVIEW_WIDTH = 16.0f;
static const float GAMEVIEW_HEIGHT = 24.0f;
static const float GAMEVIEW_WIDTH_IPAD = 18.0f;
static const float GAMEVIEW_HEIGHT_IPAD = 24.0f;
static const CGFloat GAMELOOP_INTERVAL_SECS = 1.0f / 30.0f;
static const CGFloat SIMTIMER_INTERVAL_SECS = 1.0f / 30.0f;
static const CGFloat SIMTIMER_INTERVAL_MAX = 1.0f / 15.0f;

// pause menu constants
static const float PAUSEMENU_OUTPOS_X = 0.4f;
static const float PAUSEMENU_INPOS_X = 0.0f;
static const float PAUSEMENU_OUTPOS_Y = 0.0f;
static const float PAUSEMENU_INPOS_Y = 0.0f;
static const float PAUSEMENU_ANIMDURATION = 0.3f;

// game over sequence length
static const float GAMEOVERSEQUENCE_LENGTH = 1.5f;  // seconds
static const float GAMEOVERAUTODIM_LENGTH = 0.5f;
static const float GAMEOVERAUTODIM_DELAY = 4.0f;
static const float LEVELSTATS_LENGTH = 2.0f;


// timebased mode
static const float TIMEBASED_PLAYER_RESPAWN_DELAY = 2.0f;

@interface GameViewController () <ADBannerViewDelegate>
@property (nonatomic, retain) ADBannerView* adBannerView;

- (void) initGameView;
- (void) shutdownGameView;
- (void) initGameLoop;
- (void) shutdownGameLoop;
- (void) initGestureRecognizers;
- (void) shutdownGestureRecognizers;
- (NSTimeInterval)advanceTimer;
- (void) renderTick;
- (void) simTick:(NSTimeInterval)elapsed;
- (void) gameLoop;
- (void) updateGameState:(NSTimeInterval)elapsed;
- (void) showLevelCompletedScreen;
- (void) proceedToNextRoute;
- (void) showContinueScreen;
- (BOOL) isContinueScreenVisible;
- (void) showGameOverSequence;
- (void) dismissGameOverSequenceAndShowLoading:(BOOL)showLoading;
- (void) registerNextpeerNotifications;
- (void) exitGameFinishCurrentLevel:(BOOL)finishLevel;
- (void) showTutorialWithScrim:(BOOL)scrimOn;
- (void) closeTutorial;
@end

@implementation GameViewController
@synthesize pauseMenu;
@synthesize levelCompletedScreen;
@synthesize continueScreen;
@synthesize tutorial = _tutorial;
@synthesize scoreHud;
@synthesize gameOverScreen;
@synthesize gameState;
@synthesize flightController = _flightController;
- (id) init
{
	if((self = [super init]))
	{
        self.pauseMenu = nil;
        self.levelCompletedScreen = nil;
        doneWithCompletedScreen = NO;
        self.continueScreen = nil;
        willContinue = NO;
        self.gameOverScreen = nil;
        _tutorial = nil;
        self.scoreHud = nil;
        gameState = GAME_STATE_INGAME;
        self.flightController = nil;
        _startTimebasedGame = NO;
        _isMultiplayerTourney = NO;
        _shouldRelaunchNPDashboard = NO;
        _levelStatsTimer = 0.0f;
        _statsCompletedCurLevel = NO;
        _shouldExitFromGameOver = NO;
        _postGameOverFlags = POSTGAMEOVER_FLAG_NONE;
		[self initGameView];
	}
	return self;
}

- (void)dealloc 
{
	[self shutdownGameView];
    [GameManager getInstance].gameMode = GAMEMODE_FRONTEND;
    
    self.flightController = nil;
    
    // release hud
    [GameManager getInstance].hudDelegate = nil;
    [StatsManager getInstance].delegate = nil;
    [_tutorial release];
    self.scoreHud = nil;
    self.gameOverScreen = nil;
    self.continueScreen = nil;
    self.levelCompletedScreen = nil;
    self.pauseMenu = nil;
    [super dealloc];
}

- (void) loadView
{
    UIView* containerView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    UIView* glView = [gameView rendererView];
    [glView setMultipleTouchEnabled:YES];
    [containerView addSubview:glView];
    [containerView setMultipleTouchEnabled:YES];
	self.view = containerView;
}


- (void)viewDidLoad 
{
    [super viewDidLoad];

    GameMode gameMode = [[LevelManager getInstance] gameModeForSelectedEnv];
    if(GAMEMODE_TIMEBASED == gameMode)
    {
        // UI - no pause button in Timebased mode
        buttonPause = nil;
    }
    else
    {
        // UI - pause button
        buttonPause = [[[MenuResManager getInstance] buttonPause] retain];
        [buttonPause addTarget:self action:@selector(buttonPausePressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:buttonPause];
    }    
    // UI - hud; add as subview and assign to stats-manager as delegate
    ScoreHud* newHud = [[ScoreHud alloc] initWithNibName:[CurryAppDelegate getXibNameFor:@"ScoreHud"] bundle:nil];
    self.scoreHud = newHud;
    [StatsManager getInstance].delegate = newHud;   
    [GameManager getInstance].hudDelegate = newHud;
    if(GAMEMODE_TIMEBASED == gameMode)
    {
        // setup additional tourney HUD components
        // can't just call GameManager for gameMode from inside ScoreHud viewDidLoad because
        // GameManager will not be setup until later in initGameLoop
        [newHud setupTourneyComponents];
    }
    [newHud release];
    [self.view addSubview:self.scoreHud.view];
    
    CGFloat aspectRatio = self.view.bounds.size.height / self.view.bounds.size.width;
    if(aspectRatio > 1.5) {
        // only show ad banner where we have sufficient room for it (namely longer screens)s
        [self setupADBanner];
    }
    
    _shouldExitFromGameOver = NO;
    _postGameOverFlags = POSTGAMEOVER_FLAG_NONE;
    [self initGameLoop];

    // process one frame so that there would be something to show right away
    [self gameLoop];
}

- (void)viewDidUnload 
{
    [[GameManager getInstance] exitCurrentLevel];
    [[GameManager getInstance] exitGame];
    
    [self shutdownGameLoop];
    [self shutdownGameView];
    /*
    // remove score hud
    [self.scoreHud.view removeFromSuperview];
    [GameManager getInstance].hudDelegate = nil;
    [StatsManager getInstance].delegate = nil;
    self.scoreHud = nil;

    // remove pause button
    if(buttonPause)
    {
        [buttonPause removeTarget:self action:@selector(buttonPausePressed) forControlEvents:UIControlEventTouchUpInside];
        [buttonPause removeFromSuperview];
        [buttonPause release];
        buttonPause = nil;
    }

    // remove LevelCompleted
    if([self levelCompletedScreen])
    {
        [self.levelCompletedScreen.view removeFromSuperview];
        self.levelCompletedScreen = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self]; 
    */
    [GameManager getInstance].gameMode = GAMEMODE_FRONTEND;
    [super viewDidUnload];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect renderFrame = [gameView rendererView].frame;
    renderFrame.origin.x = 0.5 * (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(renderFrame));
    renderFrame.origin.y = 0.5 * (CGRectGetHeight(self.view.bounds) - CGRectGetHeight(renderFrame));
    [gameView rendererView].frame = renderFrame;
    
    if(self.scoreHud.view.superview == self.view) {
        CGRect rect = self.scoreHud.view.frame;
        rect.origin = CGPointMake(0.0, 0.5 * (self.view.bounds.size.height - rect.size.height));
        self.scoreHud.view.frame = rect;
    }
    [self layoutADBannerAnimated:NO];
}

/*
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL) shouldUpdateSim
{
    return _shouldUpdateSim;
}

- (void) setShouldUpdateSim:(BOOL)shouldUpdateSim
{
    _shouldUpdateSim = shouldUpdateSim;
    
    if(shouldUpdateSim)
    {
        // also enable pan controller
        [self.flightController setEnabled:YES];
        [self.flightController reset];
    }
    else
    {
        [self.flightController setEnabled:NO];
        [self.flightController reset];
    }
}

#pragma mark -
#pragma mark Private Methods
- (void) initGameView
{
	// init GL stuff
	GameGLViewConfig* config = [[GameGLViewConfig alloc] init];
	[config setClearColorRed:0.0f green:0.8f blue:0.9f];
    
    config.viewportSize = [[AppRendererConfig getInstance] getViewportFrame].size;
	gameView = [(GameGLView*)[GameGLView alloc] initWithConfig:config];
	
	[config release];
}

- (void) shutdownGameView
{    
    // remove pause button
    if(buttonPause)
    {
        [buttonPause removeTarget:self action:@selector(buttonPausePressed) forControlEvents:UIControlEventTouchUpInside];
        [buttonPause removeFromSuperview];
        [buttonPause release];
        buttonPause = nil;
    }
    
	// GL stuff
	[gameView release];
    gameView = nil;
}

- (void) initGameLoop
{
    if(![[PlayerInventory getInstance] doesHangarHaveFlyer:[[GameManager getInstance] flyerId]])
    {
        // this should not happen, but in case there's a bug in the frontend UI that lets this slit through,
        // always revert to Poglider if we get here with a flyer not yet purchased;
        [[GameManager getInstance] setFlyerId:(NSString*)FLYER_ID_POGLIDER];
    }
    
    self.shouldUpdateSim = YES;
    shouldUpdateDraw = YES;
    GameMode gameMode = [[LevelManager getInstance] gameModeForSelectedEnv];
    if(GAMEMODE_TIMEBASED == gameMode)
    {
        [GameManager getInstance].gameTimeRemaining = [[LevelManager getInstance] tourneyGameTime];
        gameState = GAME_STATE_TIMEBASED_PRESTART;
        _startTimebasedGame = NO;
        _isMultiplayerTourney = NO;
        [self.scoreHud useTourneyScoreHudEntry];
        [self.scoreHud fadeInLoading:0.0f];
    }
    else
    {
        if([[StatsManager getInstance] hasCompletedTutorial])
        {
            gameState = GAME_STATE_INGAME;
        }
        else
        {
            gameState = GAME_STATE_TUTORIAL;
        }
        [[PogAnalytics getInstance] logJourneyBegan];
    }
    [GameManager getInstance].gameMode = gameMode;
    [[GameManager getInstance] newGame];
	gameLoopTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) GAMELOOP_INTERVAL_SECS
												   target:self 
												 selector:@selector(gameLoop) 
												 userInfo:nil 
												  repeats:YES];
	prevTick = [NSDate timeIntervalSinceReferenceDate];	
    
    [self initGestureRecognizers];
    
    if(GAME_STATE_TIMEBASED_PRESTART == gameState)
    {
        self.shouldUpdateSim = NO;
    }
    else if(GAME_STATE_TUTORIAL == gameState)
    {
        // show tutorial
        [self showTutorialWithScrim:NO];

        self.shouldUpdateSim = NO;
    }
}

- (void) shutdownGameLoop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self]; 
    
    // remove tutorial
    if(_tutorial)
    {
        [_tutorial.view removeFromSuperview];
        [_tutorial release];
        _tutorial = nil;
    }
    
    // remove pause
    if([self pauseMenu])
    {
        [self.pauseMenu.view removeFromSuperview]; 
        self.pauseMenu = nil; 
    }
    
    // remove score hud
    [[MenuResManager getInstance] unloadIngameImages];
    [self.scoreHud.view removeFromSuperview];
    [GameManager getInstance].hudDelegate = nil;
    [StatsManager getInstance].delegate = nil;
    self.scoreHud = nil;
    
    // game over screen
    if([self gameOverScreen])
    {
        [self.gameOverScreen.view removeFromSuperview];
        self.gameOverScreen = nil;
    }
    
    // remove LevelCompleted
    if([self levelCompletedScreen])
    {
        [self.levelCompletedScreen.view removeFromSuperview];
        self.levelCompletedScreen = nil;
    }
    
    [self shutdownGestureRecognizers];
    if(gameLoopTimer)
    {
        [gameLoopTimer invalidate];
        gameLoopTimer = nil;
    }
    [[GameManager getInstance] exitGame];
    self.shouldUpdateSim = NO;
    shouldUpdateDraw = NO;
        
    // stop both music tracks
    [[SoundManager getInstance] stopMusic];
    [[SoundManager getInstance] stopMusic2];
}

- (void) initGestureRecognizers
{
    PanController* panController = [[PanController alloc] initWithFrameSize:self.view.frame.size target:[GameManager getInstance] action:@selector(handlePanControl:)];
    self.flightController = panController;
    
    // set this to NO so that all touch events that have been recognized still get passed through to the View
    // otherwise, the pause menu button would not respond
//    panController.cancelsTouchesInView = NO;
//    [self.view addGestureRecognizer:panController];
    [[GameManager getInstance] setPanController:panController];
    [panController release];
}

- (void) shutdownGestureRecognizers
{
//    [self.view removeGestureRecognizer:[[GameManager getInstance] panController]];
    [[GameManager getInstance] setPanController:nil];
    self.flightController = nil;
}

//! \brief
//	This function advances the timer and returns the elapsed time since the last advance
- (NSTimeInterval) advanceTimer
{
	NSTimeInterval curTick = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval elapsed = curTick - prevTick;
	if(elapsed < SIMTIMER_INTERVAL_SECS)
	{
		elapsed = SIMTIMER_INTERVAL_SECS;
	}
	else if(elapsed > SIMTIMER_INTERVAL_MAX)
	{
		elapsed = SIMTIMER_INTERVAL_MAX;
	}
	prevTick = curTick;	
	return elapsed;
}

- (void) gameLoop
{
	NSTimeInterval elapsed = [self advanceTimer];
	
    if(shouldUpdateDraw)
    {
        [[RenderBucketsManager getInstance] clearAllCommands];
    }
    [self simTick:elapsed];
    [self renderTick];
    
    // perform state transitions when needed
    [self updateGameState:elapsed];
}

- (void) simTick:(NSTimeInterval)elapsed
{
    if([self shouldUpdateSim])
    {
//        [[GameManager getInstance] handlePanControl:[self flightController]];
        [[GameManager getInstance] update:elapsed];
        [[DynamicManager getInstance] setViewConstraintFromGame:[[GameManager getInstance] getPlayArea]];
        [[DynamicManager getInstance] update:elapsed isPaused:NO];
    
        // HACK - because of interdependency with delayed delete in the CollisionManager
        // it is possible that a shot get purged from CollisionManager, which has collected its garbage in
        // the previous frame; so, double clean it here
        // TODO: move all garbage collection into a manager that processes at the end of the frame
        // retire shots 
        [[CollisionManager getInstance] collectGarbage];    
        // HACK
    
        [[CollisionManager getInstance] processDetection:elapsed];
        [[CollisionManager getInstance] processResponse:elapsed];
        [[AnimProcessor getInstance] advanceClips:elapsed];
        [[GameManager getInstance] postDynamicUpdate:elapsed];
        [[CollisionManager getInstance] collectGarbage];
    }
    
    if(shouldUpdateDraw)
    {
        // add to draw list
        [[GameManager getInstance] addDraw];
        [[DynamicManager getInstance] addDraw];
    }
}

- (void) renderTick
{
	[gameView beginFrame];
	[[RenderBucketsManager getInstance] execCommands];
	[gameView endFrame];
}

- (void) updateGameState:(NSTimeInterval)elapsed
{
    // perform state transition
    switch(gameState)
    {
        case GAME_STATE_TUTORIAL:
            
            break;
            
        case GAME_STATE_INGAME:
#if defined(DEBUG)
            if([[DebugOptions getInstance] debugLevelCompletion])
            {
                float debugTimer = [[DebugOptions getInstance] debugLevelCompletionTimeout];
                debugTimer -= elapsed;
                [[DebugOptions getInstance] setDebugLevelCompletionTimeout:debugTimer];
            }
            if(([[GameManager getInstance] isAtEndOfLevel]) || 
               (([[DebugOptions getInstance] debugLevelCompletion]) &&
                ([[DebugOptions getInstance] debugLevelCompletionTimeout] <= 0.0f)))
#else
            if([[GameManager getInstance] isAtEndOfLevel])
#endif
            {
                // compute final score and commit stats
                if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
                {
                    [[GameManager getInstance] finishCurrentLevel];
                    [[StatsManager getInstance] completeTimebasedLevel];
                    [scoreHud hideForLevelCompletion];
                    if(_isMultiplayerTourney)
                    {
                        [scoreHud fadeInLoading:1.0f];
                        if(_shouldRelaunchNPDashboard)
                        {
                            // if app had entered background in the middle of a tourney, then 
                            // the NP dashboard needs to be relaunched at the end of a tourney; 
                            // otherwise, it won't show anything
//                            [Nextpeer launchDashboard];
                            _shouldRelaunchNPDashboard = NO;
                        }
                        gameState = GAME_STATE_TIMEBASED_NEXTPEER_POSTGAME;
                    }
                    else
                    {
                        // TODO: replace this with a TIMEBASED specific end screen
                        gameState = GAME_STATE_LEVELCOMPLETED;
                        doneWithCompletedScreen = NO;
                        [self showLevelCompletedScreen];                        
                    }
                    [[SoundManager getInstance] stopMusic];
                    [[SoundManager getInstance] stopMusic2];
                }
                else
                {
                    // disallow sound clips in Campaign mode to prevent spill over finishCurrentLevel-killEnemmies sounds
                    [[SoundManager getInstance] disallowPlayClip];
                    [[GameManager getInstance] finishCurrentLevel];
                    [[SoundManager getInstance] allowPlayClip];

                    if(!_statsCompletedCurLevel)
                    {
                        // if for some reason stats not yet committed, commit stats here
                        // this would happen if the level doesn't have a showRouteCompleted trigger
                        [[StatsManager getInstance] completeLevel];
                        _statsCompletedCurLevel = YES;
                        [scoreHud hideForLevelCompletion];
                    }
                    gameState = GAME_STATE_LEVELCOMPLETED;
                    doneWithCompletedScreen = NO;

                    // show loading screen
                    [scoreHud fadeInNoImageLoading:0.2f delay:0.0f];
                }
            }
            else if([[GameManager getInstance] isPlayerDead])
            {
                // stop main scroll
                [[GameManager getInstance] stopScrollCam];
                gameState = GAME_STATE_PLAYERDEAD;

                if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
                {
                    // in TIMEBASED mode, disablePan and go to the PLAYERDEAD state
                    [[GameManager getInstance] disablePanControl];
                }
                else
                {                    
                    if([[StatsManager getInstance] continuesRemaining] > 0)
                    {
                        [self showContinueScreen];                
                    }
                }
            }
            else if([[GameManager getInstance] shouldShowRouteCompleted])
            {
                // commit level stats
                [[StatsManager getInstance] completeLevel];
                _statsCompletedCurLevel = YES;
                
                // show the RouteCompleted screen
                [self showLevelCompletedScreen];                
            }
            break;
            
        case GAME_STATE_LEVELCOMPLETED:
            if(0.0f < _levelStatsTimer)
            {
                _levelStatsTimer -= elapsed;
            }
            if(0.0f >= _levelStatsTimer)
            {
                _levelStatsTimer = 0.0f;
                
                // proceed to next
                [self proceedToNextRoute];

                // after loading, move on to INGAME
                gameState = GAME_STATE_INGAME;
                [scoreHud unhideForLevelCompletion];
                [scoreHud fadeOutLoading:0.3f];                
                [[GameManager getInstance] enablePanControl];
            }
            break;
            
        case GAME_STATE_PLAYERDEAD:
            if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
            {
                // in TIMEBASED mode, keep respawning the player
                gameState = GAME_STATE_INGAME;
                if(TIMEBASED_PLAYER_RESPAWN_DELAY < [[GameManager getInstance] gameTimeRemaining])
                {
                    [[GameManager getInstance] restartTriggers];
                    [[GameManager getInstance] respawnPlayerAfterDelay:TIMEBASED_PLAYER_RESPAWN_DELAY];
                    [[GameManager getInstance] startScrollCam];
                    [[GameManager getInstance] enablePanControl];
                }
            }
            else
            {
                if(![self isContinueScreenVisible])
                {
                    // when continue screen has been dismissed, 
                    
                    if(willContinue)
                    {
                        // if continue, go back to INGAME
                        gameState = GAME_STATE_INGAME;
                        willContinue = NO;
                        
                        // clear stats
                        [[StatsManager getInstance] resetCargosCur];
                        [[StatsManager getInstance] resetScoreMultiplier];
                        
                        // spawn and resume game
                        [[GameManager getInstance] respawnPlayerAfterDelay:0.0f];
                        [[GameManager getInstance] startScrollCam];
                    }
                    else
                    {
                        // game session is done, complete it for stats
                        [[StatsManager getInstance] completeGameSessionWithCoins:YES];
                        
                        // play game over sequence
                        gameState = GAME_STATE_GAMEOVERSEQUENCE;
                        gameOverTimer = GAMEOVERSEQUENCE_LENGTH;
                    }
                }
            }
            break;
            
        case GAME_STATE_GAMEOVERSEQUENCE:
            if(0.0f < gameOverTimer)
            {
                gameOverTimer -= elapsed;
                if(0.0f >= gameOverTimer)
                {
                    [self showGameOverSequence];
                }
            }
            else
            {
                /*
                gameOverStopSimTimer -= elapsed;
                if((0.0f >= gameOverStopSimTimer) && (_shouldUpdateSim))
                {
                    // when game over stop-sim timer is up (this is timed to be about the same
                    // as when the loading screen is faded in); pause the Sim;
                    // it is ok to pause the sim here because we are guaranteed
                    // to exit the game already at this point;
                    // pausing the Sim would stop any enemies from making unwanted sound effects 
                    // during GameOverScreen
                    _shouldUpdateSim = NO;
                }
                 */
                if(_shouldExitFromGameOver)
                {
                    gameState = GAME_STATE_EXITGAME;
                }
                else if(willContinue)
                {
                    [self dismissGameOverSequenceAndShowLoading:NO];
                    
                    // if continue, go back to INGAME
                    gameState = GAME_STATE_INGAME;
                    willContinue = NO;
                    
                    // clear stats
                    [[StatsManager getInstance] resetFlightTime];
                    [[StatsManager getInstance] resetPointsTotal];
                    [[StatsManager getInstance] resetPointsCur];
                    [[StatsManager getInstance] resetCargosCur];
                    [[StatsManager getInstance] resetScoreMultiplier];
                    [[StatsManager getInstance] resetSessionCash];
                    
                    // spawn and resume game
                    [[GameManager getInstance] respawnPlayerAfterDelay:0.0f];
                    [[GameManager getInstance] startScrollCam];
                    
                    // inform managers of continue
                    [[AchievementsManager getInstance] incrContinueCount];
                    [[StatsManager getInstance] incrContinueCount];
                }
            }
            break;
            
        case GAME_STATE_TIMEBASED_PRESTART:
            {
                gameState = GAME_STATE_TIMEBASED_NEXTPEER_DASHBOARD;
                [[GameManager getInstance] disablePanControl];
//                [self registerNextpeerNotifications];
                _isMultiplayerTourney = YES;
                _startTimebasedGame = YES;
                
                [[PogAnalytics getInstance] logTourneyStarted];
            }
            break;

        case GAME_STATE_TIMEBASED_NEXTPEER_DASHBOARD:
            if(_startTimebasedGame)
            {
                // start in-game music
                [[SoundManager getInstance] playMusic:@"Ingame0" doLoop:YES];
                [[SoundManager getInstance] playMusic2:@"Ambient1" doLoop:YES];

                self.shouldUpdateSim = YES;
                shouldUpdateDraw = YES;
                [GameManager getInstance].hasTourneyEnded = NO;
                _startTimebasedGame = NO;
                [[GameManager getInstance] enablePanControl];
                [self.scoreHud fadeOutLoading:0.3f];
                gameState = GAME_STATE_INGAME;
            }
            break;

        case GAME_STATE_TIMEBASED_NEXTPEER_POSTGAME:
            if(_startTimebasedGame)
            {
                // game session completed for stats (no coins because
                // in tourneys, players only get coins from winning or buying)
                [[StatsManager getInstance] completeGameSessionWithCoins:NO];
                
                [[StatsManager getInstance] resetPointsTotal];
                [[StatsManager getInstance] resetPointsCur];
                [[StatsManager getInstance] resetCargosCur];
                [[StatsManager getInstance] resetScoreMultiplier];

                // start in-game music
                [[SoundManager getInstance] playMusic:@"Ingame0" doLoop:YES];
                [[SoundManager getInstance] playMusic2:@"Ambient1" doLoop:YES];

                [[GameManager getInstance] restartCurrentLevel];
                self.shouldUpdateSim = YES;     
                shouldUpdateDraw = YES;
                _startTimebasedGame = NO;
                [scoreHud fadeOutLoading:0.3f];
                gameState = GAME_STATE_INGAME;                
            }
            else
            {
                gameState = GAME_STATE_EXITTIMEBASED;
            }
            break;
            
        default:
            // do nothing
            break;
    }
    
    // perform new state init
    switch(gameState)
    {
        case GAME_STATE_INGAME:
            // do nothing
            break;
            
        case GAME_STATE_PLAYERDEAD:
            // do nothing
            break;
            
        case GAME_STATE_LEVELCOMPLETED:
            // do nothing
            break;
            
        case GAME_STATE_GAMEOVERSEQUENCE:
            // do nothing
            break;
            
        case GAME_STATE_EXITGAME:
            // dismiss the game over screen
            [self dismissGameOverSequenceAndShowLoading:YES];
            
            // exit the game
            [self exitGameFinishCurrentLevel:NO];
            break;
            
        case GAME_STATE_EXITTIMEBASED:
            {
                [self exitGameFinishCurrentLevel:YES];
            }
            break;
            
        default:
            // do nothing
            break;
    }
}

- (void) exitGameFinishCurrentLevel:(BOOL)finishLevel
{
    if(finishLevel)
    {
        // disallow sound clips in Campaign mode to prevent spill over finishCurrentLevel-killEnemmies sounds
        // (TODO 1/6/2011: this is probably not needed now because finishLevel is only TRUE in timebased)
        //[[SoundManager getInstance] disallowPlayClip];
        [[GameManager getInstance] finishCurrentLevel];
        //[[SoundManager getInstance] allowPlayClip];
    }
    [[GameManager getInstance] exitCurrentLevel];
    [[GameManager getInstance] exitGame];

    [self shutdownGameLoop];

    // pop back to the main menu
    [[AppNavController getInstance] popViewControllerAnimated:NO]; 

    // log journey-completed analytics
    [[PogAnalytics getInstance] logJourneyCompleted];

    // if GameOver out and player pressed Store button, push the StoreMenu right after
    if(_shouldExitFromGameOver)
    {
        if(POSTGAMEOVER_FLAG_STORE & _postGameOverFlags)
        {
            StoreMenu* controller = [[StoreMenu alloc] initWithNibName:@"StoreMenu" bundle:nil];
            [[AppNavController getInstance] pushViewController:controller animated:NO];
            [controller release];
        }
        else if(POSTGAMEOVER_FLAG_STATS & _postGameOverFlags)
        {
            StatsController* controller = [[StatsController alloc] initWithNibName:@"StatsController" bundle:nil];
            [[AppNavController getInstance] pushViewController:controller animated:NO];
            [controller release];
        }
        else if(POSTGAMEOVER_FLAG_GOALS & _postGameOverFlags)
        {
            GoalsMenu* controller = [[GoalsMenu alloc] initToGimmie:YES];
            [[AppNavController getInstance] pushViewController:controller animated:NO];
            [controller release];
        }
        
        _postGameOverFlags = POSTGAMEOVER_FLAG_NONE;
    }
}

#pragma mark -
#pragma mark AppEventDelegate
- (void) appWillResignActive
{
    if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
    {
        if((GAME_STATE_INGAME == gameState) || (GAME_STATE_PLAYERDEAD == gameState))
        {
            // pause looping effects
            [[SoundManager getInstance] pauseLoopingEffects];
        }
    }    
    // pause the game if in INGAME state and pause menu isn't up; otherwise, do nothing because the game is already in 
    // a non-progression state or about to get into a non-progression state
    else if((GAME_STATE_INGAME == gameState) && (![self pauseMenu]) &&
            (![self tutorial]) &&
            (![[GameManager getInstance] isAtEndOfLevel]) &&
            (![[GameManager getInstance] isPlayerDead]) &&
            (![self isLevelCompletedScreenVisible]))
    {
        [self buttonPausePressed];
    }
    
    // pause the gameLoopTimer in all cases
	if([gameLoopTimer isValid])
	{
		pauseStart = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
		previousFiringDate = [[gameLoopTimer fireDate] retain];
		[gameLoopTimer setFireDate:[NSDate distantFuture]];
	}
}

- (void) appDidBecomeActive
{
	if([gameLoopTimer isValid])
	{
		float pauseTime = -1.0f * [pauseStart timeIntervalSinceNow];
		[gameLoopTimer setFireDate:[previousFiringDate initWithTimeInterval:pauseTime sinceDate:previousFiringDate]];
		[pauseStart release];
		[previousFiringDate release];
		pauseStart = nil;
		previousFiringDate = nil;
    }
    
    if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
    {
        if((GAME_STATE_INGAME == gameState) || (GAME_STATE_PLAYERDEAD == gameState))
        {
            // resume looping effects
            [[SoundManager getInstance] resumeLoopingEffects];
        }
    }
}

- (void) appDidEnterBackground
{
    if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
    {
        if((GAME_STATE_INGAME == gameState) || (GAME_STATE_PLAYERDEAD == gameState))
        {
            // if entering background from in-game, set the game to finish because 
            // nextpeer will disconnect upon entering background
            [GameManager getInstance].gameTimeRemaining = 0.0f;
            
            // cover the game
            [scoreHud fadeInLoading:0.0f];
        }
    }
}

- (void) appWillEnterForeground
{
    if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
    {
        _shouldRelaunchNPDashboard = NO;
        if((GAME_STATE_TIMEBASED_PRESTART == gameState) ||
           (GAME_STATE_TIMEBASED_NEXTPEER_DASHBOARD == gameState) ||
           (GAME_STATE_TIMEBASED_NEXTPEER_POSTGAME == gameState))
        {
            // if we enter foreground into the nextpeer menu, then just exit out to main menu
            // because we either had entered background while in nextpeer menu, or during "waiting for players"
            gameState = GAME_STATE_EXITTIMEBASED;
        }
        else if((GAME_STATE_INGAME == gameState) || (GAME_STATE_PLAYERDEAD == gameState))
        {
            // if we entered foreground in one of the in-game states, then the dashboard needs to be
            // relaunched as soon as we exit this state
            // this is because NP dashboard seems to get unloaded upon enter-background
            _shouldRelaunchNPDashboard = YES;
        }
    }
}

- (void) abortToRootViewControllerNow
{
    [[GameManager getInstance] finishCurrentLevel];
    [[GameManager getInstance] exitCurrentLevel];
    [[GameManager getInstance] exitGame];

    [self shutdownGameLoop];

    [[AppNavController getInstance] popToRootViewControllerAnimated:NO];
}


#pragma mark - PauseMenuDelegate and PauseMenu IBAction

- (CGAffineTransform) pauseMenuOut
{
    CGAffineTransform result = CGAffineTransformTranslate(CGAffineTransformIdentity, 
                                                          (0.4f * self.view.bounds.size.width), 
                                                          (0.0f * self.view.bounds.size.height));
    return result;
}

- (CGAffineTransform) pauseMenuIn
{
    CGAffineTransform result = CGAffineTransformTranslate(CGAffineTransformIdentity, 
                                                          (0.0f * self.view.bounds.size.width), 
                                                          (0.0f * self.view.bounds.size.height));
    return result;
}

- (void) buttonPausePressed
{
    if((!_tutorial) && (![self pauseMenu]))
    {
        self.shouldUpdateSim = NO;
        
        // present the pause menu modally ourselves
        pauseMenu = [[PauseMenu alloc] initWithNibName:[CurryAppDelegate getXibNameFor:@"PauseMenu"] bundle:nil];
        pauseMenu.view.frame = self.view.bounds;
        pauseMenu.delegate = self;
        pauseMenu.view.transform = [self pauseMenuOut];
        [UIView animateWithDuration:PAUSEMENU_ANIMDURATION
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ 
                             pauseMenu.view.transform = [self pauseMenuIn]; 
                         }
                         completion:NULL];
        
        // pause looping effects
        [[SoundManager getInstance] pauseLoopingEffects];
        
        // play one shot sound
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
        
        // show the pause menu
        [self.view addSubview:pauseMenu.view];
    }
}


- (void) quitGameFromPauseMenu:(PauseMenu*)sender
{
    // remove pause menu
    sender.view.transform = [self pauseMenuIn];
    [UIView animateWithDuration:PAUSEMENU_ANIMDURATION 
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{ 
                         pauseMenu.view.transform = [self pauseMenuOut]; 
                     }
                     completion:^(BOOL finished){ 
                         [pauseMenu.view removeFromSuperview]; 
                         self.pauseMenu = nil; 
                         
                         // analytics
                         [[PogAnalytics getInstance] logJourneyAborted];
                         
                         // exit out to main menu
                         [self exitGameFinishCurrentLevel:NO];
                     }];        


}

- (void) restartLevelFromPauseMenu:(PauseMenu*)sender
{
    // remove pause menu
    [[SoundManager getInstance] resumeMusic];
    [[SoundManager getInstance] resumeMusic2];
    sender.view.transform = [self pauseMenuIn];
    [UIView animateWithDuration:PAUSEMENU_ANIMDURATION 
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{ 
                         pauseMenu.view.transform = [self pauseMenuOut]; 
                     }
                     completion:^(BOOL finished){ 
                         // kill the pause menu
                         [pauseMenu.view removeFromSuperview]; 
                         self.pauseMenu = nil; 

                         // analytics 
                         [[PogAnalytics getInstance] logJourneyRestarted];
                         
                         // resume looping effects
                         [[SoundManager getInstance] resumeLoopingEffects];
                         
                         self.shouldUpdateSim = NO;
                         [[GameManager getInstance] restartCurrentLevel];
                         self.shouldUpdateSim = YES;                         
                     }];        
}

- (void) resumeGameFromPauseMenu:(PauseMenu*)sender
{
    [[SoundManager getInstance] resumeMusic];
    [[SoundManager getInstance] resumeMusic2];

    // remove pause menu
    sender.view.transform = [self pauseMenuIn];
    [UIView animateWithDuration:PAUSEMENU_ANIMDURATION 
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{ 
                         pauseMenu.view.transform = [self pauseMenuOut]; 
                     }
     
                     completion:^(BOOL finished){ 
                         // kill the pause menu
                         [pauseMenu.view removeFromSuperview]; 
                         self.pauseMenu = nil; 

                         // resume looping effects
                         [[SoundManager getInstance] resumeLoopingEffects];

                         // resume the game
                         if(![self shouldUpdateSim])
                         {
                             self.shouldUpdateSim = YES;
                         }
                     }];    
}

- (void) showTutorialFromPauseMenu:(PauseMenu *)sender
{
    // remove pause menu
    sender.view.transform = [self pauseMenuIn];
    [UIView animateWithDuration:PAUSEMENU_ANIMDURATION 
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{ 
                         pauseMenu.view.transform = [self pauseMenuOut]; 
                     }
     
                     completion:^(BOOL finished){ 
                         // kill the pause menu
                         [pauseMenu.view removeFromSuperview]; 
                         self.pauseMenu = nil; 

                         // show tutorial
                         [self showTutorialWithScrim:YES];                         
                     }];    

}

#pragma mark - in-game screens
- (void) showLevelCompletedScreen
{
    _levelStatsTimer = LEVELSTATS_LENGTH;
    [[GameManager getInstance] disablePanControl];

    [scoreHud hideForLevelCompletion];
    levelCompletedScreen = [[LevelCompletedScreen alloc] initWithNibName:@"LevelCompletedScreen" bundle:nil];
    [self.view addSubview:levelCompletedScreen.view];
}

- (BOOL) isLevelCompletedScreenVisible
{
    BOOL result = NO;
    if(self.levelCompletedScreen)
    {
        result = YES;
    }
    return result;
}

- (void) proceedToNextRoute
{
    // reset stats-committed flag
    _statsCompletedCurLevel = NO;
    
    // exit the current level
    [[GameManager getInstance] exitCurrentLevel];
    
    BOOL gotoNextLevel = [[LevelManager getInstance] hasNextLevel];
    if(gotoNextLevel)
    {
        // go to the next level
        [[GameManager getInstance] gotoNextLevel];
    }
    else
    {
        // no more levels, exit to main menu
        // kill the game
        [[GameManager getInstance] exitGame];
        [self shutdownGameLoop];
        
        // pop back to the main menu
        [[AppNavController getInstance] popViewControllerAnimated:NO]; 
    }
    
    // dismiss the LevelCompleted screen
    if([self levelCompletedScreen])
    {
        [self.levelCompletedScreen.view removeFromSuperview];
        self.levelCompletedScreen = nil;  
    }
}


- (void) showContinueScreen
{
    continueScreen = [[ContinueScreen alloc] initWithContinuesRemaining:[[StatsManager getInstance] continuesRemaining]];
    continueScreen.delegate = self;
    [self.view addSubview:continueScreen.view];
}

- (BOOL) isContinueScreenVisible
{
    BOOL result = NO;
    if(self.continueScreen)
    {
        result = YES;
    }
    return result;
}

- (void) showGameOverSequence
{
    _shouldExitFromGameOver = NO;
    _postGameOverFlags = POSTGAMEOVER_FLAG_NONE;

    // fade in loading screen
    //[scoreHud fadeInNoImageLoading:GAMEOVERAUTODIM_LENGTH delay:GAMEOVERAUTODIM_DELAY];
    
    gameOverScreen = [[GameOverScreen alloc] initWithNibName:@"GameOverScreen" bundle:nil];
    gameOverScreen.delegate = self;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        [gameOverScreen.view setFrame:self.view.bounds];
        CGRect contentFrame = gameOverScreen.contentView.frame;
        float yOffset = 0.2f * contentFrame.size.height;
        CGRect newFrame = CGRectMake(contentFrame.origin.x, contentFrame.origin.y + yOffset, 
                                     contentFrame.size.width, contentFrame.size.height);
        [gameOverScreen.contentView setFrame:newFrame];
    }
    [self.view addSubview:gameOverScreen.view];        
    
    // fade in game over screen
    gameOverScreen.view.alpha = 0.0f;
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{ 
                         gameOverScreen.view.alpha = 1.0f;
                     }
                     completion:NULL];

    // setup timer to stop sim
    gameOverStopSimTimer = GAMEOVERAUTODIM_LENGTH + GAMEOVERAUTODIM_DELAY;
}

- (void) dismissGameOverSequenceAndShowLoading:(BOOL)showLoading
{
    if(showLoading)
    {
        [scoreHud fadeInLoading:0.0f];
    }
    [gameOverScreen.view removeFromSuperview];
    self.gameOverScreen = nil;
}

- (BOOL) isGameOverScreenVisible
{
    BOOL result = NO;
    if([self gameOverScreen])
    {
        result = YES;
    }
    return result;
}

#pragma mark - ContinueScreenDelegate

- (void) continueGame:(ContinueScreen *)sender
{
    // dismiss the continue screen
    [continueScreen.view removeFromSuperview];
    self.continueScreen = nil;
    
    // subtract a continue from StatsManager
    unsigned int continues = [[StatsManager getInstance] continuesRemaining];
    if(0 < continues)
    {
        --continues;
    }
    else
    {
        continues = 0;
    }
    [[StatsManager getInstance] setContinuesRemaining:continues];
    
    // inform achievements manager of continue
    [[AchievementsManager getInstance] incrContinueCount];
    
    willContinue = YES;
}

- (void) endGame:(ContinueScreen *)sender
{
    // dismiss the continue screen
    [continueScreen.view removeFromSuperview];
    self.continueScreen = nil;    

    willContinue = NO;
}

#pragma mark - GameOverScreenDelegate
- (void) dismissGameOverScreen
{
    _shouldExitFromGameOver = YES;
    gameOverScreen.delegate = nil;
}

- (void) gotoStore
{
    _shouldExitFromGameOver = YES;
    _postGameOverFlags |= POSTGAMEOVER_FLAG_STORE;
    gameOverScreen.delegate = nil;
}

- (void) gotoStats
{
    _shouldExitFromGameOver = YES;
    _postGameOverFlags |= POSTGAMEOVER_FLAG_STATS;
    gameOverScreen.delegate = nil;
}

- (void) gotoGoals
{
    _shouldExitFromGameOver = YES;
    _postGameOverFlags |= POSTGAMEOVER_FLAG_GOALS;
    gameOverScreen.delegate = nil;
}

- (void) continueGame
{
    _shouldExitFromGameOver = NO;
    willContinue = YES;
}

#pragma mark - TutorialControllerDelegate
- (void) showTutorialWithScrim:(BOOL)scrimOn
{
    BOOL guided = YES;
    if(scrimOn)
    {
        guided = NO;
    }
    _tutorial = [[TutorialController alloc] initGuided:guided];
    _tutorial.delegate = self;
    [_tutorial.view setFrame:self.view.bounds];

    [self.view addSubview:[_tutorial view]];
    if(scrimOn)
    {
        [_tutorial showScrollViewScrim];
    }
}

- (void) closeTutorial
{
    if(_tutorial)
    {
        [_tutorial.view removeFromSuperview];
        [_tutorial release];
        _tutorial = nil;
        
        // resume looping effects (in case we came from the pause menu)
        [[SoundManager getInstance] resumeLoopingEffects];
        
        // resume game
        gameState = GAME_STATE_INGAME;
        [self setShouldUpdateSim:YES];
        
        // set tutorial completed so it never shows automatically again
        [[StatsManager getInstance] setCompletedTutorial];
    }
}

- (void) dismissTutorial
{
    [UIView animateWithDuration:0.5f 
                     animations:^{
                         [_tutorial.view setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         [self closeTutorial];
                     }];
}


#pragma mark - touch events
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if([self flightController])
    {
        [self.flightController view:self.view touchesBegan:touches withEvent:event];
    }
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if([self flightController])
    {
        [self.flightController view:self.view touchesMoved:touches withEvent:event];
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if([self flightController])
    {
        [self.flightController view:self.view touchesEnded:touches withEvent:event];
    }
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if([self flightController])
    {
        [self.flightController view:self.view touchesCancelled:touches withEvent:event];
    }
}

#pragma mark - ad banner
- (void) setAdBannerView:(ADBannerView *)adBannerView {
    if(_adBannerView != adBannerView) {
        _adBannerView.delegate = nil;
        [_adBannerView removeFromSuperview];
        _adBannerView = adBannerView;
        
        if(adBannerView) {
            adBannerView.delegate = self;
            [self.view addSubview:adBannerView];
        }
    }
}

- (void) setupADBanner {
    if(!self.adBannerView) {
        self.adBannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    }
}

- (void) layoutADBannerAnimated:(BOOL)animated {
    if(self.adBannerView.superview == self.view) {
        CGRect bannerFrame = self.adBannerView.frame;
        if (self.adBannerView.bannerLoaded) {
            CGFloat contentBottom = self.view.bounds.size.height - self.adBannerView.bounds.size.height;
            bannerFrame.origin.y = contentBottom;
        } else {
            bannerFrame.origin.y = self.view.bounds.size.height;
        }
        [UIView animateWithDuration:animated ? 0.2 : 0.0 animations:^{
            self.adBannerView.frame = bannerFrame;
        }];
    }
}

#pragma mark - ADBannerViewDelegate
- (void) bannerViewDidLoadAd:(ADBannerView *)banner {
    [self layoutADBannerAnimated:YES];
}

- (void) bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [self layoutADBannerAnimated:YES];
}

- (BOOL) bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    [self buttonPausePressed];
    [[SoundManager getInstance] pauseMusic];
    [[SoundManager getInstance] pauseMusic2];
    return YES;
}

- (void) bannerViewActionDidFinish:(ADBannerView *)banner {
    // don't resume music because we could be leaving the app from user tapping on the Ad;
    // when user exits pause menu, music will resume
}


@end
