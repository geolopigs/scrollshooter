//
//  StatsData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "StatsData.h"
#import "EnvScoreData.h"
#import "AchievementsData.h"
#import "StatsManager.h"

const unsigned int STATS_FLAG_COMPLETEDTUTORIAL = 0x01;
const unsigned int STATS_FLAG_COMPLETEDTUTORIALTOURNEY = 0x02;

static NSString* const GLOBALHIGHSCORE_KEY = @"globalHighscore";
static NSString* const ENVSCORES_KEY = @"envScores";
static NSString* const FLIGHTTIME_KEY = @"flightTime";
static NSString* const CARGOSDELIVERED_KEY = @"cargosDelivered";
static NSString* const ACHIEVEMENTSDATA_KEY = @"achievementsData";
static NSString* const POGCOINS_KEY = @"pogcoins";
static NSString* const HIGHMULTIPLIER_KEY = @"highMultiplier";
static NSString* const TOURNEYWINS_KEY = @"tourneyWins";
static NSString* const FLAGS_KEY = @"flags";

@interface StatsData (PrivateMethods)
- (EnvScoreData*) getEntryWithEnv:(NSString*)envName leveIndex:(unsigned int)levelIndex;
@end

@implementation StatsData
@synthesize highscore;
@synthesize envScores;
@synthesize flightTime = _flightTime;
@synthesize cargosDelivered = _cargosDelivered;
@synthesize pogcoinsCollected = _pogcoinsCollected;
@synthesize highMultiplier = _highMultiplier;
@synthesize numTourneyWins = _numTourneyWins;
@synthesize achievements = _achievements;
@synthesize flags = _flags;

- (id)init
{
    self = [super init];
    if (self) 
    {
        highscore = 0;
        _flightTime = 0.0;
        _cargosDelivered = 0;
        _pogcoinsCollected = 0;
        _highMultiplier = 1;
        _numTourneyWins = 0;
        self.envScores = [NSMutableDictionary dictionary];
        self.achievements = [NSMutableDictionary dictionary];
        _flags = 0;
    }
    
    return self;
}

- (void) dealloc
{
    self.achievements = nil;
    self.envScores = nil;
    [super dealloc];
}

- (EnvScoreData*) getEntryWithEnv:(NSString *)envName leveIndex:(unsigned int)levelIndex
{
    NSString* entryKey = [NSString stringWithFormat:@"%@_%d", envName, levelIndex];
    EnvScoreData* entry = [envScores objectForKey:entryKey];
    if(!entry)
    {
        // entry does not exist, create a new one
        entry = [[[EnvScoreData alloc] initWithEnv:envName level:levelIndex] autorelease];
        if(!entry)
        {
            NSLog(@"failed to get entry for %@", entryKey);
        }
        else
        {
            [envScores setObject:entry forKey:entryKey];
        }
    }
    return entry;
}

#pragma mark - accessor functions

- (void) setHighscore:(unsigned int)newScore forEnv:(NSString*)envName level:(unsigned int)levelIndex
{
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        // entry exists, update it
        entry.highscore = newScore;
    }
}

- (void) setGradeScore:(unsigned int)newScore forEnv:(NSString*)envName level:(unsigned int)levelIndex
{
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        // entry exists, update it
        entry.gradeScore = newScore;
    }
}

- (unsigned int) getHighscoreForEnv:(NSString*)envName level:(unsigned int)levelIndex
{
    unsigned int result = 0;
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        result = [entry highscore];
    }
    return result;
}

- (unsigned int) getGradeScoreForEnv:(NSString*)envName level:(unsigned int)levelIndex
{
    unsigned int result = 0;
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        result = [entry gradeScore];
    }
    return result;
}

- (void) setFlightTime:(NSTimeInterval)flightTime forEnv:(NSString *)envName level:(unsigned int)levelIndex
{
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        entry.flightTime = flightTime;
    }
}

- (NSTimeInterval) getFlightTimeForEnv:(NSString *)envName level:(unsigned int)levelIndex
{
    NSTimeInterval result = 0.0;
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        result = [entry flightTime];
    }
    return result;
}

- (void) setCargosDelivered:(unsigned int)cargos forEnv:(NSString *)envName level:(unsigned int)levelIndex
{
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        entry.cargosDeliveredHigh = cargos;
    }
}

