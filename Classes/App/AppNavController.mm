//
//  AppNavController.mm
//  Curry
//
//

#import "AppNavController.h"
#import "CurryAppDelegate.h"
#import "SoundManager.h"
#import "GameViewController.h"
#import "TutorialTourney.h"
#import "MainMenu.h"
#import "UINavigationController+Curry.h"

@implementation AppNavController

#pragma mark - Instance Methods
- (void) pushViewController:(UIViewController*)controller animated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        // play sound only if animated
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
    }
	CurryAppDelegate *delegate = (CurryAppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate.navController pushViewController:controller animated:isAnimated];
}

- (void) popViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        // play sound only if animated
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
    }

    CurryAppDelegate *delegate = (CurryAppDelegate*) [[UIApplication sharedApplication] delegate];
    
    UIViewController* topController = (UIViewController*) [[delegate navController] topViewController];
    if([topController isMemberOfClass:[GameViewController class]])
    {
        // if we are popping the game, start frontend music
        [[SoundManager getInstance] playMusic:@"Ambient1" doLoop:YES];
    }
    [delegate.navController popViewControllerAnimated:isAnimated];
}

- (void) pushFromLeftViewController:(UIViewController*)controller animated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        // play sound only if animated
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
    }
	CurryAppDelegate *delegate = (CurryAppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate.navController pushFromLeftViewController:controller animated:isAnimated];
}

- (void) pushFromRightViewController:(UIViewController*)controller animated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        // play sound only if animated
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
    }
	CurryAppDelegate *delegate = (CurryAppDelegate *)[[UIApplication sharedApplication] delegate];
	[delegate.navController pushFromRightViewController:controller animated:isAnimated];
}

- (void) popToLeftViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        // play sound only if animated
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
    }
    
    CurryAppDelegate *delegate = (CurryAppDelegate*) [[UIApplication sharedApplication] delegate];
    
    UIViewController* topController = (UIViewController*) [[delegate navController] topViewController];
    if([topController isMemberOfClass:[GameViewController class]])
    {
        // if we are popping the game, start frontend music
        [[SoundManager getInstance] playMusic:@"Ambient1" doLoop:YES];
    }
    [delegate.navController popToLeftViewControllerAnimated:isAnimated];
}

- (void) popToRightViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        // play sound only if animated
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
    }
    
    CurryAppDelegate *delegate = (CurryAppDelegate*) [[UIApplication sharedApplication] delegate];
    
    UIViewController* prevTopController = (UIViewController*) [[delegate navController] topViewController];
    [delegate.navController popToRightViewControllerAnimated:isAnimated];
    UIViewController* curTopController = (UIViewController*) [[delegate navController] topViewController];

    // handle screen transitions
    if([prevTopController isMemberOfClass:[GameViewController class]])
    {
        // if we are popping the game, start frontend music
        [[SoundManager getInstance] playMusic:@"Ambient1" doLoop:YES];
    }
    else if(([prevTopController isMemberOfClass:[TutorialTourney class]]) &&
            ([curTopController isMemberOfClass:[MainMenu class]]))
    {
        // if going from TutorialTourney to MainMenu, then launch Tourney right away
        MainMenu* curMainMenu = (MainMenu*) curTopController;
        [curMainMenu setShouldLaunchNextpeerWhenAppear:YES];
    }
}

- (void) popToRootViewControllerAnimated:(BOOL)isAnimated
{
    CurryAppDelegate *delegate = (CurryAppDelegate*) [[UIApplication sharedApplication] delegate];
    [delegate.navController popToRootViewControllerAnimated:isAnimated];
}

#pragma mark -
#pragma mark Singleton
static AppNavController* singletonInstance = nil;
+ (AppNavController*) getInstance
{
	@synchronized(self)
	{
		if (!singletonInstance)
		{
			singletonInstance = [[[AppNavController alloc] init] retain];
		}
	}
	return singletonInstance;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singletonInstance release];
		singletonInstance = nil;
	}
}

+ (void) setSingletonInstance:(AppNavController*)newInstance
{
    @synchronized(self)
    {
        if(singletonInstance)
        {
            [singletonInstance release];
        }
        singletonInstance = [newInstance retain];
    }
}
@end
