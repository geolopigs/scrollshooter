//
//  AchievementsData.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/22/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "AchievementsData.h"
#import "GameCenterManager.h"

static NSString* const IDENTIFIER_KEY = @"identifier";
static NSString* const ISDIRTY_KEY = @"isDirty";
static NSString* const CURVALUE_KEY = @"curValue";
static NSString* const TGTVALUE_KEY = @"tgtValue";
static NSString* const REPORTGIMMIE_KEY = @"reportGimmie";

@implementation AchievementsData
@synthesize identifier = _identifier;
@synthesize isDirty = _isDirty;
@synthesize currentValue = _currentValue;
@synthesize targetValue = _targetValue;
@synthesize shouldReportToGimmie = _shouldReportToGimmie;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.identifier = nil;
        _isDirty = NO;
        _currentValue = 0;
        _targetValue = 1;
        _shouldReportToGimmie = NO;
    }
    return self;
}

- (id) initWithIdentifier:(NSString*)identifier targetValue:(unsigned int)target
{
    self = [super init];
    if(self)
    {
        self.identifier = identifier;
        _isDirty = NO;
        _currentValue = 0;
        if(0 < target)
        {
            _targetValue = target;
        }
        else
        {
            _targetValue = 1;
        }
        _shouldReportToGimmie = NO;
    }
    return self;
}

- (void) dealloc
{
    self.identifier = nil;
    [super dealloc];
}

#pragma mark - management
- (void) syncWithGKAchievement:(GKAchievement*)loadedAchievement
{
    if(loadedAchievement)
    {
        if([self percentComplete] < [loadedAchievement percentComplete])
        {
            float newValue = _targetValue * [loadedAchievement percentComplete] / 100.0f;
            _currentValue = static_cast<unsigned int>(newValue);
            _isDirty = NO;
        }
    }
}

- (void) markDirty
{
    _isDirty = YES;
}

- (void) markDirtyForGimmie
{
    _shouldReportToGimmie = YES;
}

#pragma mark - tracking
- (void) updateCurrentValue:(unsigned int)newValue
{
    if(newValue != _currentValue)
    {
        // check dirty flag
        if(_currentValue < _targetValue)
        {
            _isDirty = YES;
        }
        
        // update the value (clamped at targetValue)
        _currentValue = newValue;
        if(_currentValue > _targetValue)
        {
            _currentValue = _targetValue;
        }
    }
    _shouldReportToGimmie = YES;
}

- (void) updateWatermarkValue:(unsigned int)newValue
{
    if(newValue > _currentValue)
    {
        if(_currentValue < _targetValue)
        {
            _isDirty = YES;
        }
        _currentValue = newValue;
        if(_currentValue > _targetValue)
        {
            _currentValue = _targetValue;
        }
    }
    _shouldReportToGimmie = YES;
}

- (void) incrByValue:(unsigned int)increment
{
    if(_currentValue < _targetValue)
    {
        _isDirty = YES;
    }
    if((_currentValue + increment) < _targetValue)
    {
        _currentValue = _currentValue + increment;
    }
    else
    {
        _currentValue = _targetValue;
    }
    _shouldReportToGimmie = YES;
}

#pragma mark - reporting
- (float) percentComplete
{
    float result = 100.0f;
    if(_currentValue == _targetValue)
    {
        result = 100.0f;
    }
    else
    {
        result = static_cast<float>(_currentValue) / static_cast<float>(_targetValue);
        result *= 100.0f;
    }
    return result;
}

- (void) reportToGameCenter
{
    if(_isDirty)
    {
        [[GameCenterManager getInstance] reportAchievementIdentifier:_identifier percentComplete:[self percentComplete]];
        _isDirty = NO;
    }
}

- (void) reportToGimmieAsEventId:(NSString *)eventId
{
    if(_shouldReportToGimmie)
    {
        // TODO: if we want Gimmie later, report event here
        _shouldReportToGimmie = NO;
    }
}

- (BOOL) isCompleted
{
    BOOL result = (_currentValue == _targetValue);
    return result;
}

- (BOOL) isNewlyCompleted
{
    BOOL result = NO;
    if(_isDirty)
    {
        result = [self isCompleted];
    }
    return result;
}

#pragma mark - NSCoding methods

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_identifier forKey:IDENTIFIER_KEY];
    [coder encodeObject:[NSNumber numberWithBool:_isDirty] forKey:ISDIRTY_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:_currentValue] forKey:CURVALUE_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:_targetValue] forKey:TGTVALUE_KEY];
    [coder encodeObject:[NSNumber numberWithBool:_shouldReportToGimmie] forKey:REPORTGIMMIE_KEY];
}

- (id) initWithCoder:(NSCoder *) decoder
{
    self.identifier = [decoder decodeObjectForKey:IDENTIFIER_KEY];
    
    NSNumber* decoderIsDirty = [decoder decodeObjectForKey:ISDIRTY_KEY];
    if(decoderIsDirty)
    {
        _isDirty = [decoderIsDirty boolValue];
    }
    else
    {
        _isDirty = YES;
    }
    
    NSNumber* decoderCurValue = [decoder decodeObjectForKey:CURVALUE_KEY];
    if(decoderCurValue)
    {
        _currentValue = [decoderCurValue unsignedIntValue];
    }
    else
    {
        _currentValue = 0;
    }
    
    NSNumber* decoderTgtValue = [decoder decodeObjectForKey:TGTVALUE_KEY];
    if(decoderTgtValue)
    {
        _targetValue = [decoderTgtValue unsignedIntValue];
    }
    else
    {
        _targetValue = 1;
    }
    
    NSNumber* decoderReportGimmie = [decoder decodeObjectForKey:REPORTGIMMIE_KEY];
    if(decoderReportGimmie)
    {
        _shouldReportToGimmie = [decoderReportGimmie boolValue];
    }
    else
    {
        _shouldReportToGimmie = NO;
    }
    
	return self;
}

@end
