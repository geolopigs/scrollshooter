//
//  EnvScoreData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "EnvScoreData.h"

static NSString* const ENVNAME_KEY = @"envName";
static NSString* const LEVELINDEX_KEY = @"levelIndex";
static NSString* const HIGHSCORE_KEY = @"highscore";
static NSString* const HASCOMPLETED_KEY = @"hasCompleted";
static NSString* const GRADESCORE_KEY = @"gradeScore";
static NSString* const FLIGHTTIME_KEY = @"flightTime";
static NSString* const CARGOS_KEY = @"cargos";

@implementation EnvScoreData
@synthesize envName;
@synthesize levelIndex;
@synthesize highscore;
@synthesize hasCompleted;
@synthesize gradeScore;
@synthesize flightTime = _flightTime;
@synthesize cargosDeliveredHigh = _cargosDeliveredHigh;

- (id)initWithEnv:(NSString*)env level:(unsigned int)level
{
    self = [super init];
    if (self) 
    {
        self.envName = env;
        self.levelIndex = level;
        self.highscore = 0;
        self.hasCompleted = NO;
        self.gradeScore = 0;
        self.flightTime = 0.0;
        self.cargosDeliveredHigh = 0;
    }
    
    return self;
}

- (void) dealloc
{
    self.envName = nil;
    [super dealloc];
}


#pragma mark - NSCoding methods

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:envName forKey:ENVNAME_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:levelIndex] forKey:LEVELINDEX_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:highscore] forKey:HIGHSCORE_KEY];
    [coder encodeObject:[NSNumber numberWithBool:hasCompleted] forKey:HASCOMPLETED_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:gradeScore] forKey:GRADESCORE_KEY];
    [coder encodeObject:[NSNumber numberWithDouble:_flightTime] forKey:FLIGHTTIME_KEY];
    [coder encodeObject:[NSNumber numberWithUnsignedInt:_cargosDeliveredHigh] forKey:CARGOS_KEY];
}

- (id) initWithCoder:(NSCoder *) decoder
{
    self.envName = [decoder decodeObjectForKey:ENVNAME_KEY];
    
    NSNumber* levelIndexNumber = [decoder decodeObjectForKey:LEVELINDEX_KEY];
    self.levelIndex = [levelIndexNumber unsignedIntValue];
	
    NSNumber* highscoreNumber = [decoder decodeObjectForKey:HIGHSCORE_KEY];
    self.highscore = [highscoreNumber unsignedIntValue];
    
    NSNumber* hasCompletedNumber = [decoder decodeObjectForKey:HASCOMPLETED_KEY];
    self.hasCompleted = [hasCompletedNumber boolValue];
    
    NSNumber* gradeScoreNumber = [decoder decodeObjectForKey:GRADESCORE_KEY];
    if(gradeScoreNumber)
    {
        self.gradeScore = [gradeScoreNumber unsignedIntValue];
    }
    else
    {
        // player updated from a saved-file that does not yet have gradescore
        // so, assign them zero so that they have to play the levels over
        self.gradeScore = 0;
    }
    
    NSNumber* flightTimeNumber = [decoder decodeObjectForKey:FLIGHTTIME_KEY];
    if(flightTimeNumber)
    {
        self.flightTime = [flightTimeNumber doubleValue];
    }
    else
    {
        self.flightTime = 0.0;
    }
    
    NSNumber* cargosDeliveredNumber = [decoder decodeObjectForKey:CARGOS_KEY];
    if(cargosDeliveredNumber)
    {
        self.cargosDeliveredHigh = [cargosDeliveredNumber unsignedIntValue];
    }
    else
    {
        self.cargosDeliveredHigh = 0;
    }
    
	return self;
}

@end
