//
//  AchievementRegEntry.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 11/23/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern unsigned int SERVER_TYPE_NONE;
extern unsigned int SERVER_TYPE_GAMECENTER;  
extern unsigned int SERVER_TYPE_GIMMIEWORLD;

@interface AchievementRegEntry : NSObject
{
    NSString* const _description;
    NSString* const _progressFormat;
    unsigned int _supportedServerFlags;
    NSString* _gimmieID;
}
@property (nonatomic,retain) NSString* name;
@property (nonatomic,retain) NSString* const description;
@property (nonatomic,retain) NSString* const progressFormat;
@property (nonatomic,assign) unsigned int targetValue;
@property (nonatomic,assign) unsigned int supportedServerFlags;
@property (nonatomic,retain) NSString* gimmieID;

- (id) initWithName:(NSString*)name description:(NSString* const)desc targetValue:(unsigned int)targetValue supports:(unsigned int)supportedServers;

// server supports
- (BOOL) supportsGameCenter;
- (BOOL) supportsGimmieWorld;

// creation methods
+ (AchievementRegEntry*)newWithName:(NSString*)name description:(NSString* const) desc targetValue:(unsigned int)targetValue;
+ (AchievementRegEntry*)newWithName:(NSString *)name description:(NSString* const) desc targetValue:(unsigned int)targetValue 
                           supports:(unsigned int)supportedServers gimmieID:(NSString*)gimmieWorldIdentifier;
@end
