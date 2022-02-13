//
//  BossArchetype.h
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
@interface BossContext : NSObject
{
    // runtime params
    NSMutableArray* enemyLayers;
    NSMutableArray* attachedEnemies;
    float timeTillFire;
    unsigned int behaviorState;
    SineWeaver* weaverX;
    SineWeaver* weaverY;
    CGPoint initPos;
    float cruisingTimer;
    unsigned int curWeaponLayer;
    float timeTillNextLayerFire;
    BOOL isNextLayerWaiting;
    NSMutableArray* bossWeapon;
    BOOL collisionOn;
    BOOL burningEffectActivated;
    const NSString* curAnimState;
    NSMutableArray* spawnAddons;
    
    // config params
    unsigned int dynamicsAddonsIndex;
    unsigned int spawnEffectBucketIndex;
    float timeBetweenShots;
    float shotSpeed;
    CGPoint introVel;
    CGPoint introDoneBotLeft;
    CGPoint introDoneTopRight;
    CGPoint cruiseBoxBotLeft;
    CGPoint cruiseBoxTopRight;
    CGPoint colAreaBotLeft;
    CGPoint colAreaTopRight;
    BOOL hasCruiseBox;
    AddonData* addonData;
    float cruisingTimeout;
    CGPoint exitVel;
    CGPoint cruisingVel;
    int health;
    unsigned int numCargos;
    BOOL isCollidable;
    unsigned int numWeaponLayers;
    NSDictionary* triggerContext;
    NSDictionary* boarTriggerContext;
    NSDictionary* singleTriggerContext;
    NSDictionary* doubleTriggerContext;
    NSString* unblockScrollCamName;
    BOOL hasDestroyedState;
    BOOL allLayers;                 // TRUE to spawn all enemies at the beginning but activate them layer by layer
                                    // a layer will be activated if its predecessor has less than half of its enemies remain
}
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
@property (nonatomic,retain) NSMutableArray* bossWeapon;
@property (nonatomic,assign) BOOL collisionOn;
@property (nonatomic,assign) BOOL burningEffectActivated;
@property (nonatomic,retain) const NSString* curAnimState;
@property (nonatomic,retain) NSMutableArray* spawnAddons;
@property (nonatomic,retain) NSMutableArray* bossAddons;    // boss weapon fixtures
@property (nonatomic,assign) BOOL bossActivated;

@property (nonatomic,assign) unsigned int dynamicsAddonsIndex;
@property (nonatomic,assign) unsigned int spawnEffectBucketIndex;
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
@property (nonatomic,assign) int health;
@property (nonatomic,assign) unsigned int numCargos;
@property (nonatomic,assign) BOOL isCollidable;
@property (nonatomic,assign) unsigned int numWeaponLayers;
@property (nonatomic,retain) NSDictionary* triggerContext;
@property (nonatomic,retain) NSDictionary* boarTriggerContext;
@property (nonatomic,retain) NSDictionary* singleTriggerContext;
@property (nonatomic,retain) NSDictionary* doubleTriggerContext;
@property (nonatomic,retain) NSString* unblockScrollCamName;
@property (nonatomic,assign) BOOL hasDestroyedState;
@property (nonatomic,assign) BOOL allLayers;
@property (nonatomic,retain) NSMutableArray* bossFixtureClipnames;
@property (nonatomic,retain) NSMutableArray* bossActiveClipnames;
@property (nonatomic,assign) CGPoint colOrigin;
@property (nonatomic,assign) BOOL bossWeaponEarlyActivation;

- (BOOL) areAttachedEnemiesIncapacitated;
- (unsigned int) numAttachedEnemiesAlive;
- (unsigned int) numAliveInLayer:(unsigned int)layerIndex;
- (BOOL) hasNextWeaponLayer;
- (BOOL) isFinalLayer;
@end

@interface BossArchetype : NSObject<EnemyInitProtocol,EnemyBehaviorProtocol,EnemyCollisionResponse,EnemyKilledDelegate,EnemyParentDelegate,EnemySpawnedDelegate>
{
    NSString* typeName;
    NSString* sizeName;
    NSString* clipName;
    NSString* addonsName;
    NSString* destructionEffectName;
    NSString* destructionAddonName;
    NSString* soundClipName;
    NSString* introClipName;
    NSString* spawnAddonName;
}
@property (nonatomic,retain) NSString* typeName;
@property (nonatomic,retain) NSString* sizeName;
@property (nonatomic,retain) NSString* clipName;
@property (nonatomic,retain) NSString* addonsName;
@property (nonatomic,retain) NSString* destructionEffectName;
@property (nonatomic,retain) NSString* destructionAddonName;
@property (nonatomic,retain) NSString* soundClipName;
@property (nonatomic,retain) NSString* introClipName;
@property (nonatomic,retain) NSString* spawnAddonName;

- (id) initWithTypeName:(NSString*)givenName 
               sizeName:(NSString*)givenSizeName 
               clipName:(NSString*)givenClipName 
             addonsName:(NSString*)givenAddonsName
  destructionEffectName:(NSString*)givenDestructionEffectName
          soundClipName:(NSString*)givenSoundClipName;

- (id) initWithTypeName:(NSString*)givenName 
               sizeName:(NSString*)givenSizeName 
               clipName:(NSString*)givenClipName 
             addonsName:(NSString*)givenAddonsName
  destructionEffectName:(NSString*)givenDestructionEffectName
   destructionAddonName:(NSString*)givenDestructionAddonName
          soundClipName:(NSString*)givenSoundClipName
          introClipName:(NSString*)givenIntroClipName
         spawnAddonName:(NSString*)givenSpawnAddonName;
@end
