//
//  EnvData.h
//  PeterPog
//
//  Env contains multiple Levels; it is an environment in which Levels take place;
//  eg. Homebase is an Env
//
//  Created by Shu Chiun Cheah on 8/19/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameModes.h"

@interface EnvLevelData : NSObject
{
    NSString* routeType;
    NSString* routeName;
    NSString* serviceName;
    NSString* fileName;
    NSString* animName;
    NSString* pathsName;
    NSString* triggersName;
    NSString* commonAnimName;
    unsigned int scoreA;
    unsigned int scoreB;
    unsigned int scoreC;
}
@property (nonatomic,retain) NSString* routeType;
@property (nonatomic,retain) NSString* routeName;
@property (nonatomic,retain) NSString* serviceName;
@property (nonatomic,retain) NSString* fileName;
@property (nonatomic,retain) NSString* animName;
@property (nonatomic,retain) NSString* pathsName;
@property (nonatomic,retain) NSString* triggersName;
@property (nonatomic,retain) NSString* commonAnimName;
@property (nonatomic,assign) unsigned int scoreA;
@property (nonatomic,assign) unsigned int scoreB;
@property (nonatomic,assign) unsigned int scoreC;
- (id) initFromDictionary:(NSDictionary*)dict commonAnimName:(NSString*)commonAnimFilename;
@end

@interface EnvInfo : NSObject
{
}
@property (nonatomic,retain) NSDictionary* info;
@property (nonatomic,retain) NSMutableArray* levels;
- (id) initWithDictionary:(NSDictionary*)givenEnvInfo levelsArray:(NSMutableArray*)givenArray;
@end

@interface EnvData : NSObject
{
    NSDictionary* fileData;
    NSArray*        envList;
    NSMutableArray* envNames;
    NSMutableDictionary* envRegistry;
}
@property (nonatomic,retain) NSDictionary* fileData;
@property (nonatomic,retain) NSArray* envList;
@property (nonatomic,retain) NSMutableArray* envNames;
@property (nonatomic,retain) NSMutableDictionary* envRegistry;
- (id) initFromFilename:(NSString*)filename;
- (NSArray*) getLevelsArrayForEnvNamed:(NSString*)envName;
- (int) getNumContinuesForEnvNamed:(NSString*)envName;
- (GameMode) getGameModeForEnvNamed:(NSString*)envName;
@end
