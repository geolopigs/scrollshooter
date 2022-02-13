//
//  EnvData.mm
//  PeterPog
//
//  Env contains multiple Levels; it is an environment in which Levels take place;
//  eg. Homebase is an Env
//
//  Created by Shu Chiun Cheah on 8/19/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "EnvData.h"

@implementation EnvLevelData
@synthesize routeType;
@synthesize routeName;
@synthesize serviceName;
@synthesize fileName;
@synthesize animName;
@synthesize pathsName;
@synthesize triggersName;
@synthesize commonAnimName;
@synthesize scoreA;
@synthesize scoreB;
@synthesize scoreC;

- (id) initFromDictionary:(NSDictionary *)dict commonAnimName:(NSString*)commonAnimFilename
{
    self = [super init];
    if(self)
    {
        self.routeType = [dict objectForKey:@"routeType"];
        self.routeName = [dict objectForKey:@"routeName"];
        self.serviceName = [dict objectForKey:@"serviceName"];
        self.fileName = [dict objectForKey:@"file"];
        self.animName = [dict objectForKey:@"anim"];
        self.pathsName = [dict objectForKey:@"paths"];
        self.triggersName = [dict objectForKey:@"triggers"];
        self.commonAnimName = commonAnimFilename;
        self.scoreA = 5000;
        self.scoreB = 3500;
        self.scoreC = 1500;
        NSNumber* scoreANum = [dict objectForKey:@"scoreA"];
        NSNumber* scoreBNum = [dict objectForKey:@"scoreB"];
        NSNumber* scoreCNum = [dict objectForKey:@"scoreC"];
        if(scoreANum && scoreBNum && scoreCNum)
        {
            self.scoreA = [scoreANum unsignedIntValue];
            self.scoreB = [scoreBNum unsignedIntValue];
            self.scoreC = [scoreCNum unsignedIntValue];
        }
    }
    return self;
}

- (void) dealloc
{
    self.commonAnimName = nil;
    self.triggersName = nil;
    self.pathsName = nil;
    self.animName = nil;
    self.fileName = nil;
    self.serviceName = nil;
    self.routeName = nil;
    self.routeType = nil;
    [super dealloc];
}


@end

@implementation EnvInfo
@synthesize info;
@synthesize levels;
- (id) initWithDictionary:(NSDictionary *)givenEnvInfo levelsArray:(NSMutableArray*)givenArray
{
    self = [super init];
    if(self)
    {
        self.info = givenEnvInfo;
        self.levels = givenArray;
    }
    return self;
}

- (void) dealloc
{
    self.levels = nil;
    self.info = nil;
    [super dealloc];
}


@end

@implementation EnvData
@synthesize fileData;
@synthesize envList;
@synthesize envNames;
@synthesize envRegistry;
- (id)initFromFilename:(NSString *)filename
{
    self = [super init];
    if (self) 
    {
        // load dictionary from file
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"];
        self.fileData = [NSDictionary dictionaryWithContentsOfFile:path];
        self.envList = [fileData objectForKey:@"envList"];
        
        // enumerate env names and populate registry
        self.envNames = [NSMutableArray arrayWithCapacity:[envList count]];
        self.envRegistry = [NSMutableDictionary dictionaryWithCapacity:[envList count]];
        for(NSDictionary* cur in envList)
        {
            NSString* name = [cur objectForKey:@"name"];
            [envNames addObject:name];

            NSString* commonAnim = [cur objectForKey:@"commonAnim"];
            NSArray* levels = [cur objectForKey:@"levels"];
            NSMutableArray* envLevels = [NSMutableArray array];
            for(NSDictionary* curLevel in levels)
            {
                EnvLevelData* newLevel = [[EnvLevelData alloc] initFromDictionary:curLevel commonAnimName:commonAnim];
                [envLevels addObject:newLevel];
                [newLevel release];
            }
            
            EnvInfo* newInfo = [[EnvInfo alloc] initWithDictionary:[cur objectForKey:@"info"] levelsArray:envLevels];
            [envRegistry setObject:newInfo forKey:name];
            [newInfo release];
        }
    }
    
    return self;
}

- (void) dealloc
{
    self.envRegistry = nil;
    self.envNames = nil;
    self.envList = nil;
    self.fileData = nil;
    [super dealloc];
}

- (NSArray*) getLevelsArrayForEnvNamed:(NSString*)envName
{
    EnvInfo* envInfo = [envRegistry objectForKey:envName];
    assert(envInfo);
    assert([envInfo levels]);
    return [envInfo levels];
}

- (int) getNumContinuesForEnvNamed:(NSString *)envName
{
    int result = 0;
    /*
    EnvInfo* envInfo = [envRegistry objectForKey:envName];
    if(envInfo)
    {
        NSNumber* numContinuesNumber = [[envInfo info] objectForKey:@"numContinues"];
        if(numContinuesNumber)
        {
            result = [numContinuesNumber intValue];
        }
    }
     */
    return result;
}

- (GameMode) getGameModeForEnvNamed:(NSString *)envName
{
   GameMode result = GAMEMODE_CAMPAIGN;
    EnvInfo* envInfo = [envRegistry objectForKey:envName];
    if(envInfo)
    {
        NSString* gameModeStr = [[envInfo info] objectForKey:@"gameMode"];
        if([gameModeStr isEqualToString:@"Timebased"])
        {
            result = GAMEMODE_TIMEBASED;
        }
    }    
    return result;
}

@end
