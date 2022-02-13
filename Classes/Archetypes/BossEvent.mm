//
//  BossEvent.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/16/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "BossEvent.h"
#import "GameManager.h"
#import "EnemySpawner.h"

const unsigned int BOSSEVENT_FLAG_NONE      = 0x00;
const unsigned int BOSSEVENT_FLAG_TARGETPOS = 0x01;
const unsigned int BOSSEVENT_FLAG_SPAWNER   = 0x02;
const unsigned int BOSSEVENT_FLAG_DELAY     = 0x04;
const unsigned int BOSSEVENT_FLAG_ANIMSTATE = 0x08;

@implementation BossEvent
@synthesize targetPoint = _targetPoint;
@synthesize bl = _bl;
@synthesize tr = _tr;
@synthesize delay = _delay;
@synthesize spawner = _spawner;
@synthesize doneSpawnAnimState = _doneSpawnAnimState;
@synthesize hasPlayedDoneSpawnAnim = _hasPlayedDoneSpawnAnim;
@synthesize animState = _animState;
@synthesize continueToNext = _continueToNext;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.targetPoint = CGPointMake(50.0f, 75.0f);
        self.bl = CGPointMake(0.0f, 0.0f);
        self.tr = CGPointMake(100.0f,150.0f);
        self.delay = 0.0f;
        self.spawner = nil;
        self.doneSpawnAnimState = nil;
        _hasPlayedDoneSpawnAnim = NO;
        self.animState = nil;
        _continueToNext = NO;
        flag = BOSSEVENT_FLAG_NONE;
    }
    return self;
}

- (void) dealloc
{
    self.animState = nil;
    self.doneSpawnAnimState = nil;
    self.spawner = nil;
    [super dealloc];
}

#pragma mark - TARGETPOS
- (void) setTargetPos:(CGPoint)targetPoint doneRect:(CGRect)rect
{
    CGRect playArea = [[GameManager getInstance] getPlayArea];
    _targetPoint = CGPointMake(targetPoint.x * playArea.size.width,
                             targetPoint.y * playArea.size.height);
    _bl = CGPointMake((rect.origin.x * playArea.size.width) + playArea.origin.x,
                                    (rect.origin.y * playArea.size.height) + playArea.origin.y);
    _tr = CGPointMake((rect.size.width * playArea.size.width) + _bl.x,
                      (rect.size.height * playArea.size.height) + _bl.y);

}

// returns the center point of the target box
- (CGPoint) getTargetPos
{
    return _targetPoint;
}

- (BOOL) doesTargetContainPos:(CGPoint)pos
{
    BOOL result = [BossEvent doesBoxBl:_bl tr:_tr containPoint:pos];
    return result;
}

#pragma mark - flags

- (void) setFlag:(unsigned int) flagToSet
{
    flag |= flagToSet;
}

- (BOOL) isSetFlag:(unsigned int) queryFlag
{
    BOOL result = (queryFlag & flag);
    return result;
}

#pragma mark - utilities
+ (BOOL) doesBoxBl:(CGPoint)bl tr:(CGPoint)tr containPoint:(CGPoint)queryPoint
{
    BOOL result = NO;
    if((queryPoint.x >= bl.x) && (queryPoint.x <= tr.x) &&
       (queryPoint.y >= bl.y) && (queryPoint.y <= tr.y))
    {
        result = YES;
    }
    return result;
}

@end
