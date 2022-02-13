//
//  UINavigationController+Curry.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Curry)
- (void) altAnimatePushViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) altAnimatePopViewControllerAnimated:(BOOL)animated;
- (void) pushFromLeftViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) pushFromRightViewController:(UIViewController*)controller animated:(BOOL)isAnimated;
- (void) popToLeftViewControllerAnimated:(BOOL)isAnimated;
- (void) popToRightViewControllerAnimated:(BOOL)isAnimated;

@end
