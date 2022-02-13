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
@class AddonData;
@interface Boss2Context : NSObject

// runtime
@property (nonatomic,retain) NSMutableArray* enemyLayers;
@property (nonatomic,retain) NSMutableArray* attachedEnemies;
@property (nonatomic,assign) float timeTillFire;
@property (nonatomic,assign) unsigned int behaviorState;
@property (nonatomic,retain) SineWeaver* weaverX;
@property (nonatomic,retain) SineWeaver* weaverY;
@property (nonatomic,assign) CGPoint initPos;
@property (nonatomic,assign) float cruisingTimer;
@property (nonatomic,assign) unsigned int curWeaponLayer;
@property (nonatomic,assign) float timeTillNextLayerFire;
@property (nonatomic,assign) BOOL isNextLayerWaiting;
@property (nonatomic,assign) BOOL collisionOn;
@property (nonatomic,retain) const NSString* curAnimState;

// configs
@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@property (nonatomic,assign) unsigned int spawnEffectBucketIndex;
@property (nonatomic,assign) float faceDir;
@property (nonatomic,assign) float timeBetweenShots;
@property (nonatomic,assign) float shotSpeed;
@property (nonatomic,assign) CGPoint introVel;
@property (nonatomic,assign) CGPoint introDoneBotLeft;
@property (nonatomic,assign) CGPoint introDoneTopRight;
@property (nonatomic,assign) CGPoint cruiseBoxBotLeft;
@property (nonatomic,assign) CGPoint cruiseBoxTopRight;
@property (nonatomic,assign) CGPoint colAreaBotLeft;
@property (nonatomic,assign) CGPoint colAreaTopRight;
@property (nonatomic,assign) BOOL hasCruiseBox;
@property (nonatomic,retain) AddonData* addonData;
@property (nonatomic,assign) float cruisingTimeout;
@property (nonatomic,assign) CGPoint exitVel;
@property (nonatomic,assign) CGPoint cruisingVel;
@property (nonatomic,assign) unsigned int health;
@property (nonatomic,assign) unsigned int numCargos;
@property (nonatomic,assign) BOOL isCollidable;
@property (nonatomic,assign) unsigned int numWeaponLayers;
@property (nonatomic,retain) NSDictionary* triggerContext;
@property (nonatomic,retain) NSString* unblockScrollCamName;
@property (nonatomic,assign) CGPoint colOrigin;
@property (nonatomic,retain) NSMutableDictionary* animStates;

- (void) setupFromContextDictionary:(NSDictionary*)triggerContext;
- (BOOL) areAttachedEnemiesIncapacitated;
- (unsigned int) numAttachedEnemiesAlive;
- (unsigned int) numAliveInLayer:(unsigned int)layerIndex;
- (BOOL) hasNextWeaponLayer;
- (BOOL) isFinalLayer;
@end

@interface Boss2 : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemyParentDelegate,EnemySpawnedDelegate>
@property (nonatomic,retain) NSString* typeName;
@property (nonatomic,retain) NSString* sizeName;
@property (nonatomic,retain) NSString* addonsName;
@property (nonatomic,retain) NSString* soundClipName;
- (id) initWithTypeName:(NSString*)givenTypeName sizeName:(NSString*)givenSizeName addonsName:(NSString*)givenAddonsName;

@end
