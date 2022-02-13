//
//  DebugOptions.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/20/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#if defined(DEBUG)

@interface DebugOptions : NSObject
{
    BOOL isPlayerInvincible;
    BOOL isPlayerMissilesOn;
    BOOL isDebugColOutlineOn;
    BOOL isDebugSpriteOutlineOn;
    BOOL _debugNoEnemies;
    
    BOOL debugLevelCompletion;
    float debugLevelCompletionTimeout;
    
    BOOL isAllLevelsUnlocked;
    BOOL _areFlyersUnlocked;
}
@property (nonatomic,assign) BOOL isPlayerInvincible;
@property (nonatomic,assign) BOOL isPlayerMissilesOn;
@property (nonatomic,assign) BOOL isDebugColOutlineOn;
@property (nonatomic,assign) BOOL isDebugSpriteOutlineOn;
@property (nonatomic,assign) BOOL debugNoEnemies;
@property (nonatomic,assign) BOOL debugLevelCompletion;
@property (nonatomic,assign) float debugLevelCompletionTimeout;
@property (nonatomic,assign) BOOL isAllLevelsUnlocked;
@property (nonatomic,assign) BOOL areFlyersUnlocked;

// singleton
+(DebugOptions*) getInstance;
+(void) destroyInstance;

// UI
- (void) togglePlayerInvincibleOnOff:(id)sender;
- (void) togglePlayerMissilesOnOff:(id)sender;
- (void) toggleDebugColOutlineOnOff:(id)sender;
- (void) toggleDebugSpriteOutlineOnOff:(id)sender;
- (void) toggleDebugNoEnemiesOnOff:(id)sender;
- (void) toggleDebugLevelCompletion:(id)sender;
- (void) toggleAllLevelsUnlocked:(id)sender;
- (void) toggleFlyersUnlocked:(id)sender;
@end

#endif  // defined(DEBUG)
