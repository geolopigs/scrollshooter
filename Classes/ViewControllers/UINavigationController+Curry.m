//
//  UINavigationController+Curry.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/13/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "UINavigationController+Curry.h"

@implementation UINavigationController (Curry)

- (void) altAnimatePushViewController:(UIViewController*)controller animated:(BOOL)isAnimated
{
    [CATransaction begin];
    
    CATransition *transition;
    transition = [CATransition animation];
    transition.type = kCATransitionMoveIn;          // Use any animation type and subtype you like
    transition.subtype = kCATransitionFromLeft;
    transition.duration = 0.2;
    
    CATransition *fadeTrans = [CATransition animation];
    fadeTrans.type = kCATransitionFade;
    fadeTrans.duration = 0.1;
    
    
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
//    [[[[self.view subviews] objectAtIndex:1] layer] addAnimation:fadeTrans forKey:nil];
    
    
    
    [self pushViewController:controller animated:isAnimated];
    [CATransaction commit];    
}


- (void) altAnimatePopViewControllerAnimated:(BOOL)animated
{
    [CATransaction begin];
    
    CATransition *transition;
    transition = [CATransition animation];
    transition.type = kCATransitionReveal;          // Use any animation type and subtype you like
    transition.subtype = kCATransitionFromRight;
    transition.duration = 0.2;
    
    CATransition *fadeTrans = [CATransition animation];
    fadeTrans.type = kCATransitionFade;
    fadeTrans.duration = 0.3;
    
    
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
    //[[[[self.view subviews] objectAtIndex:1] layer] addAnimation:fadeTrans forKey:nil];
    
    
    
    [self  popViewControllerAnimated:YES];
    [CATransaction commit];
}

- (void) pushFromLeftViewController:(UIViewController*)controller animated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionMoveIn;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromLeft;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [self pushViewController:controller animated:YES];
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
    
        [CATransaction commit];    
    }
    else
    {
        [self pushViewController:controller animated:NO];
    }
}

- (void) pushFromRightViewController:(UIViewController*)controller animated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionMoveIn;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromRight;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [self pushViewController:controller animated:YES];
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [CATransaction commit];    
    }
    else
    {
        [self pushViewController:controller animated:NO];
    }
}

- (void) popToLeftViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionReveal;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromRight;
        transition.duration = 0.2;

        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [self  popViewControllerAnimated:YES];
        [CATransaction commit];   
    }
    else
    {
        [self popViewControllerAnimated:NO];
    }
}

- (void) popToRightViewControllerAnimated:(BOOL)isAnimated
{
    if(isAnimated)
    {
        [CATransaction begin];
        
        CATransition *transition;
        transition = [CATransition animation];
        transition.type = kCATransitionReveal;          // Use any animation type and subtype you like
        transition.subtype = kCATransitionFromLeft;
        transition.duration = 0.2;
        
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        
        [[[[self.view subviews] objectAtIndex:0] layer] addAnimation:transition forKey:nil];
        
        [self  popViewControllerAnimated:YES];
        [CATransaction commit];   
    }
    else
    {
        [self popViewControllerAnimated:NO];
    }
}

@end
