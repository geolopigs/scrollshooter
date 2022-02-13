//
//  EnemyFactory.m
//
//

#import "EnemyFactory.h"
#import "Enemy.h"
#import "EnemyProtocol.h"
#import "BoarFighterArchetype.h"
#import "HoverFighter.h"
#import "ScatterBomb.h"
#import "BoarFighterSpawner.h"
#import "EnemySpawner.h"
#import "DuaSeatoArchetype.h"
#import "DuaSeatoSpawner.h"
#import "BoarSolo.h"
#import "GroundCargoSpawner.h"
#import "TurretSingle.h"
#import "TurretDouble.h"
#import "TurretBasic.h"
#import "CargoBoat.h"
#import "CargoShipB.h"
#import "BoarSpeedo.h"
#import "BossArchetype.h"
#import "TurretSpawner.h"
#import "DynamicsSpawner.h"
#import "BoarFighterBasic.h"
#import "LineSpawner.h"
#import "DynLineSpawner.h"
#import "BossSpawner.h"
#import "PlayerMissile.h"
#import "Boomerang.h"
#import "Laser.h"
#import "TurretLaser.h"
#import "Boss2.h"
#import "SubSpawner.h"
#import "WaterMine.h"

@interface EnemyFactory(PrivateMethods)
- (void) createBoarSubL6;
@end

@implementation EnemyFactory
@synthesize archetypeLib;
@synthesize spawnerLib;

#pragma mark -
#pragma mark Singleton

static EnemyFactory* singletonInstance = nil;
+ (EnemyFactory*)getInstance
{
    @synchronized(self)
    {
        if (singletonInstance == nil)
		{
			singletonInstance = [[EnemyFactory alloc] init];
		}
    }
    return singletonInstance;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singletonInstance release];
		singletonInstance = nil;
	}
}

#pragma mark - type definitions
- (void) createBoarSubL6
{
    NSDictionary* animStates = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                    @"BoarSubmarine2Spawn", 
                                                                    @"BoarSubmarine2", 
                                                                    @"BoarSubmarine2Destroyed",
                                                                    nil]
                                                           forKeys:[NSArray arrayWithObjects:
                                                                    @"intro",
                                                                    @"basic",
                                                                    @"destroyed",
                                                                    nil]];
    NSDictionary* effects = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                 @"BoarSubmarineWakes",
                                                                 @"Sub2Explosion",
                                                                 @"BoarSub2Burn",
                                                                 nil]
                                                        forKeys:[NSArray arrayWithObjects:
                                                                 @"cruise",
                                                                 @"destroy",
                                                                 @"critical",
                                                                 nil]];
    Boss2* newType = [[Boss2 alloc] initWithTypeName:@"BoarSubL6" 
                                            sizeName:@"BoarSubmarine2" 
                                    spawnersDataName:@"BoarSubL6_addons"
                                          animStates:animStates
                      ]; 
    newType.effectAddons = effects;
    newType.introSoundName = @"SubEmerging";
    newType.incapSoundName = @"SubmarineExplosion";
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
}

- (void) createSkyIsleL7
{
    NSDictionary* animStates = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                    @"FloatingIsland", 
                                                                    nil]
                                                           forKeys:[NSArray arrayWithObjects:
                                                                    @"basic",
                                                                    nil]];
    NSDictionary* effects = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                 @"SkyIsleL7Burn",
                                                                 @"SkyIsleL7Destroyed",
                                                                 nil]
                                                        forKeys:[NSArray arrayWithObjects:
                                                                 @"critical",
                                                                 @"destroy",
                                                                 nil]];
    Boss2* newType = [[Boss2 alloc] initWithTypeName:@"SkyIsleL7" 
                                            sizeName:@"SkyIsleL7" 
                                    spawnersDataName:@"SkyIsleL7_addons"
                                          animStates:animStates
                      ]; 
    newType.effectAddons = effects;
    newType.soundClipName = @"LargeBlimpHum";
    newType.incapSoundName = @"BlimpExplosion";
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];    
}

- (void) createSkyIsleL10
{
    NSDictionary* animStates = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                    @"FloatingIsland", 
                                                                    nil]
                                                           forKeys:[NSArray arrayWithObjects:
                                                                    @"basic",
                                                                    nil]];
    NSDictionary* effects = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                 @"SkyIsleL10Destroyed",
                                                                 nil]
                                                        forKeys:[NSArray arrayWithObjects:
                                                                 @"destroy",
                                                                 nil]];
    Boss2* newType = [[Boss2 alloc] initWithTypeName:@"SkyIsleL10" 
                                            sizeName:@"SkyIsleL10" 
                                    spawnersDataName:@"SkyIsleL10_addons"
                                          animStates:animStates
                      ]; 
    newType.effectAddons = effects;
    newType.soundClipName = @"LargeBlimpHum";
    newType.incapSoundName = @"BlimpExplosion";
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];    
}

