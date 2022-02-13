//
//  EnemyFactory.h
//
//

#import <Foundation/Foundation.h>
@class Enemy;
@class EnemySpawner;
@interface EnemyFactory : NSObject 
{
	NSMutableDictionary* archetypeLib;
    NSMutableDictionary* spawnerLib;
}
@property (nonatomic,retain) NSMutableDictionary* archetypeLib;
@property (nonatomic,retain) NSMutableDictionary* spawnerLib;

+ (EnemyFactory*)getInstance;
+ (void) destroyInstance;

- (void) initArchetypeLib;
- (void) initSpawnerLib;
- (Enemy*) createEnemyFromKey:(NSString*)key;
- (Enemy*) createEnemyFromKey:(NSString*)key AtPos:(CGPoint)givenPos;
- (Enemy*) createEnemyFromKey:(NSString *)key AtPos:(CGPoint)givenPos withSpawnerContext:(id)spawnerContext;
- (EnemySpawner*) createEnemySpawnerFromKey:(NSString*)key;
- (EnemySpawner*) createEnemySpawnerFromKey:(NSString *)key withTriggerName:(NSString*)triggerName;
- (EnemySpawner*) createGunSpawnerFromKey:(NSString*)key 
                       withPositionsArray:(NSArray*)positionsArray 
                               atDistance:(float)dist 
                      renderBucketShadows:(unsigned int)bucketShadows
                             renderBucket:(unsigned int)bucket
                       renderBucketAddons:(unsigned int)bucketAddons
                            forObjectType:(NSString *)objectName
                              triggerName:(NSString*)triggerName;
@end

