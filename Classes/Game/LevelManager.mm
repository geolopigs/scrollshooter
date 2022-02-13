//
//  LevelManager.mm
//  Curry
//
//

#import "LevelManager.h"
#import "LevelConfig.h"
#import "Level.h"
#import "LevelAnimData.h"
#import "EnvData.h"
#import "EffectFactory.h"
#import "LootFactory.h"
#import "AddonFactory.h"
#import "AddonData.h"
#import "SpawnersData.h"
#import "StatsManager.h"

@interface LevelManager (LevelManagerPrivate)
- (void) initConfigs;
- (void) shutdownConfigs;
- (void) resetLevelIndex:(unsigned int)index;
- (void) initSpawnersDataReg;
- (void) shutdownSpawnersDataReg;
- (void) loadSpawnersDataNamed:(NSString*)name;
- (void) initAddonData;
- (void) shutdownAddonData;
@end

@implementation LevelManager
@synthesize envData;
@synthesize selectedEnv;
@synthesize selectedEnvname;
@synthesize tourneyGameTime;
@synthesize levelConfigs;
@synthesize curLevel;
@synthesize effectFactory;
@synthesize lootFactory;
@synthesize addonFactory;
@synthesize addonDataReg;
@synthesize spawnersDataReg = _spawnersDataReg;
@synthesize nextLevelIndex;

#pragma mark -
#pragma mark singleton
static LevelManager* singleton = nil;

+ (LevelManager*)getInstance
{
    @synchronized(self)
    {
        if (singleton == nil)
		{
			singleton = [[LevelManager alloc] init];
		}
    }
    return singleton;
}

+ (void) destroyInstance
{
    @synchronized(self)
    {
		[singleton release];
		singleton = nil;
	}	
}


#pragma mark -
#pragma mark Instance Methods

- (id) init
{
	if((self = [super init]))
	{
		[self initConfigs];
        [self initAddonData];
        [self initSpawnersDataReg];
        self.selectedEnv = nil;
        self.selectedEnvname = nil;
        _tourneyGameTime = 120.0f;
        nextLevelIndex = 0;
		curLevel = nil;
        self.effectFactory = nil;
        self.lootFactory = nil;
        self.addonFactory = nil;
	}
	return self;
}

- (void) dealloc
{
    self.addonFactory = nil;
    self.lootFactory = nil;
    self.effectFactory = nil;
    self.selectedEnvname = nil;
    self.selectedEnv = nil;
    [self shutdownSpawnersDataReg];
    [self shutdownAddonData];
	[self shutdownConfigs];
	assert(nil == curLevel);
	[super dealloc];
}

- (void) update:(NSTimeInterval)elapsed
{
	
}

- (void) startNextLevel
{
    assert([levelConfigs count] > nextLevelIndex);
	assert(nil == curLevel);
	curLevel = [[Level alloc] initWithConfig:[levelConfigs objectAtIndex:nextLevelIndex]];

    // setup level specific factories
    effectFactory = [[EffectFactory alloc] initWithLevelAnimData:[curLevel animData]];
    lootFactory = [[LootFactory alloc] initWithLevelAnimData:[curLevel animData]];
    addonFactory = [[AddonFactory alloc] initWithLevelAnimData:[curLevel animData]];
    
    // prep StatsManager for this level
    [[StatsManager getInstance] setupForEnvNamed:selectedEnvname level:nextLevelIndex];
    
    // prep next level's index
    ++nextLevelIndex;

    // TODO: either group levels into env, or remove this altogether; will decide in later releases
    // for now, we let the player go back to level 1 after they finish the last level
    if([levelConfigs count] <= nextLevelIndex)
    {
        nextLevelIndex = 0;
    }
}

- (void) shutdownLevel
{
    self.addonFactory = nil;
    self.lootFactory = nil;
    self.effectFactory = nil;
    self.curLevel = nil;
}

- (void) restartLevel
{
    [curLevel restartLevel];
}

- (void) restartTriggers
{
    [curLevel.gameCamera restartTriggers];
}

- (BOOL) hasNextLevel
{
    /*
    BOOL hasNextLevel = NO;
    if([levelConfigs count] > nextLevelIndex)
    {
        hasNextLevel = YES;
    }
     */
    
    // TODO: either group levels into env, or remove this altogether; will decide in later releases
    // for now, we let the player go back to level 1 after they finish the last level
    BOOL hasNextLevel = YES;
    return hasNextLevel;
}

