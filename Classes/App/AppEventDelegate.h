/*
 *  AppEventDelegate.h
 *  CobraPanic
 *
 *	Protocol to allow the AppDelegate to inform various ViewControllers in the game of external events
 *  that affect the App
 *
 */

@protocol AppEventDelegate <NSObject>
- (void) appWillResignActive;
- (void) appDidBecomeActive;
- (void) appDidEnterBackground;
- (void) appWillEnterForeground;
- (void) abortToRootViewControllerNow;
@end