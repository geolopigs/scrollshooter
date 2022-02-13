//
//  CurryAppDelegate.h
//  Curry
//
//

#import <UIKit/UIKit.h>

@class MainMenu;

@interface CurryAppDelegate : UIResponder <UIApplicationDelegate>
{
    UIWindow *_window;
	MainMenu* _viewController;
	UINavigationController *_navController;	
    
	NSTimer*	soundLoopTimer;
}

@property (nonatomic,retain) UIWindow IBOutlet *window;
@property (nonatomic,retain) MainMenu* viewController;
@property (nonatomic,retain) UINavigationController *navController;

- (void) globalInit;
- (void) globalShutdown;
- (void) setToFrontendBackgroundColor;
- (void) setToInGameBackgroundColor;

+ (NSString*) getXibNameFor:(NSString*)baseName;
@end

