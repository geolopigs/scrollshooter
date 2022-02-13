//
//  LevelDataDelegate.h
//  Pogditor
//
//  Created by Shu Chiun Cheah on 7/24/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LevelData;
@protocol LevelDataDelegate<NSObject>
- (void) commitToLevelData:(LevelData*)levelData;
@end

