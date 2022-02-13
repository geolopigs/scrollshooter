//
//  CurryAppDelegate.m
//  Curry
//
//

#import "CurryAppDelegate.h"
#import "RendererGLView.h"
#import "RenderBucketsManager.h"
#import "AppNavController.h"
#import "AppRendererConfig.h"
#import "EnemyFactory.h"
#import "PlayerFactory.h"
#import "LevelManager.h"
#import "GameManager.h"
#import "DynamicManager.h"
#import "MenuResManager.h"
#import "CollisionManager.h"
#import "SoundManager.h"
#import "StatsManager.h"
#import "CargoManager.h"
#import "AnimProcessor.h"
#import "GameObjectSizes.h"
#import "AppEventDelegate.h"
#import "GameCenterManager.h"
#import "AchievementsManager.h"
#import "Appirater.h"
#import "MainMenu.h"
#import "GameViewController.h"
#import "PlayerInventory.h"
#import "StoreManager.h"
#import "ProductManager.h"
#import "TourneyManager.h"
#import "MBProgressHUD.h"
#import "DebugOptions.h"
#import <QuartzCore/QuartzCore.h>
#import "PogAnalytics.h"
#import "MoreMenu.h"
#import "UIColor+Utils.h"

static const CGFloat SOUNDLOOP_INTERVAL_SECS = 1.0f / 30.0f;

@interface CurryAppDelegate (PrivateMethods)
- (void) soundLoop;
- (void) globalDidEnterBackground;
- (void) globalTerminate;
- (void) initFrontendBackground;
- (void) shutdownFrontendBackground;
@end

@implementation CurryAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize navController = _navController;

#pragma mark -
#pragma mark Application lifecycle

void uncaughtExceptionHandler(NSException* exception)
{
    [[PogAnalytics getInstance] logError:@"Uncaught" message:@"Crash" exception:exception];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	[self globalInit];

    [[PogAnalytics getInstance] appBegin];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    MainMenu* mainMenu = [[[MainMenu alloc] initWithNibName:@"MainMenu" bundle:nil] autorelease];
    self.viewController = mainMenu;
    self.navController = [[[UINavigationController alloc] initWithRootViewController:_viewController] autorelease];

    [self initFrontendBackground];
    [self.window addSubview:[self navController].view];
    [self.window makeKeyAndVisible];
	
	// Hide the navigation bar on UINavigationController
	[_navController setNavigationBarHidden:TRUE];
	
    
    // passed in NO because there is a call in MainMenu ViewWillAppear that will show the prompt
    //[Appirater appLaunched:NO];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	UIViewController<AppEventDelegate>* topController = (UIViewController<AppEventDelegate>*) self.navController.topViewController;
	[topController appWillResignActive];

    // resign sound
    [[SoundManager getInstance] resignActive];
    if(soundLoopTimer)
    {
        [soundLoopTimer invalidate];
        soundLoopTimer = nil;
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	UIViewController<AppEventDelegate>* topController = (UIViewController<AppEventDelegate>*) [[self navController] topViewController];
	[topController appDidEnterBackground];	
    [[GameCenterManager getInstance] appDidEnterBackground];

    // hide any MBProgressHUD regardless of where it was added from
    [MBProgressHUD hideHUDForView:self.window animated:NO];
    
    // save stats to disk
    [[StatsManager getInstance] saveStatsData];
    [[StatsManager getInstance] savePlayerData];
    
    // dismiss dangling alerts
    [[MenuResManager getInstance] dismissAlertView];
    
    [[PogAnalytics getInstance] appEnterBackground];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    [[PogAnalytics getInstance] appEnterForeground];
    UIViewController<AppEventDelegate>* topController = (UIViewController<AppEventDelegate>*) [[self navController] topViewController];
	[topController appWillEnterForeground];

    // passed in NO because there is a call in MainMenu ViewWillAppear that will show the prompt
    //[Appirater appEnteredForeground:NO];
 }


- (void)applicationDidBecomeActive:(UIApplication *)application {
	UIViewController<AppEventDelegate>* topController = (UIViewController<AppEventDelegate>*) [[self navController] topViewController];
	[topController appDidBecomeActive];

    // unresign sound
    if(!soundLoopTimer)
    {
        soundLoopTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) SOUNDLOOP_INTERVAL_SECS
                                                      target:self 
                                                    selector:@selector(soundLoop) 
                                                    userInfo:nil 
                                                     repeats:YES];
        [[SoundManager getInstance] restoreActive];
    }    
}


