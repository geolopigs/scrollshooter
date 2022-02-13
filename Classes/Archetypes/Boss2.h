//
//  Boss2.h
//  PeterPog
//  
//  Generic Boss archetype
//
//  Created by Shu Chiun Cheah on 9/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"


@class SineWeaver;
@class SpawnersData;
@class EnemySpawner;
@interface Boss2Context : NSObject

// runtime
@property (nonatomic,retain) NSMutableArray* subSpawners;
@property (nonatomic,assign) float timeTillFire;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,retain) SineWeaver* weaverX;
@property (nonatomic,retain) SineWeaver* weaverY;
@property (nonatomic,assign) CGPoint initPos;
@property (nonatomic,assign) float cruisingTimer;
@property (nonatomic,assign) BOOL collisionOn;
@property (nonatomic,retain) const NSString* curAnimState;
@property (nonatomic,retain) EnemySpawner* bossGroup;
@property (nonatomic,assign) unsigned int curTimelineEvent;
@property (nonatomic,assign) float curTimelineTimer;
@property (nonatomic,assign) float destroyTimer;

// configs
@property (nonatomic,retain) NSMutableDictionary* subSpawnerConfigs;
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@property (nonatomic,assign) unsigned int spawnEffectBucketIndex;
@property (nonatomic,assign) float faceDir;
@property (nonatomic,assign) CGPoint introVel;
@property (nonatomic,assign) CGPoint introDoneBotLeft;
@property (nonatomic,assign) CGPoint introDoneTopRight;
@property (nonatomic,assign) CGPoint cruiseBoxBotLeft;
@property (nonatomic,assign) CGPoint cruiseBoxTopRight;
@property (nonatomic,assign) CGPoint colAreaBotLeft;
@property (nonatomic,assign) CGPoint colAreaTopRight;
@property (nonatomic,assign) BOOL hasCruiseBox;
@property (nonatomic,retain) SpawnersData* spawnersData;
@property (nonatomic,assign) float cruisingTimeout;
@property (nonatomic,assign) CGPoint exitVel;
@property (nonatomic,assign) float cruisingSpeed;
@property (nonatomic,assign) int health;
@property (nonatomic,assign) unsigned int numCargos;
@property (nonatomic,assign) BOOL isCollidable;
@property (nonatomic,retain) NSString* unblockScrollCamName;
@property (nonatomic,assign) CGPoint colOrigin;
@property (nonatomic,retain) NSMutableArray* timeline;
@property (nonatomic,retain) NSMutableDictionary* effectAddonsReg;
@property (nonatomic,assign) float destroyDelay;        // delay to allow the explosion some screen time

// setup
- (void) setupFromContextDictionary:(NSDictionary*)triggerContext;
- (void) setupFromSpawnersData:(SpawnersData *)givenSpawnersData onEnemy:(Enemy*)enemy;

// queries
- (BOOL) isInTimelineSpawnerNamed:(NSString*)spawnerGroupName;
@end

@interface Boss2 : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemySpawnedDelegate>
@property (nonatomic,retain) NSString* typeName;
@property (nonatomic,retain) NSString* sizeName;
@property (nonatomic,retain) NSString* spawnersDataName;
@property (nonatomic,retain) NSString* soundClipName;
@property (nonatomic,retain) NSString* introSoundName;
@property (nonatomic,retain) NSString* incapSoundName;
@property (nonatomic,retain) NSDictionary* animStates;
@property (nonatomic,retain) NSDictionary* effectAddons;
- (id) initWithTypeName:(NSString*)givenTypeName 
               sizeName:(NSString*)givenSizeName 
       spawnersDataName:(NSString*)givenSpawnersDataName 
             animStates:(NSDictionary*)givenAnimStates;

@end