#pragma mark -
#pragma mark factory methods

- (id) init
{
	if((self = [super init]))
	{
		[self initArchetypeLib];
        [self initSpawnerLib];
	}
	return self;
}

- (void) dealloc
{
    self.spawnerLib = nil;
    self.archetypeLib = nil;
	[super dealloc];
}

- (Enemy*) createEnemyFromKey:(NSString *)key
{
	Enemy* newEnemy = nil;
	NSObject<EnemyInitProtocol>* cur = [archetypeLib objectForKey:key];
	if(cur)
	{
		CGPoint origin = CGPointMake(0.0f, 0.0f);
		newEnemy = [[Enemy alloc] initAtPos:origin usingDelegate:cur];
	}
	
	return newEnemy;
}

- (Enemy*) createEnemyFromKey:(NSString *)key AtPos:(CGPoint)givenPos
{
	Enemy* newEnemy = nil;
	NSObject<EnemyInitProtocol>* cur = [archetypeLib objectForKey:key];
	if(cur)
	{
		newEnemy = [[Enemy alloc] initAtPos:givenPos usingDelegate:cur];
	}
	
	return newEnemy;	
}

- (Enemy*) createEnemyFromKey:(NSString *)key AtPos:(CGPoint)givenPos withSpawnerContext:(id)spawnerContext
{
	Enemy* newEnemy = nil;
	NSObject<EnemyInitProtocol>* cur = [archetypeLib objectForKey:key];
	if(cur)
	{
		newEnemy = [[Enemy alloc] initAtPos:givenPos usingDelegate:cur withSpawnerContext:spawnerContext];
	}
	
	return newEnemy;	    
}