- (void)applicationWillTerminate:(UIApplication *)application {
    [[GameCenterManager getInstance] appWillTerminate];
    [self shutdownFrontendBackground];
    [self globalShutdown];

    [[PogAnalytics getInstance] appEnd];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc 
{
    if(soundLoopTimer)
    {
        [soundLoopTimer invalidate];
    }
    [super dealloc];
}



#pragma mark - Engine init shutdown
- (void) globalInit
{
    // analytics
    [PogAnalytics getInstance];
    
	// init renderer
	AppRendererConfig* config = [AppRendererConfig getInstance];
	[RendererGLView getInstance];
	[[RenderBucketsManager getInstance] initWithConfig:config.bucketsConfig];
	
	// init frontend navigation controller
	[AppNavController getInstance];
	
	// init game object factories
    [GameObjectSizes getInstance];
	[EnemyFactory getInstance];
    [PlayerFactory getInstance];
	
	// init game managers
	[LevelManager getInstance];
    [GameManager getInstance];
	[DynamicManager getInstance];
    [CollisionManager getInstance];
    [CargoManager getInstance];
    [AnimProcessor getInstance];
    [TourneyManager getInstance];
    
	// init global menu resources
	[MenuResManager getInstance];

    // init sound
    [SoundManager getInstance];    
    soundLoopTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) SOUNDLOOP_INTERVAL_SECS
                                                      target:self 
                                                    selector:@selector(soundLoop) 
                                                    userInfo:nil 
                                                     repeats:YES];
    
    // init stats
    [StatsManager getInstance];
    [ProductManager getInstance];
    [[StatsManager getInstance] loadPlayerData];
    [[StatsManager getInstance] loadStatsData];
    [PlayerInventory getInstance];
    [StoreManager getInstance];
    [AchievementsManager getInstance];
//    [GameCenterManager getInstance];
//    [[GameCenterManager getInstance] checkAndAuthenticate];
    
#if defined(DEBUG)
    [DebugOptions getInstance];
#endif
}

- (void) globalShutdown
{
#if defined(DEBUG)
    [DebugOptions destroyInstance];
#endif

    [GameCenterManager destroyInstance];
    [AchievementsManager destroyInstance];
    [SoundManager destroyInstance];
    [StoreManager destroyInstance];
    [PlayerInventory destroyInstance];
    [ProductManager destroyInstance];
    [StatsManager destroyInstance];	
    [MenuResManager destroyInstance];
    
    [AnimProcessor destroyInstance];
    [CollisionManager destroyInstance];
    [DynamicManager destroyInstance];
    [GameManager destroyInstance];
	[LevelManager destroyInstance];
    [PlayerFactory destroyInstance];
	[EnemyFactory destroyInstance];
    [GameObjectSizes destroyInstance];
	[AppNavController destroyInstance];
    [TourneyManager destroyInstance];
	
	[RenderBucketsManager destroyInstance];
	[RendererGLView destroyInstance];
	[AppRendererConfig destroyInstance];
    
    [PogAnalytics destroyInstance];
}

+ (NSString*) getXibNameFor:(NSString *)baseName
{
    NSString* result = baseName;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        result = [baseName stringByAppendingFormat:@"-iPad"];
    }
    return result;
}

#pragma mark - Private Methods
- (void) soundLoop
{    
    // pump sound manager
    [[SoundManager getInstance] update];
}

- (void) globalDidEnterBackground
{
    
}

- (void) globalTerminate
{
    
}


- (void) initFrontendBackground
{
    // setup frontend background
    CGRect imageFrame = [[self window] bounds];
    imageFrame.size.height = imageFrame.size.width * 1.5f;
    
    [[MenuResManager getInstance] initBackgroundImageWithFrame:imageFrame];
    [[MenuResManager getInstance] loadFrontendBackgroundImage];

    [self setToFrontendBackgroundColor];
    [self.window addSubview:[[MenuResManager getInstance] frontendBackground]];
}

- (void) shutdownFrontendBackground
{
    [[MenuResManager getInstance].frontendBackground removeFromSuperview];
}

- (void) setToFrontendBackgroundColor {
    self.window.backgroundColor = [UIColor colorWithHex:0x84CCC9FF];
}

- (void) setToInGameBackgroundColor {
    self.window.backgroundColor = [UIColor blackColor];
}

@end