- (LevelAnimData*) getCurLevelAnimData
{
    return [curLevel animData];
}

- (void) selectEnvNamed:(NSString *)name level:(unsigned int)levelIndex
{
    self.selectedEnv = [envData getLevelsArrayForEnvNamed:name];
    self.selectedEnvname = name;
    
    if(levelIndex < [selectedEnv count])
    {
        selectedLevelIndex = levelIndex;
    }
    else
    {
        selectedLevelIndex = 0;
    }
}

- (void) initForSelectedEnv
{
    [self resetLevelIndex:selectedLevelIndex];
    for(EnvLevelData* curEnvLevel in selectedEnv)
    {
        LevelConfig* newLevel = [[LevelConfig alloc] initFromEnvLevelData:curEnvLevel];
        [levelConfigs addObject:newLevel];
        [newLevel release];
    }
}

- (void) shutdownForSelectedEnv
{
    [levelConfigs removeAllObjects];
    [self resetLevelIndex:0];
}

- (unsigned int) getNumEnv
{
    unsigned int result = [[envData envNames] count];
    return result;
}

- (unsigned int) getEnvIndexFromName:(NSString *)name
{
    unsigned int result = [self getNumEnv];
    NSUInteger index = [[envData envNames] indexOfObject:name];
    if(index != NSNotFound)
    {
        result = index;
    }
    return result;
}

- (unsigned int) getNumLevelsForEnv:(NSString *)name
{
    unsigned int num = 0;
    NSArray* array = [envData getLevelsArrayForEnvNamed:name];
    if(array)
    {
        num = [array count];
    }
    return num;
}

- (unsigned int) getGlobalIndexForEnv:(NSString*)envName level:(unsigned int)levelIndex
{
    unsigned int result = 0;
    unsigned int envIndex = [self getEnvIndexFromName:envName];
    assert(envIndex < [self getNumEnv]);
    assert(levelIndex < [self getNumLevelsForEnv:envName]);
    
    // accumulate num levels in all preceeding env
    unsigned int curEnv = 0;
    while(curEnv < envIndex)
    {
        NSString* curEnvName = [[self getEnvNames] objectAtIndex:curEnv];
        result += [self getNumLevelsForEnv:curEnvName];
        ++curEnv;
    }
    
    // finally add current level index to accumulated result
    result += levelIndex;
    
    return result;
}


- (NSMutableArray*) getEnvNames
{
    return [envData envNames];
}

- (AddonData*) getAddonDataForName:(NSString *)name
{
    AddonData* result = [addonDataReg objectForKey:name];
    return result;
}

- (SpawnersData*) getSpawnersDataForName:(NSString *)name
{
    SpawnersData* result = [_spawnersDataReg objectForKey:name];
    return result;
}

- (NSString*) getCurServiceName
{
    NSString* result = nil;
    NSArray* levelsArray = [envData getLevelsArrayForEnvNamed:selectedEnvname];
    unsigned int curIndex = nextLevelIndex - 1;
    
    // TODO: decide on whether we continue to let player loop back to level 1 or group levels in some other way in later releases;
    // for now, nextLevelIndex loops back to 0 when player has reached the final level
    if(0 == nextLevelIndex)
    {
        curIndex = [levelsArray count] - 1;
    }
    if(curIndex < [levelsArray count])
    {
        EnvLevelData* cur = [levelsArray objectAtIndex:curIndex];
        result = [cur serviceName];
    }
    return result;
}

- (NSString*) getCurRouteName
{
    NSString* result = nil;
    NSArray* levelsArray = [envData getLevelsArrayForEnvNamed:selectedEnvname];
    unsigned int curIndex = nextLevelIndex - 1;
    // TODO: decide on whether we continue to let player loop back to level 1 or group levels in some other way in later releases;
    // for now, nextLevelIndex loops back to 0 when player has reached the final level
    if(0 == nextLevelIndex)
    {
        curIndex = [levelsArray count] - 1;
    }
    if(curIndex < [levelsArray count])
    {
        EnvLevelData* cur = [levelsArray objectAtIndex:curIndex];
        result = [cur routeName];
    }
    return result;
}

- (unsigned int) getSelectedLevelIndex
{
    return selectedLevelIndex;
}

