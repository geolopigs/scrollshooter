//
//  GameModeMenuDelegate.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/30/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameModes.h"

@protocol GameModeMenuDelegate <NSObject>
- (void) dismissAndGoToGameMode:(GameMode)selectedGameMode;
@end