- (void) initArchetypeLib
{
	self.archetypeLib = [NSMutableDictionary dictionaryWithCapacity:10];
	
    NSObject<EnemyInitProtocol>* newType = nil;
    
    // BoarFighter
    newType = [[BoarFighterArchetype alloc] init];
    [archetypeLib setObject:newType forKey:@"BoarFighterFixed"];
    [newType release];

    // DuaSeato
    newType = [[DuaSeatoArchetype alloc] init];
    [archetypeLib setObject:newType forKey:@"DuaSeato"];
    [newType release];
    
    // BoarSolo
    newType = [[BoarSolo alloc] init];
    [archetypeLib setObject:newType forKey:@"BoarSoloGun"];
    [newType release];
    
    // TurretSingle
    newType = [[TurretSingle alloc] init];
    [archetypeLib setObject:newType forKey:@"TurretSingle"];
    [newType release];

    // TurretDouble
    newType = [[TurretDouble alloc] init];
    [archetypeLib setObject:newType forKey:@"TurretDouble"];
    [newType release];
    
    // TurretBasic
    newType = [[TurretBasic alloc] init];
    [archetypeLib setObject:newType forKey:@"TurretBasic"];
    [newType release];
    
    // CargoBoat
    newType = [[CargoBoat alloc] init];
    [archetypeLib setObject:newType forKey:@"CargoBoat"];
    [newType release];
    
    // CargoShipB
    newType = [[CargoShipB alloc] init];
    [archetypeLib setObject:newType forKey:@"CargoShipB"];
    [newType release];
    
    // BoarSpeedo
    newType = [[BoarSpeedo alloc] init];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // BoarFighterBasic
    newType = [[BoarFighterBasic alloc] init];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
     
    // HoverFighter
    newType = [[HoverFighter alloc] init];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // ScatterBomb
    newType = [[ScatterBomb alloc] initWithAnimNamed:@"SpinTriBullet" explosionNamed:@"SpinTriBulletGone"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // WaterMine
    newType = [[WaterMine alloc] initWithTypeName:@"WaterMine" animNamed:@"WaterMine" explosionNamed:@"SpinTriBulletGone" spawnAnimNamed:@"WaterMineSpawn"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // PlayerMissile
    newType = [[PlayerMissile alloc] initWithAnimNamed:@"Missile" trailName:@"MissileTrail" typeName:@"PlayerMissile"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // BlueMissile
    newType = [[PlayerMissile alloc] initWithAnimNamed:nil trailName:@"BlueTrail" typeName:@"BlueMissile"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // Boomerang
    newType = [[Boomerang alloc] initWithAnimNamed:@"Boomerang"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // YellowLaser
    newType = [[Laser alloc] initWithAnimNamed:@"YellowLaser" typeName:@"Laser"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // PlayerLaser
    newType = [[Laser alloc] initAsPlayerWeaponWithAnimNamed:@"BlueLaser" typeName:@"PlayerLaser"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // BoarPumpkinBlimp
    newType = [[BossArchetype alloc] initWithTypeName:@"BoarPumpkinBlimp" 
                                             sizeName:@"BoarPumpkinBlimp" 
                                             clipName:@"BoarPumpkinBlimp" 
                                           addonsName:@"BoarPumpkinBlimp_addons" 
                                destructionEffectName:@"BoarPumpkinBlimpBurned" 
                                 destructionAddonName:@"BoarBlimpBurning"
                                        soundClipName:nil
                                        introClipName:nil
                                       spawnAddonName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // BoarBlimp
    newType = [[BossArchetype alloc] initWithTypeName:@"BoarBlimp" sizeName:@"BoarBlimp" clipName:@"BoarBlimp" addonsName:@"BoarBlimp_addons" destructionEffectName:@"BlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // BoarBlimpParked
    newType = [[BossArchetype alloc] initWithTypeName:@"BoarBlimpParked" sizeName:@"BoarBlimp" clipName:@"BoarBlimp" addonsName:@"BoarBlimpParked_addons" destructionEffectName:@"BlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // BoarBlimpTSParked
    newType = [[BossArchetype alloc] initWithTypeName:@"BoarBlimpTSParked" sizeName:@"BoarBlimp" clipName:@"BoarBlimp" addonsName:@"BoarBlimpTSParked_addons" destructionEffectName:@"BlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // MidBlimp
    newType = [[BossArchetype alloc] initWithTypeName:@"MidBlimp" sizeName:@"MidBlimp" clipName:@"MidBlimp" addonsName:@"MidBlimp_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // MidBlimp0
    newType = [[BossArchetype alloc] initWithTypeName:@"MidBlimp0" sizeName:@"MidBlimp" clipName:@"MidBlimp" addonsName:@"MidBlimp0_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // MidBlimpParked
    newType = [[BossArchetype alloc] initWithTypeName:@"MidBlimpParked" sizeName:@"MidBlimp" clipName:@"MidBlimp" addonsName:@"MidBlimpParked_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // MidBlimpBoar
    newType = [[BossArchetype alloc] initWithTypeName:@"MidBlimpBoar" sizeName:@"MidBlimpBoar" clipName:@"MidBlimp" addonsName:@"MidBlimpBoar_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // MidBlimpBoar3
    newType = [[BossArchetype alloc] initWithTypeName:@"MidBlimpBoar3" sizeName:@"MidBlimpBoar" clipName:@"MidBlimp" addonsName:@"MidBlimpBoar3_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // MidTurretBlimp
    newType = [[BossArchetype alloc] initWithTypeName:@"MidTurretBlimp" sizeName:@"MidTurretBlimp" clipName:@"MidBlimp" addonsName:@"MidTurretBlimp_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // MidBlimpBSD
    newType = [[BossArchetype alloc] initWithTypeName:@"MidBlimpBSD" sizeName:@"MidTurretBlimp" clipName:@"MidBlimp" addonsName:@"MidBlimpBSD_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // MidBlimpLeftTurrets
    newType = [[BossArchetype alloc] initWithTypeName:@"MidBlimpLeftTurrets" sizeName:@"MidTurretBlimp" clipName:@"MidBlimp" addonsName:@"MidBlimpLeftTurrets_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // MidBlimpRightTurrets
    newType = [[BossArchetype alloc] initWithTypeName:@"MidBlimpRightTurrets" sizeName:@"MidTurretBlimp" clipName:@"MidBlimp" addonsName:@"MidBlimpRightTurrets_addons" destructionEffectName:@"MidBlimpBurned" soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LargeBlimpLeft
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimpLeft" sizeName:@"LargeBlimpLeft" clipName:@"LargeBlimp" addonsName:@"LargeBlimpLeft_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LargeBlimpRight
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimpRight" sizeName:@"LargeBlimpRight" clipName:@"LargeBlimp" addonsName:@"LargeBlimpRight_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LargeBlimpTurretLeft
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimpTurretLeft" sizeName:@"LargeBlimpTurretLeft" clipName:@"LargeBlimp" addonsName:@"LargeBlimpTurretLeft_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LargeBlimpTurretRight
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimpTurretRight" sizeName:@"LargeBlimpTurretRight" clipName:@"LargeBlimp" addonsName:@"LargeBlimpTurretRight_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LargeBlimp
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimp" sizeName:@"LargeBlimp" clipName:@"LargeBlimp" addonsName:@"LargeBlimp_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LargeBlimpParked
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimpParked" sizeName:@"LargeBlimp" clipName:@"LargeBlimp" addonsName:@"LargeBlimpParked_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LargeBlimpTSParked
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimpTSParked" sizeName:@"LargeBlimp" clipName:@"LargeBlimp" addonsName:@"LargeBlimpTSParked_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // LargeBlimpTurrets
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimpTurrets" sizeName:@"LargeBlimpTurrets" clipName:@"LargeBlimp" addonsName:@"LargeBlimpTurrets_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LargeBlimpBSD
    newType = [[BossArchetype alloc] initWithTypeName:@"LargeBlimpBSD" sizeName:@"LargeBlimpTurrets" clipName:@"LargeBlimp" addonsName:@"LargeBlimpBSD_addons" destructionEffectName:@"LargeBlimpBurned" soundClipName:@"LargeBlimpHum"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
    
    // LandingPad
    newType = [[BossArchetype alloc] initWithTypeName:@"LandingPad" sizeName:@"LandingPad" clipName:@"LandingPad" addonsName:@"LandingPad_addons" destructionEffectName:nil soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // FloatingIsland
    newType = [[BossArchetype alloc] initWithTypeName:@"FloatingIsland" sizeName:@"FloatingIsland" clipName:@"FloatingIsland" addonsName:@"FloatingIslandBSD_addons" destructionEffectName:nil soundClipName:nil];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // BoarSubmarine
    newType = [[BossArchetype alloc] initWithTypeName:@"BoarSubmarine" 
                                             sizeName:@"BoarSubmarine" 
                                             clipName:@"BoarSubmarine" 
                                           addonsName:@"BoarSubBSD_addons" 
                                destructionEffectName:@"BoarPumpkinBlimpBurned"
                                 destructionAddonName:nil 
                                        soundClipName:nil 
                                        introClipName:@"BoarSubmarineSpawn"
                                       spawnAddonName:@"TurretOpen"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // BoarSubmarine2
    newType = [[BossArchetype alloc] initWithTypeName:@"BoarSubmarine2" 
                                             sizeName:@"BoarSubmarine2" 
                                             clipName:@"BoarSubmarine2" 
                                           addonsName:@"BoarSub2BSD_addons" 
                                destructionEffectName:@"BoarPumpkinBlimpBurned"
                                 destructionAddonName:nil 
                                        soundClipName:nil 
                                        introClipName:@"BoarSubmarine2Spawn"
                                       spawnAddonName:@"TurretOpen"];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];

    // BoarSubL2
    NSDictionary* BoarSubL2AnimStates = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                             @"BoarSubmarineSpawn", 
                                                                             @"BoarSubmarine", 
                                                                             @"BoarSubmarineOpenDoor",
                                                                             @"BoarSubmarineCloseDoor",
                                                                             @"BoarSubmarineDestroyed",
                                                                             nil]
                                                                    forKeys:[NSArray arrayWithObjects:
                                                                             @"intro",
                                                                             @"basic",
                                                                             @"opendoor",
                                                                             @"closedoor",
                                                                             @"destroyed",
                                                                             nil]];
    NSDictionary* boarSubL2Effects = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                          @"BoarSubmarineWakes",
                                                                          @"SubExplosion",
                                                                          @"BoarSubBurn",
                                                                          nil]
                                                                 forKeys:[NSArray arrayWithObjects:
                                                                          @"cruise",
                                                                          @"destroy",
                                                                          @"critical",
                                                                          nil]];
    Boss2* boarSubL2Type = [[Boss2 alloc] initWithTypeName:@"BoarSubL2" 
                                                  sizeName:@"BoarSubmarine" 
                                          spawnersDataName:@"BoarSubL2_addons"
                                                animStates:BoarSubL2AnimStates
                            ]; 
    boarSubL2Type.effectAddons = boarSubL2Effects;
    boarSubL2Type.introSoundName = @"SubEmerging";
    boarSubL2Type.incapSoundName = @"SubmarineExplosion";
    [archetypeLib setObject:boarSubL2Type forKey:[boarSubL2Type getEnemyTypeName]];
    [boarSubL2Type release];

    
    // BoarSubL6
    [self createBoarSubL6];
    
    // SkyIsleL7
    [self createSkyIsleL7];
    
    // SkyIsleL10
    [self createSkyIsleL10];
    
    
    // TurretLaser
    NSDictionary* turretLaserAnimStates = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                               @"TurretLaserIdle",
                                                                               @"TurretLaserActive",
                                                                               @"TurretLaserDestroyed",
                                                                               nil]
                                                                      forKeys:[NSArray arrayWithObjects:
                                                                               TLANIMKEY_IDLE,
                                                                               TLANIMKEY_FIRE,
                                                                               TLANIMKEY_DESTROYED,
                                                                               nil]];
    newType = [[TurretLaser alloc] initWithTypeName:@"TurretLaser" sizeName:@"TurretLaser" animStates:turretLaserAnimStates];
    [archetypeLib setObject:newType forKey:[newType getEnemyTypeName]];
    [newType release];
}

- (void) initSpawnerLib
{
    self.spawnerLib = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSObject<EnemySpawnerDelegate>* newType = nil;
    
    // BoarFighter
    newType = [[BoarFighterSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"BoarFighterSpawner"];
    [newType release];

    // DuaSeato
    newType = [[DuaSeatoSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"DuaSeatoSpawner"];
    [newType release];
    
    // GroundCargoSpawner
    newType = [[GroundCargoSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"ca_Spawner"];
    [newType release];
    
    // TurretSpawner
    newType = [[TurretSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"gr_Spawner"];
    [newType release];
    
    // DynamicsSpawner
    newType = [[DynamicsSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"dy_Spawner"];
    [newType release];
    
    // LineSpawner
    newType = [[LineSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"LineSpawner"];
    [newType release];
    
    // BossSpawner
    newType = [[BossSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"BossSpawner"];
    [newType release];

    // DynLineSpawner
    newType = [[DynLineSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"DynLineSpawner"];
    [newType release];
    
    // SubSpawner (spawners that are attached to an Enemy)
    newType = [[SubSpawner alloc] init];
    [spawnerLib setObject:newType forKey:@"SubSpawner"];
    [newType release];
}

- (EnemySpawner*) createEnemySpawnerFromKey:(NSString *)key
{
    EnemySpawner* newSpawner = nil;
    NSObject<EnemySpawnerDelegate>* cur = [spawnerLib objectForKey:key];
    if(cur)
    {
        newSpawner = [[EnemySpawner alloc] initWithDelegate:cur];
    }
    return newSpawner;
}

- (EnemySpawner*) createEnemySpawnerFromKey:(NSString *)key withTriggerName:(NSString*)triggerName
{
    EnemySpawner* newSpawner = nil;
    NSObject<EnemySpawnerDelegate>* cur = [spawnerLib objectForKey:key];
    if(cur)
    {
        NSMutableDictionary* contextInfo = [NSMutableDictionary dictionary];
        [contextInfo setObject:triggerName forKey:@"triggerName"];
        newSpawner = [[EnemySpawner alloc] initWithDelegate:cur contextInfo:contextInfo];
    }
    return newSpawner;
}

- (EnemySpawner*) createGunSpawnerFromKey:(NSString*)key 
                       withPositionsArray:(NSArray*)positionsArray 
                               atDistance:(float)dist 
                      renderBucketShadows:(unsigned int)bucketShadows
                             renderBucket:(unsigned int)bucket
                       renderBucketAddons:(unsigned int)bucketAddons
                            forObjectType:(NSString *)objectName
                              triggerName:(NSString *)triggerName
{
    EnemySpawner* newSpawner = nil;
    NSObject<EnemySpawnerDelegate>* cur = [spawnerLib objectForKey:key];
    if(cur)
    {
        // spawner init takes in a Dictionary as its context init info
        NSMutableDictionary* contextInfo = [NSMutableDictionary dictionary];
        [contextInfo setObject:positionsArray forKey:@"positionsArray"];

        [contextInfo setObject:[NSNumber numberWithUnsignedInt:bucketShadows] forKey:@"bucketShadows"];
        [contextInfo setObject:[NSNumber numberWithUnsignedInt:bucket] forKey:@"bucket"];
        [contextInfo setObject:[NSNumber numberWithUnsignedInt:bucketAddons] forKey:@"bucketAddons"];
        
        [contextInfo setObject:[NSNumber numberWithFloat:dist] forKey:@"layerDistance"];
        [contextInfo setObject:objectName forKey:@"objectType"];
        [contextInfo setObject:triggerName forKey:@"triggerName"];

        newSpawner = [[EnemySpawner alloc] initWithDelegate:cur contextInfo:contextInfo];
    }
    return newSpawner;
}


@end