- (unsigned int) getCurLevelIndex
{
    unsigned int result = nextLevelIndex;
    if(0 < result)
    {
        result -= 1;
    }
    else 
    {
        result = [levelConfigs count] - 1;
    }
    return result;
}

- (GameMode) gameModeForSelectedEnv
{
    GameMode result = GAMEMODE_CAMPAIGN;
    if([self selectedEnvname])
    {
        result = [[[LevelManager getInstance] envData] getGameModeForEnvNamed:[self selectedEnvname]];
    }
    return result;
}

#pragma mark -
#pragma mark Private Methods
- (void) initConfigs
{
    self.envData = [[EnvData alloc] initFromFilename:@"PogEnv"];
    self.levelConfigs = [NSMutableArray array];
    
}

- (void) shutdownConfigs;
{
    self.levelConfigs = nil;
    self.envData = nil;
}

- (void) resetLevelIndex:(unsigned int)index
{
    assert(index < [selectedEnv count]);
    nextLevelIndex = index;
}

- (void) createAddonDataNamed:(NSString*)name
{
    AddonData* newData = [[AddonData alloc] initFromFilename:name];
    [addonDataReg setObject:newData forKey:name];
    [newData release];    
}


- (void) initAddonData
{
    self.addonDataReg = [NSMutableDictionary dictionary];
    [self createAddonDataNamed:@"CargoBoatBoar_addons"];
    [self createAddonDataNamed:@"CargoShipB_addons"];
    [self createAddonDataNamed:@"BoarPumpkinBlimp_addons"]; 
    [self createAddonDataNamed:@"BoarBlimp_addons"];
    [self createAddonDataNamed:@"BoarBlimpParked_addons"];
    [self createAddonDataNamed:@"BoarBlimpTSParked_addons"];
    [self createAddonDataNamed:@"MidBlimp_addons"];
    [self createAddonDataNamed:@"MidBlimp0_addons"];
    [self createAddonDataNamed:@"MidBlimpParked_addons"];
    [self createAddonDataNamed:@"MidBlimpBoar_addons"];
    [self createAddonDataNamed:@"MidBlimpBoar3_addons"];
    [self createAddonDataNamed:@"MidTurretBlimp_addons"];
    [self createAddonDataNamed:@"MidBlimpBSD_addons"];
    [self createAddonDataNamed:@"MidBlimpLeftTurrets_addons"];
    [self createAddonDataNamed:@"MidBlimpRightTurrets_addons"];
    [self createAddonDataNamed:@"LargeBlimpLeft_addons"];
    [self createAddonDataNamed:@"LargeBlimpRight_addons"];
    [self createAddonDataNamed:@"LargeBlimpTurretLeft_addons"];
    [self createAddonDataNamed:@"LargeBlimpTurretRight_addons"];
    [self createAddonDataNamed:@"LargeBlimp_addons"];
    [self createAddonDataNamed:@"LargeBlimpParked_addons"];
    [self createAddonDataNamed:@"LargeBlimpTSParked_addons"];
    [self createAddonDataNamed:@"LargeBlimpTurrets_addons"];
    [self createAddonDataNamed:@"LargeBlimpBSD_addons"];
    [self createAddonDataNamed:@"LandingPad_addons"];
    [self createAddonDataNamed:@"FloatingIslandBSD_addons"];
    [self createAddonDataNamed:@"BoarSubBSD_addons"];
    [self createAddonDataNamed:@"BoarSubL2_addons"];
    [self createAddonDataNamed:@"BoarSubL6_addons"];
    [self createAddonDataNamed:@"BoarSub2BSD_addons"];
}

- (void) shutdownAddonData
{
    self.addonDataReg = nil;
}

- (void) loadSpawnersDataNamed:(NSString*)name
{
    SpawnersData* newData = [[SpawnersData alloc] initFromFilename:name];
    [_spawnersDataReg setObject:newData forKey:name];
    [newData release];
}

- (void) initSpawnersDataReg
{
    self.spawnersDataReg = [NSMutableDictionary dictionary];
    [self loadSpawnersDataNamed:@"BoarSubL2_addons"];
    [self loadSpawnersDataNamed:@"BoarSubL6_addons"];
    [self loadSpawnersDataNamed:@"SkyIsleL7_addons"];
    [self loadSpawnersDataNamed:@"SkyIsleL10_addons"];
}

- (void) shutdownSpawnersDataReg
{
    self.spawnersDataReg = nil;
}

@end
