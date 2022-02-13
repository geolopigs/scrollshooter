//
//  AddonProtocols.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/8/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Addon;
@protocol AddonTypeDelegate <NSObject>
- (void) initAddon:(Addon*)newAddon;
- (void) updateBehaviorForAddon:(Addon*)givenAddon elapsed:(NSTimeInterval)elapsed;
@end

@protocol AddonDelegate <NSObject>
- (CGPoint) worldPosition;
- (float) rotation;
@end
