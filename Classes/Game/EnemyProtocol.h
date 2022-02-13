//
//  EnemyProtocol.h
//

#import <UIKit/UIKit.h>

@class Enemy;
@class EnemySpawner;

// individual enemy protocols
@protocol EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy;
@optional
- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(id)spawnerContext;
- (NSString*) getEnemyTypeName;
@end

@protocol EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy*)givenEnemy;
@optional   // only need to implement if added to GameManager triggerEnemies
- (void) enemyBehavior:(Enemy*)givenEnemy receiveTrigger:(NSString*)label;
- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy;
@end

@protocol EnemyBehaviorContext <NSObject>
- (void) setupFromConfig:(NSDictionary*)config;
- (int) getInitHealth;
- (unsigned int) getFlags;
- (void) setFlags:(unsigned int)newFlags;
@end

@protocol EnemyCollisionResponse <NSObject>
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB;
- (BOOL) isPlayerCollidable;
- (BOOL) isPlayerWeapon;
- (BOOL) isCollidable;          // whether this object should be added to collision manager at all
- (BOOL) isCollisionOnFor:(Enemy*)enemy;         // whether collision is turned ON for the object at the moment
@end

@protocol EnemyAABBDelegate <NSObject>
- (CGRect) getAABB:(Enemy*)givenEnemy;
@end

@protocol EnemyKilledDelegate <NSObject>
- (void) killEnemy:(Enemy*)givenEnemy; 
- (BOOL) incapacitateEnemy:(Enemy*)givenEnemy showPoints:(BOOL)showPoints;
@end

// called by enemy to remove itself from the attachedEnemies list of its parent
// for enemies that were spawned as addons of their parent
@protocol EnemyParentDelegate <NSObject>
- (void) removeFromParent:(Enemy*)parent enemy:(Enemy*)givenEnemy;
@end

@protocol EnemySpawnedDelegate <NSObject>
- (void) preSpawn:(Enemy*)givenEnemy;
@end

// enemy group protocols
@protocol EnemySpawnerDelegate <NSObject>
- (void) initEnemySpawner:(EnemySpawner*)spawner withContextInfo:(NSMutableDictionary*)info;
- (Enemy*) updateEnemySpawner:(EnemySpawner*)spawner elapsed:(NSTimeInterval)elapsed;
- (void) retireEnemies:(EnemySpawner*)spawner elapsed:(NSTimeInterval)elapsed;
- (void) restartEnemySpawner:(EnemySpawner*)spawner;
- (void) activateEnemySpawner:(EnemySpawner*)spawner withTriggerContext:(NSDictionary*)context;
@end

@protocol EnemySpawnerContextDelegate <NSObject>
- (NSDictionary*) spawnerTriggerContext;
- (float) spawnerLayerDistance;
@end

