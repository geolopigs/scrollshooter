//
//  AchievementsData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/22/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface AchievementsData : NSObject<NSCoding>
{
    NSString* _identifier;
    BOOL _isDirty;
    unsigned int _currentValue;
    unsigned int _targetValue;
    BOOL _shouldReportToGimmie;
}
@property (nonatomic,retain) NSString* identifier;
@property (nonatomic,readonly) BOOL isDirty;
@property (nonatomic,readonly) unsigned int currentValue;
@property (nonatomic,readonly) unsigned int targetValue;
@property (nonatomic,readonly) BOOL shouldReportToGimmie;

- (id) initWithIdentifier:(NSString*)identifier targetValue:(unsigned int)target;

// management (called from AchievementsManager only)
- (void) syncWithGKAchievement:(GKAchievement*)loadedAchievement;
- (void) markDirty;
- (void) markDirtyForGimmie;

// tracking
- (void) updateCurrentValue:(unsigned int) newValue;
- (void) updateWatermarkValue:(unsigned int)newValue;
- (void) incrByValue:(unsigned int) increment;
- (BOOL) isCompleted;
- (BOOL) isNewlyCompleted;      // completed but not yet reported to GameCenter (useful for high-level stats code)

// reporting
- (float) percentComplete;
- (void) reportToGameCenter;
- (void) reportToGimmieAsEventId:(NSString*)eventId;

@end
