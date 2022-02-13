//
//  LevelManager.h
//  Curry
//
//

#import <Foundation/Foundation.h>
#import "GameModes.h"

@class LevelConfig;
@class Level;
@class LevelAnimData;
@class EnvData;
@class EffectFactory;
@class LootFactory;
@class AddonFactory;
@class AddonData;
@class SpawnersData;
@interface LevelManager : NSObject 
{
    EnvData* envData;
    NSArray* selectedEnv;
    NSString* selectedEnvname;
    unsigned int selectedLevelIndex;
    float _tourneyGameTime;
    
	NSMutableArray* levelConfigs;
    EffectFactory* effectFactory;
    LootFactory* lootFactory;
    AddonFactory* addonFactory;
    NSMutableDictionary* addonDataReg;
    
	Level* curLevel;
    unsigned int nextLevelIndex;
}
@property (nonatomic,retain) EnvData* envData;
@property (nonatomic,retain) NSArray* selectedEnv;
@property (nonatomic,retain) NSString* selectedEnvname;
@property (nonatomic,assign) float tourneyGameTime;
@property (nonatomic,retain) NSMutableArray* levelConfigs;
@property (nonatomic,retain) EffectFactory* effectFactory;
@property (nonatomic,retain) LootFactory* lootFactory;
@property (nonatomic,retain) AddonFactory* addonFactory;
@property (nonatomic,retain) NSMutableDictionary* addonDataReg;
@property (nonatomic,retain) NSMutableDictionary* spawnersDataReg;
@property (nonatomic,retain) Level* curLevel;
@property (nonatomic,readonly) unsigned int nextLevelIndex;

+ (LevelManager*)getInstance;
+ (void) destroyInstance;

- (void) update:(NSTimeInterval)elapsed;
- (void) startNextLevel;
- (void) shutdownLevel;
- (void) restartLevel;
- (void) restartTriggers;
- (BOOL) hasNextLevel;
- (LevelAnimData*) getCurLevelAnimData;
- (void) selectEnvNamed:(NSString*)name level:(unsigned int)levelIndex;
- (void) initForSelectedEnv;
- (void) shutdownForSelectedEnv;
- (unsigned int) getNumEnv;
- (unsigned int) getNumLevelsForEnv:(NSString*)name;
- (unsigned int) getEnvIndexFromName:(NSString*)name;
- (unsigned int) getGlobalIndexForEnv:(NSString*)envName level:(unsigned int)levelIndex;
- (NSMutableArray*) getEnvNames;
- (NSString*) getCurServiceName;
- (NSString*) getCurRouteName;
- (unsigned int) getSelectedLevelIndex;
- (unsigned int) getCurLevelIndex;      // call this between initForSelectedEnv and shutdownForSelectedEnv to retrieve
                                        // the current level's index

- (void) createAddonDataNamed:(NSString*)name;
- (AddonData*) getAddonDataForName:(NSString*)name;
- (SpawnersData*) getSpawnersDataForName:(NSString*)name;
- (GameMode) gameModeForSelectedEnv;
@end