- (unsigned int) getCargosDeliveredForEnv:(NSString *)envName level:(unsigned int)levelIndex
{
    unsigned int result = 0;
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        result = [entry cargosDeliveredHigh];
    }
    return result;
}

- (void) setHasCompleted:(BOOL)yesNo forEnv:(NSString*)envName level:(unsigned int)levelIndex
{
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        // entry exists, update it
        entry.hasCompleted = yesNo;
    }
}


- (BOOL) hasCompletedForEnv:(NSString *)envName level:(unsigned int)levelIndex
{
    BOOL result = NO;
    EnvScoreData* entry = [self getEntryWithEnv:envName leveIndex:levelIndex];
    if(entry)
    {
        result = [entry hasCompleted];
    }
    return result;    
}

- (void) resetHighscores
{
    highscore = 0;
    _flightTime = 0.0;
    _cargosDelivered = 0;
    [envScores removeAllObjects];
}


#pragma mark - NSCoding methods

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[NSNumber numberWithUnsignedInt:highscore] forKey:GLOBALHIGHSCORE_KEY];
    [coder encodeObject:envScores forKey:ENVSCORES_KEY];
    [coder encodeObject:_achievements forKey:ACHIEVEMENTSDATA_KEY];
    [coder encodeObject:[NSNumber numberWithDouble:_flightTime] forKey:FLIGHTTIME_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:_cargosDelivered] forKey:CARGOSDELIVERED_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:_pogcoinsCollected] forKey:POGCOINS_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:_highMultiplier] forKey:HIGHMULTIPLIER_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:_numTourneyWins] forKey:TOURNEYWINS_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:_flags] forKey:FLAGS_KEY];
}

- (id) initWithCoder:(NSCoder *) decoder
{
    NSNumber* highscoreNumber = [decoder decodeObjectForKey:GLOBALHIGHSCORE_KEY];
    self.highscore = [highscoreNumber unsignedIntValue];    
    self.envScores = [decoder decodeObjectForKey:ENVSCORES_KEY];
    
    NSNumber* flightTimeNumber = [decoder decodeObjectForKey:FLIGHTTIME_KEY];
    if(flightTimeNumber)
    {
        _flightTime = [flightTimeNumber doubleValue];
    }
    else
    {
        _flightTime = 0.0f;
    }
    
    NSNumber* cargosDeliveredNumber = [decoder decodeObjectForKey:CARGOSDELIVERED_KEY];
    if(cargosDeliveredNumber)
    {
        _cargosDelivered = [cargosDeliveredNumber unsignedIntValue];
    }
    else
    {
        _cargosDelivered = 0;
    }
    
    NSNumber* pogcoinsNumber = [decoder decodeObjectForKey:POGCOINS_KEY];
    if(pogcoinsNumber)
    {
        _pogcoinsCollected = [pogcoinsNumber unsignedIntValue];
    }
    else
    {
        // for backward compatibility, init with existing coins player already has
        _pogcoinsCollected = [[StatsManager getInstance] getTotalCash];
    }
    
    // highest multiplier
    NSNumber* highMultNumber = [decoder decodeObjectForKey:HIGHMULTIPLIER_KEY];
    if(highMultNumber)
    {
        _highMultiplier = [highMultNumber unsignedIntValue];
    }
    else
    {
        _highMultiplier = 1;
    }
    
    // num tourney wins
    NSNumber* tourneyWinsNumber = [decoder decodeObjectForKey:TOURNEYWINS_KEY];
    if(tourneyWinsNumber)
    {
        _numTourneyWins = [tourneyWinsNumber unsignedIntValue];
    }
    else
    {
        _numTourneyWins = 0;
    }
    
    NSMutableDictionary* achievementsFromFile = [decoder decodeObjectForKey:ACHIEVEMENTSDATA_KEY];
    if(achievementsFromFile)
    {
        self.achievements = achievementsFromFile;
    }
    else
    {
        // for backward compatibility, create it
        self.achievements = [NSMutableDictionary dictionary];
    }
    
    NSNumber* flagsNumber = [decoder decodeObjectForKey:FLAGS_KEY];
    if(flagsNumber)
    {
        _flags = [flagsNumber unsignedIntValue];
    }
    else
    {
        _flags = 0;
    }

	return self;
}

@end
