//
//  AchievementRegEntry.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/23/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "AchievementRegEntry.h"

// server type flags
unsigned int SERVER_TYPE_NONE = 0x00;
unsigned int SERVER_TYPE_GAMECENTER = 0x01;  
unsigned int SERVER_TYPE_GIMMIEWORLD = 0x02;


@implementation AchievementRegEntry
@synthesize name = _name;
@synthesize description = _description;
@synthesize progressFormat = _progressFormat;
@synthesize targetValue = _targetValue;
@synthesize supportedServerFlags = _supportedServerFlags;
@synthesize gimmieID = _gimmieID;

- (id) initWithName:(NSString*)name description:(NSString* const) desc targetValue:(unsigned int)targetValue supports:(unsigned int)supportedServers
{
    self = [super init];
    if(self)
    {
        self.name = name;
        self.description = desc;
        self.progressFormat = nil;
        self.targetValue = targetValue;
        self.supportedServerFlags = supportedServers;
        self.gimmieID = nil;
    }
    return self;
}

- (void) dealloc
{
    self.gimmieID = nil;
    self.progressFormat = nil;
    self.description = nil;
    self.name = nil;
    [super dealloc];
}

#pragma mark - server supports
- (BOOL) supportsGameCenter
{
    BOOL result = (_supportedServerFlags & SERVER_TYPE_GAMECENTER);
    return result;
}

- (BOOL) supportsGimmieWorld
{
    BOOL result = (_supportedServerFlags & SERVER_TYPE_GIMMIEWORLD);
    return result;
}

#pragma mark - creation methods

+ (AchievementRegEntry*)newWithName:(NSString *)name description:(NSString* const)desc targetValue:(unsigned int)targetValue
{
    // defaults to GameCenter only support
    AchievementRegEntry* newEntry = [[AchievementRegEntry alloc] initWithName:name description:desc targetValue:targetValue supports:SERVER_TYPE_GAMECENTER];
    return [newEntry autorelease];
}

+ (AchievementRegEntry*)newWithName:(NSString *)name description:(NSString* const)desc targetValue:(unsigned int)targetValue supports:(unsigned int)supportedServers gimmieID:(NSString*)gimmieWorldIdentifier
{
    // defaults to GameCenter only support
    AchievementRegEntry* newEntry = [[AchievementRegEntry alloc] initWithName:name description:desc targetValue:targetValue supports:supportedServers];
    newEntry.gimmieID = gimmieWorldIdentifier;
    return [newEntry autorelease];
}

@end
