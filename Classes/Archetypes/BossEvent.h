//
//  BossEvent.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/16/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const unsigned int BOSSEVENT_FLAG_NONE;
extern const unsigned int BOSSEVENT_FLAG_TARGETPOS;
extern const unsigned int BOSSEVENT_FLAG_SPAWNER;
extern const unsigned int BOSSEVENT_FLAG_DELAY;
extern const unsigned int BOSSEVENT_FLAG_ANIMSTATE;

@class EnemySpawner;
@interface BossEvent : NSObject
{
    unsigned int flag;
}
@property (nonatomic,assign) CGPoint targetPoint;
@property (nonatomic,assign) CGPoint bl;
@property (nonatomic,assign) CGPoint tr;
@property (nonatomic,retain) EnemySpawner* spawner;
@property (nonatomic,retain) NSString* doneSpawnAnimState;
@property (nonatomic,assign) BOOL hasPlayedDoneSpawnAnim;
@property (nonatomic,assign) float delay;
@property (nonatomic,retain) NSString* animState;
@property (nonatomic,assign) BOOL continueToNext;

// TARGETPOS
- (void) setTargetPos:(CGPoint)targetPoint doneRect:(CGRect)rect;
- (CGPoint) getTargetPos;
- (BOOL) doesTargetContainPos:(CGPoint)pos;

// flags
- (void) setFlag:(unsigned int) flatToSet;
- (BOOL) isSetFlag:(unsigned int) queryFlag;

// utilities
+ (BOOL) doesBoxBl:(CGPoint)bl tr:(CGPoint)tr containPoint:(CGPoint)queryPoint;
@end
