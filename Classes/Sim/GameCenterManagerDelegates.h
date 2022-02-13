//
//  GameCenterManagerDelegates.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/7/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GameCenterManagerAuthenticationDelegate <NSObject>
- (void) didSucceedAuthentication;
- (void) showAuthenticationDialog:(UIViewController*)authViewController;
@end
