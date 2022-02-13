//
//  AppNavController.h
//  Curry
//
//

#import <Foundation/Foundation.h>


@interface AppNavController : NSObject 
{
    
}

+ (AppNavController*) getInstance;
+ (void) destroyInstance;

- (void) pushViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) popViewControllerAnimated:(BOOL)isAnimated;
- (void) pushFromLeftViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) pushFromRightViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) popToLeftViewControllerAnimated:(BOOL)isAnimated;
- (void) popToRightViewControllerAnimated:(BOOL)isAnimated;
- (void) popToRootViewControllerAnimated:(BOOL)isAnimated;

@end
