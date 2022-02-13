//
//  GameManager.mm
//  Curry
//

#import "GameManager.h"
#import "Player.h"
#import "PlayerFactory.h"
#import "EnemyFactory.h"
#import "EffectFactory.h"
#import "Enemy.h"
#import "DynamicManager.h"
#import "AnimProcessor.h"
#import "RenderBucketsManager.h"
#import "PanController.h"
#import "LevelManager.h"
#import "Level.h"
#import "TopCam.h"
#import "CamPath.h"
#import "FiringPath.h"
#import "CollisionManager.h"
#import "EnemySpawner.h"
#import "CargoManager.h"
#import "StatsManager.h"
#import "PickupSpec.h"
#import "PlayerStatus.h"
#import "SoundManager.h"
#import "Loot.h"
#import "LootFactory.h"
#import "CamPath.h"
#import "AchievementsManager.h"
#import "AchievementsData.h"
#import "AchievementRegEntry.h"
#import "PlayerInventoryIds.h"
#import "PlayerInventory.h"
#import "ProductManager.h"
#import "TourneyManager.h"
#include "MathUtils.h"

#if defined(DEBUG)
#import "DebugOptions.h"
#endif

typedef enum
{
    TOURNEY_ATTACK_INVALID = 0,
    TOURNEY_ATTACK_DARKCLOUDS,
    TOURNEY_ATTACK_FIREWORKS,
    TOURNEY_ATTACK_MUTE
} TourneyAttack;

NSString* const kNextpeerTourneyDidStart = @"NextpeerTourneyDidStart";
NSString* const kNextpeerTourneyDidEnd = @"NextpeerTourneyDidEnd";
NSString* const kNextpeerDashboardDidExit = @"NextpeerDashboardDidExit";
NSString* const kNextpeerDashboardWillAppear = @"NextpeerDashboardWillAppear";

const unsigned int NUM_CARGOS_PER_MULT = 5;

@interface GameManager (PrivateMethods)
- (void) resetKillAllBullets;
- (void) processKillAllBullets:(NSTimeInterval)elapsed;
- (void) queueStandardUpgrades;
- (void) clearAllSpawners;
- (void) clearAchievementsNotifications;
- (void) updateAchievementsSummary:(NSTimeInterval)elapsed;
- (void) tourneyResetAttackCounts;
- (void) tourneyProcessAttacks:(NSTimeInterval)elapsed;
- (void) tourneyShowDarkClouds;
- (void) tourneyShowFireworks;
@end

@implementation GameManager

@synthesize gameMode = _gameMode;
@synthesize flyerId = _flyerId;
@synthesize flyerType = _flyerType;
@synthesize playerStatus;
@synthesize playerShip;
@synthesize curLevel;
@synthesize panController;
@synthesize enemySpawners;
@synthesize spawnerTrash;
@synthesize spawnerTrashTrash;
@synthesize spawnerRegistry;
@synthesize hudDelegate;
@synthesize scrollCamBlockers;
@synthesize pickupsQueue;
@synthesize basicPickups;
@synthesize triggerEnemies;
@synthesize valueSortedEnemies;
@synthesize delayedWeapons;
@synthesize delayedWeaponsTrash;
@synthesize isKillBulletsActivated;
@synthesize killBulletsTimer;
@synthesize hasUsedLifeSaver = _hasUsedLifeSaver;
@synthesize achievementsCompleted = _achievementsCompleted;
@synthesize achievementsDisplayed = _achievementsDisplayed;
@synthesize curAchievementTimer = _curAchievementTimer;
@synthesize gameTimeRemaining = _gameTimeRemaining;
@synthesize hasTourneyEnded = _hasTourneyEnded;
@synthesize lastAttackerName = _lastAttackerName;
@synthesize lastAttackerIcon = _lastAttackerIcon;

- (NSString*) flyerType
{
    NSString* result = [[ProductManager getInstance] getFlyerTypeNameForProductId:[self flyerId]];
    return result;
}

#pragma mark -
#pragma mark Singleton
static GameManager* singletonGameManager = nil;
+ (GameManager*) getInstance
{
	@synchronized(self)
	{
		if (!singletonGameManager)
		{
			singletonGameManager = [[[GameManager alloc] init] retain];
		}
	}
	return singletonGameManager;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singletonGameManager release];
		singletonGameManager = nil;
	}
}

#pragma mark -
#pragma mark Instance Methods

- (id) init
{
	if((self = [super init]))
	{
        self.gameMode = GAMEMODE_FRONTEND;
        self.flyerId = (NSString*) FLYER_ID_POGLIDER;
        self.playerStatus = nil;
        self.playerShip = nil;
        self.panController = nil;
        panControllerEnabled = YES;
        self.enemySpawners = nil;
        self.spawnerRegistry = nil;
        self.hudDelegate = nil;

        // blocking scroll cam
        self.scrollCamBlockers = [NSMutableArray array];
        scrollCamBlocked = NO;

        // pick-ups policy
        self.pickupsQueue = [NSMutableArray array];
        self.basicPickups = [NSMutableArray array];
        pickupsRationed = NO;
        
        // trigger receiving enemies
        self.triggerEnemies = [NSMutableDictionary dictionary];
        
        self.valueSortedEnemies = [NSMutableArray array];
        
        // special weapons
        self.delayedWeapons = [NSMutableArray array];
        self.delayedWeaponsTrash = [NSMutableArray array];
        
        // power weapons
        self.isKillBulletsActivated = NO;
        self.killBulletsTimer = 0.0f;
        _hasUsedLifeSaver = NO;
        
        // swipe tracking stats
        numOpposingSwipes = 0;
        prevSwipeVec = CGPointMake(1.0f, 0.0f);
        prevSwipeTranslate = CGPointMake(0.0f, 0.0f);
        isShowingSwipeTip = NO;
        
        // UI
        _shouldShowRouteCompleted = NO;
        
        // setup CollisionManager for this game session
        [[CollisionManager getInstance] newCollisionSetWithName:@"Player"];
        [[CollisionManager getInstance] newCollisionSetWithName:@"Enemies"];
        [[CollisionManager getInstance] newCollisionSetWithName:@"EnemiesNonCollidable"];
        [[CollisionManager getInstance] newCollisionSetWithName:@"EnemyFire"];
        [[CollisionManager getInstance] newCollisionSetWithName:@"PlayerFire"];
        [[CollisionManager getInstance] newCollisionSetWithName:@"Loots"];
        [[CollisionManager getInstance] addDetectionPairForSet:@"Player" against:@"Enemies"];
        [[CollisionManager getInstance] addDetectionPairForSet:@"Player" against:@"EnemyFire"];
        [[CollisionManager getInstance] addDetectionPairForSet:@"Player" against:@"Loots"];
        [[CollisionManager getInstance] addDetectionPairForSet:@"Enemies" against:@"PlayerFire"];
        [[CollisionManager getInstance] addDetectionPairForSet:@"EnemiesNonCollidable" against:@"PlayerFire"];
        
        // achievements notifications
        self.achievementsCompleted = [NSMutableArray array];
        self.achievementsDisplayed = [NSMutableArray array];
        _curAchievementTimer = 0.0f;
        
        // timebased params
        _gameTimeRemaining = 120.0f;
        _gameTimeRemainingPrev = _gameTimeRemaining;
        _hasTourneyEnded = NO;
        _tourneyUtilLookup = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                  [NSNumber numberWithInt:TOURNEY_ATTACK_DARKCLOUDS],
                                                                  [NSNumber numberWithInt:TOURNEY_ATTACK_FIREWORKS],
                                                                  [NSNumber numberWithInt:TOURNEY_ATTACK_MUTE], nil] 
                                                         forKeys:[NSArray arrayWithObjects:
                                                                  MULTIPLAYERUTIL_ID_DARKCLOUDS,
                                                                  MULTIPLAYERUTIL_ID_FIREWORKS,
                                                                  MULTIPLAYERUTIL_ID_MUTE, nil]] retain];
        _lastAttackerName = nil;
        _lastAttackerIcon = nil;
        _tourneyFireworksSpawnTimers = [[NSMutableArray array] retain];
        _tourneyFireworksEffectNames = [[NSArray arrayWithObjects:@"MissileHit", @"Explosion", nil] retain];
        [self tourneyResetAttackCounts];
        
	}
	return self;
}

- (void) dealloc
{
    [_tourneyFireworksEffectNames release];
    [_tourneyFireworksSpawnTimers release];
    self.lastAttackerIcon = nil;
    self.lastAttackerName = nil;
    [_tourneyUtilLookup release];
    self.achievementsDisplayed = nil;
    self.achievementsCompleted = nil;
    self.delayedWeaponsTrash = nil;
    self.delayedWeapons = nil;
    self.valueSortedEnemies = nil;
    self.triggerEnemies = nil;
    self.basicPickups = nil;
    self.pickupsQueue = nil;
    self.scrollCamBlockers = nil;
    self.hudDelegate = nil;
    self.spawnerRegistry = nil;
    self.enemySpawners = nil;
    self.panController = nil;
    self.playerShip = nil;
    self.playerStatus = nil;
    self.flyerId = nil;
	[super dealloc];
}

- (void) newGame
{
    // clear out playerStatus
    self.playerStatus = nil;
    _hasUsedLifeSaver = NO;
    
    // swipe tracking stats
    numOpposingSwipes = 0;
    prevSwipeVec = CGPointMake(1.0f, 0.0f);
    isShowingSwipeTip = NO;

    // level
    [[LevelManager getInstance] initForSelectedEnv];
    
    // stats
    [[StatsManager getInstance] setupForNewGame];
    
    // reset continue and route count in Achievements
    [[AchievementsManager getInstance] resetContinueCount];
    [[AchievementsManager getInstance] resetRouteCount];
    
    [self gotoNextLevel];
}

- (void) exitGame
{
    // report scores to Game Center
    [[StatsManager getInstance] reportScoresToGameCenter];
    [[AchievementsManager getInstance] reportAchievementsToGameCenter];
    
    // clear out playerStatus
    self.playerStatus = nil;

    // deplete player's single-use only when player has finished a level
    [[PlayerInventory getInstance] clearNumBombs];
    [[PlayerInventory getInstance] clearCargoMagnet];
    if(GAMEMODE_TIMEBASED == [self gameMode])
    {
        [[PlayerInventory getInstance] clearAllMultiplayerUtils];
    }

    // this function is called after level has shutdown;
    // so, only needs to clean up the selected Env
    [[LevelManager getInstance] shutdownForSelectedEnv];
    
    // release hud delegate
    self.hudDelegate = nil;
    
    // clear out pickups policy
    [pickupsQueue removeAllObjects];
    [basicPickups removeAllObjects];
    pickupsRationed = NO;
    
    // clear out scrollcam blockers
    scrollCamBlocked = NO;
    [self.scrollCamBlockers removeAllObjects];
    
    // reset render buckets (clear out all commands)
    [[RenderBucketsManager getInstance] resetFromConfig];
}

- (void) gotoNextLevel
{
    // should not have any scrollcam blockers dangling around at this point
    assert(0 == [scrollCamBlockers count]);
    
    // reset per-level sound manager flags
    [[SoundManager getInstance] allowPlayClip];
    
    // setup enemy spawner lib
    self.enemySpawners = [NSMutableArray array];  
    self.spawnerTrash = [NSMutableArray array];
    self.spawnerTrashTrash = [NSMutableArray array];
    self.spawnerRegistry = [NSMutableDictionary dictionary];
    
    // reset renderbuckets
    [[RenderBucketsManager getInstance] resetFromConfig];
    
    // start level
    [[LevelManager getInstance] startNextLevel];
    
    // reset pickups policy
    [pickupsQueue removeAllObjects];
    [basicPickups removeAllObjects];
    pickupsRationed = NO;
    
    // stats
    [[StatsManager getInstance] reportScoresToGameCenter];
    [[AchievementsManager getInstance] reportAchievementsToGameCenter];
    _shouldShowRouteCompleted = NO;

    // reset stats for cur level
    [[StatsManager getInstance] resetCurLevel];
    
    // power weapons
    [self resetKillAllBullets];
    
    playerShip = [[PlayerFactory getInstance] createFromKey:[self flyerType] AtPos:CGPointMake(62.5f, 40.0f)];  
    [playerShip setRespawnPosToInitPos];
    [playerShip spawnWithPlayerStatus:playerStatus];   
    [self startScrollCam];
    [self enablePanControl];
    
    // in Timebased mode, reset gameTimeRemaining
    if(GAMEMODE_TIMEBASED == [self gameMode])
    {
        self.gameTimeRemaining = [[LevelManager getInstance] tourneyGameTime];
        _gameTimeRemainingPrev = self.gameTimeRemaining;
        _hasTourneyEnded = NO;

        // reset tourney attacks
        [[TourneyManager getInstance] didBeginGameSession];
        [self tourneyResetAttackCounts];
    }
}

- (void) exitCurrentLevel
{
    // clear achievements notifications if game happens to be showing them
    [self clearAchievementsNotifications];
    
    // clear delayed weapons
    for(Enemy* cur in [self delayedWeapons])
    {
        [cur kill];
    }
    [self.delayedWeapons removeAllObjects];
    [self.delayedWeaponsTrash removeAllObjects];
    
    // clear enemies
    [valueSortedEnemies removeAllObjects];
    [self clearAllTriggerEnemies];
    [self clearAllSpawners];
    self.spawnerTrashTrash = nil;
    self.spawnerTrash = nil;
    self.enemySpawners = nil;
    self.spawnerRegistry = nil;
    
    [self stopScrollCam];
    
    // save player status in case there is a next level when we need to restore it
    PlayerStatus* newStatus = [playerShip exportPlayerStatus];
    self.playerStatus = newStatus;
    [newStatus release];
    [playerShip kill];
    self.playerShip = nil;

    [[LevelManager getInstance] shutdownLevel];

    // these managers have to be reset last
    // shutdownLevel above may end up adding more trash from calling remove on these managers
    [[CollisionManager getInstance] reset];
    [[DynamicManager getInstance] reset];
    [[AnimProcessor getInstance] reset];
}

- (void) restartCurrentLevel
{
    // clear achievements notifications if game happens to be showing them
    [self clearAchievementsNotifications];

    // stop in-game music 2 (which is the game context sensitive track)
    [[SoundManager getInstance] stopMusic2];
    
    // clear out scrollcam blockers
    scrollCamBlocked = NO;
    [self.scrollCamBlockers removeAllObjects];
    
    // clear out enemies and reset their spawner
    for(Enemy* cur in [self delayedWeapons])
    {
        [cur kill];
    }
    [self.delayedWeapons removeAllObjects];
    [self.delayedWeaponsTrash removeAllObjects];
    
    [valueSortedEnemies removeAllObjects];
    [self clearAllTriggerEnemies];
    [self clearAllSpawners];
    for(NSString* curSpawnerName in spawnerRegistry)
    {
        EnemySpawner* curSpawner = [spawnerRegistry objectForKey:curSpawnerName];
        [curSpawner restart];
    }
    
    // clear out playership; autofire has to be explicitly untriggered
    [playerShip unTriggerAutoFire];
    [playerShip kill];

    // kill all anim-sprites (need to do this here because they rely on the following managers)
    // so, the kill and respawn cannot be atomic; thus, this is not done in restartLevel
    [[[LevelManager getInstance] curLevel] killAllAnimSprites];
    
    // clear out sim managers
    [[CollisionManager getInstance] reset];
    [[DynamicManager getInstance] reset];
    [[AnimProcessor getInstance] reset];

    // reset pickups policy
    [pickupsQueue removeAllObjects];
    [basicPickups removeAllObjects];    // doing this before player spawn is correct because when the basic pickups are
                                        // re-queued from a restart, they get added to the pickups queue as well
    pickupsRationed = NO;
    
    // restart the level
    [[LevelManager getInstance] restartLevel];
    [[[LevelManager getInstance] curLevel] spawnAllAnimSprites];
    _shouldShowRouteCompleted = NO;

    // reset stats for cur level
    [[StatsManager getInstance] resetCurLevel];

    // power weapons
    [self resetKillAllBullets];
    
    // add the playerShip back in; restore with any playerStatus that was saved from previous levels if any;
    [playerShip setRespawnPosToInitPos];
    [playerShip spawnWithPlayerStatus:playerStatus];
    [self startScrollCam];
    [self enablePanControl];

    // in Timebased mode, reset gameTimeRemaining
    if(GAMEMODE_TIMEBASED == [self gameMode])
    {
        self.gameTimeRemaining = [[LevelManager getInstance] tourneyGameTime];
        _gameTimeRemainingPrev = self.gameTimeRemaining;
        _hasTourneyEnded = NO;
        [[TourneyManager getInstance] didBeginGameSession];
        [self tourneyResetAttackCounts];
    }
}

// wrap up the current level (stop weapons, compute scores, etc.)
- (void) finishCurrentLevel
{
    // stop player auto-fire
    [playerShip stopAutoFire];
    
    // stop scrollcam
    [self stopScrollCam];

    // incapacitate all enemies
    [self incapThenKillAllEnemies];
    
    // deactivate all spawners
    [self stopAllEnemySpawners];
    
    if(GAMEMODE_TIMEBASED == [self gameMode])
    {
        [[TourneyManager getInstance] didEndGameSession];
    }
}

- (void) restartTriggers
{
    // clear out enemies and reset their spawner
    for(Enemy* cur in [self delayedWeapons])
    {
        [cur kill];
    }
    [self.delayedWeapons removeAllObjects];
    [self.delayedWeaponsTrash removeAllObjects];
    
    [valueSortedEnemies removeAllObjects];
    [self clearAllTriggerEnemies];
    [self clearAllSpawners];
    for(NSString* curSpawnerName in spawnerRegistry)
    {
        EnemySpawner* curSpawner = [spawnerRegistry objectForKey:curSpawnerName];
        [curSpawner restart];
    }
    
    // restart triggers in level
    [[LevelManager getInstance] restartTriggers];
    
    // power weapons
    [self resetKillAllBullets];
    [self startScrollCam];
}

- (void) update:(NSTimeInterval)elapsed
{
    // process level
    [[[LevelManager getInstance] curLevel] update:elapsed];
    
    // process player
    if([playerShip processRespawn:elapsed])
    {
        [panController resetPanOrigin];
        [playerShip spawnWithPlayerStatus:playerStatus];
    }
    [playerShip updateWeapons:elapsed];
    
    // clear sorted-value enemies list after player weapons
    // this list will be populated when enemies do their updateBehavior
    [valueSortedEnemies removeAllObjects];
    
    // process delayed weapons retirement
    for(Enemy* cur in self.delayedWeapons)
    {
        if([cur willRetire])
        {
            [cur kill];
            [self.delayedWeaponsTrash addObject:cur];
        }
    }
    if([self.delayedWeaponsTrash count])
    {
        for(Enemy* cur in self.delayedWeaponsTrash)
        {
            [self.delayedWeapons removeObject:cur];
        }
        [self.delayedWeaponsTrash removeAllObjects];
    }    
    
    // process enemy spawners
    for(EnemySpawner* curSpawner in self.enemySpawners)
    {
        [curSpawner update:elapsed];
        if([curSpawner hasWoundDown])
        {
            [spawnerTrash addObject:curSpawner];
        }
    }
    if([spawnerTrash count])
    {
        for(EnemySpawner* cur in spawnerTrash)
        {
            // reset the Triggered flag
            [cur setTriggered:NO];
            
            // remove it from processing
            if([cur hasOutstandingEnemies])
            {
                [spawnerTrashTrash addObject:cur];
            }
            else
            {
                [cur shutdownSpawner];
            }
            [enemySpawners removeObject:cur];
            
            // remove from blockers (if it is a blocker)
            [scrollCamBlockers removeObject:cur];
        }
        [spawnerTrash removeAllObjects];
        
        // unblock scroll cam if this garbage collection cycle has cleared out all the blockers
        if((scrollCamBlocked) && ([scrollCamBlockers count] == 0))
        {
            scrollCamBlocked = NO;
            [self startScrollCam];
        }
    }
    
    // achievements summary
    [self updateAchievementsSummary:elapsed];
    
    // update stats
    [[StatsManager getInstance] updateFlightTime:elapsed];
    
    // dismiss Swipe tip after the user has made at least N opposing swipes
    if((isShowingSwipeTip) && ([hudDelegate isMessageBeingDisplayed]) && (numOpposingSwipes > 3))
    {
        [self dismissMessage];
        isShowingSwipeTip = NO;
    }

    // update hud processing
    [hudDelegate update:elapsed];
    
    // update time-based timer
    if(GAMEMODE_TIMEBASED == _gameMode)
    {
        _gameTimeRemainingPrev = _gameTimeRemaining;
//        if([Nextpeer isCurrentlyInTournament])
//        {
//            _gameTimeRemaining = [Nextpeer timeLeftInTourament];
//        }
//        else
        {
            _gameTimeRemaining -= elapsed;
        }
        if(_gameTimeRemaining <= 0.0f)
        {
            _gameTimeRemaining = 0.0f;
        }

        if(_gameTimeRemaining <= 10.0f)
        {
            // countdown
            unsigned int prev = static_cast<unsigned int>(_gameTimeRemainingPrev);
            unsigned int cur = static_cast<unsigned int>(_gameTimeRemaining);
            if(cur < prev)
            {
                [self showCountdown:[NSString stringWithFormat:@"%d",cur]];
            }
        }
        
        [[TourneyManager getInstance] updateAttacks:elapsed];
        [self tourneyProcessAttacks:elapsed];
    }
}

- (void) postDynamicUpdate:(NSTimeInterval)elapsed
{
    // process kill-bullets here, after all the new shots have been added
    [self processKillAllBullets:elapsed];

    [[[[LevelManager getInstance] curLevel] gameCamera] offsetPosByPlayer:playerShip];
}

- (void) addDraw
{
    [[LevelManager getInstance].curLevel addDraw];
    [playerShip addDrawForWeapons];
}

// get the playArea constrained by the bounds based on the current camera path
- (CGRect) getPlayArea
{
    return [[[[LevelManager getInstance] curLevel] gameCamera] getPlayArea];
}

// get the area of the view frame
- (CGRect)getPlayFrame
{
    return [[[[LevelManager getInstance] curLevel] gameCamera] getPlayFrame];    
}

- (void) stopAllEnemySpawners
{
    for(EnemySpawner* cur in enemySpawners)
    {
        [cur setActivated:NO];
    }
}

- (void) incapThenKillAllEnemies
{
    for(EnemySpawner* cur in enemySpawners)
    {
        [cur incapThenKillAllEnemies];
    }
}

- (void) killPlayer
{
    // clear queued pickups (specifically we want to clear the healthpacks)
    [pickupsQueue removeAllObjects];
    
    // clear player status, the next spawn should start fresh
    self.playerStatus = nil;
    
    [playerShip incapacitate];
}

- (void) killAllBullets:(float)duration
{
    isKillBulletsActivated = YES;
    killBulletsTimer = duration;
}

- (void) resetKillAllBullets
{
    isKillBulletsActivated = NO;
    killBulletsTimer = 0.0f;
}

- (void) processKillAllBullets:(NSTimeInterval)elapsed
{
    if(isKillBulletsActivated)
    {
        killBulletsTimer -= elapsed;
        if(0.0f < killBulletsTimer)
        {
            for(EnemySpawner* cur in enemySpawners)
            {
                [cur killAllBullets];
            }
            for(Enemy* curWeapon in delayedWeapons)
            {
                curWeapon.willRetire = YES;
            }
        }
        else
        {
            [self resetKillAllBullets];
        }
    }
}

- (void) triggerNewSpawnerWithName:(NSString*)name triggerContext:(NSDictionary*)context
{
#if defined(DEBUG)
    if(![[DebugOptions getInstance] debugNoEnemies])
#endif
    {
        EnemySpawner* newSpawner = [self.spawnerRegistry objectForKey:name];
        if(!newSpawner)
        {
            // otherwise, create a new one
            newSpawner = [[EnemyFactory getInstance] createEnemySpawnerFromKey:name];
            [self.spawnerRegistry setObject:newSpawner forKey:name];
            [newSpawner release];
        }
        
        
        if(newSpawner)
        {
            // if spawner is already in registry, just activate it
            [newSpawner activateWithContext:context];
            [newSpawner setTriggered:YES];
            [self.enemySpawners addObject:newSpawner];    
        }
#if defined(DEBUG)
        else
        {
            NSLog(@"WARNING: Trigger not found: %@", name);
        }
#endif
    }
}

- (void) triggerNewInstanceSpawnerWithName:(NSString*)name triggerContext:(NSDictionary*)context
{
#if defined(DEBUG)
    if(![[DebugOptions getInstance] debugNoEnemies])
#endif
    {
        EnemySpawner* newSpawner = [self.spawnerRegistry objectForKey:name];
        if(!newSpawner)
        {
            // otherwise, create a new instance;
            // name assumes the convention of <spawner_name>.<instance_name>
            // eg. LineSpawner.1
            NSString* spawnerName = [name stringByDeletingPathExtension];
            newSpawner = [[EnemyFactory getInstance] createEnemySpawnerFromKey:spawnerName withTriggerName:name];
            [self.spawnerRegistry setObject:newSpawner forKey:name];
            [newSpawner release];
        }
        
        
        if(newSpawner)
        {
            // if spawner is already in registry, just activate it
            [newSpawner activateWithContext:context];
            [newSpawner setTriggered:YES];
            [self.enemySpawners addObject:newSpawner];    
        }
#if defined(DEBUG)
        else
        {
            NSLog(@"WARNING: Trigger not found: %@", name);
        }
#endif
    }
}


- (void) stopSpawnerWithName:(NSString *)name
{
    EnemySpawner* spawner = [spawnerRegistry objectForKey:name];
    if(spawner)
    {
        [spawner setActivated:NO];
    }
}

- (void) addNewGroundSpawnerWithName:(NSString*)name 
                      positionsArray:(NSArray *)positionsArray 
                       layerDistance:(float)dist
                 renderBucketShadows:(unsigned int)bucketShadows
                        renderBucket:(unsigned int)bucket
                  renderBucketAddons:(unsigned int)bucketAddons
                       forObjectType:(NSString *)objectTypename
                              asName:(NSString*)triggerName
{
    EnemySpawner* newSpawner = [[EnemyFactory getInstance] createGunSpawnerFromKey:name 
                                                                withPositionsArray:positionsArray 
                                                                        atDistance:dist
                                                               renderBucketShadows:bucketShadows
                                                                      renderBucket:bucket
                                                                renderBucketAddons:bucketAddons
                                                                     forObjectType:objectTypename
                                                                       triggerName:triggerName];
    assert(newSpawner);
    
    // deactivate it first; wait for trigger;
    [newSpawner setActivated:NO];
    
    [self.spawnerRegistry setObject:newSpawner forKey:triggerName];
    [newSpawner release];
}

- (CGPoint) getCamSpacePlayerPos
{
    return [playerShip pos];
}

- (void) clearAllSpawners
{
    for(EnemySpawner* curSpawner in enemySpawners)
    {
        [curSpawner shutdownSpawner];
    }
    for(EnemySpawner* curSpawner in spawnerTrash)
    {
        [curSpawner shutdownSpawner];
    }
    for(EnemySpawner* curSpawner in spawnerTrashTrash)
    {
        [curSpawner shutdownSpawner];
    }
    [self.spawnerTrashTrash removeAllObjects];
    [self.spawnerTrash removeAllObjects];
    [self.enemySpawners removeAllObjects];
}

- (void) clearAchievementsNotifications
{
    [self.achievementsCompleted removeAllObjects];
    [self.achievementsDisplayed removeAllObjects];
    _curAchievementTimer = 0.0f;
}

#pragma mark - game state conditions

- (BOOL) isAtEndOfLevel
{
    BOOL result = NO;
    if(GAMEMODE_TIMEBASED == _gameMode)
    {
//        if(([Nextpeer isCurrentlyInTournament]) && ([Nextpeer timeLeftInTourament] < 1.0f))
//        {
//            result = YES;
//        }
        if(!result)
        {
            result = (([self hasTourneyEnded]) || ([self gameTimeRemaining] <= 0.0f));
        }
    }
    else
    {
        result = [[[LevelManager getInstance] curLevel].gameCamera.triggerPath isAtEndOfPath];
    }
    return result;
}

- (BOOL) isPlayerDead
{
    BOOL result = NO;
    if((![playerShip isAlive]) &&
       (![playerShip isPlayerWaitingToRespawn]))
    {
        result = YES;
    }
    return result;
}

// this is a read-once BOOL; it gets reset each time it's been read
- (BOOL) shouldShowRouteCompleted
{
    BOOL result = _shouldShowRouteCompleted;
    if(result)
    {
        _shouldShowRouteCompleted = NO;
    }
    return result;
}

#pragma mark - trigger events

- (void) startPlayerAutofire
{
#if defined(DEBUG)
    if(![[DebugOptions getInstance] debugNoEnemies])
#endif
    {
        [playerShip triggerAutoFire];
    }
}

- (void) stopPlayerAutofire
{
    [playerShip unTriggerAutoFire];
}

- (void) startScrollCam
{
    if(!scrollCamBlocked)
    {
        // if not scroll-blocked, start up scroll
        [[[[LevelManager getInstance] curLevel] gameCamera] startMainPath];
    }
}

- (void) stopScrollCam
{
    [[[[LevelManager getInstance] curLevel] gameCamera] stopMainPath:PAUSETYPE_REGULAR];    
}

- (BOOL) scrollCamHasStopped
{
    BOOL result = [[[[LevelManager getInstance] curLevel] gameCamera] paused];
    return result;
}

- (void) blockScrollCamFor:(NSString *)spawnerTriggerName
{
    EnemySpawner* blocker = [self.spawnerRegistry objectForKey:spawnerTriggerName];
    if((blocker) && ([self.enemySpawners containsObject:blocker]) && (![blocker hasWoundDown]))
    {
        // if blocker has been spawned and has not yet wound down, add it to blocker list
        [self.scrollCamBlockers addObject:blocker];
        scrollCamBlocked = YES;
        
        // and block the scrollcam
        [self stopScrollCam];
    }
}

- (BOOL) blockScrollTriggerFor:(NSString *)spawnerTriggerName
{
    // assume main path is already in a loop
    assert([[[[[LevelManager getInstance] curLevel] gameCamera] camPath] isInLoop]);
    
    BOOL blockInEffect = NO;
    EnemySpawner* blocker = [self.spawnerRegistry objectForKey:spawnerTriggerName];
    if((blocker) && ([self.enemySpawners containsObject:blocker]) && (![blocker hasWoundDown]))
    {
        // if blocker has been spawned and has not yet wound down, add it to blocker list
        [self.scrollCamBlockers addObject:blocker];
        scrollCamBlocked = YES;
        
        // and block the scrollcam
        [[[[LevelManager getInstance] curLevel] gameCamera] stopMainPath:PAUSETYPE_TRIGGERONLY];   
        blockInEffect = YES;
    }
    return blockInEffect;
}

- (void) unblockScrollCamFor:(NSString *)spawnerTriggerName
{
    if(scrollCamBlocked)
    {
        EnemySpawner* blocker = [self.spawnerRegistry objectForKey:spawnerTriggerName];
        if(blocker)
        {
            [self.scrollCamBlockers removeObject:blocker];
            scrollCamBlocked = NO;
            [self startScrollCam];
        }
    }
}


- (void) respawnPlayerAfterDelay:(float)delay
{
    playerShip.isPlayerWaitingToRespawn = YES;
    playerShip.timeTillPlayerRespawn = delay;
}

- (void) showCountdown:(NSString *)text
{
    [hudDelegate showCountdown:text];
}

- (void) showLevelLabel:(NSString*)text
{
    NSString* displayText = text;
    if([text isEqualToString:@"$title"])
    {
        // $Title is this level's service name and route name
        displayText = [NSString stringWithFormat:@"%@ %@", [[LevelManager getInstance] getCurServiceName], [[LevelManager getInstance] getCurRouteName]];
    }
    [hudDelegate showLevelLabel:displayText];
}

- (void) showMessage:(NSString *)text
{
    [hudDelegate showMessage:text];
}

- (void) dismissMessage
{
    [hudDelegate dismissMessage];
}

- (void) triggerEnemy:(NSString *)label
{
    // trigger the enemy that matches the given label in the triggerEnemies registry
    Enemy* enemy = [triggerEnemies objectForKey:label];
    if(enemy)
    {
        // do enemy stuff
        [enemy triggerGameEvent:label];
    }
}

// no need to call stop at level flow points, game manager handles reseting this bool
- (void) startRationingPickups
{
    pickupsRationed = YES;
}

- (void) stopRationingPickups
{
    pickupsRationed = NO;
}

- (BOOL) isWeaponPickup:(NSString*)pickupTypename
{
    BOOL result = NO;
    if(([pickupTypename hasPrefix:@"DoubleBullet"]) || ([pickupTypename hasPrefix:@"Missile"]))
    {
        result = YES;
    }
    return result;
}

- (void) queueFromBasicPickups
{
    unsigned int index = 0;
    while(index < [basicPickups count])
    {
        PickupSpec* cur = [basicPickups objectAtIndex:index];
        [self queuePickupNamed:[cur typeName] number:[cur number]];
        ++index;
    }
}

- (void) queueBasicPickupNamed:(NSString *)typeName number:(unsigned int)num
{
    if(![self isWeaponPickup:typeName])
    {
        PickupSpec* newPickup = [[PickupSpec alloc] initWithType:typeName number:num];
        [basicPickups addObject:newPickup];
        
        // basic pickup also gets queued for release right away (in case it is triggered after player spawn)
        [pickupsQueue addObject:newPickup];
        [newPickup release];
    }
}

- (void) queuePickupNamed:(NSString*)typeName number:(unsigned int)num
{
    if(![self isWeaponPickup:typeName])
    {
        PickupSpec* newPickup = [[PickupSpec alloc] initWithType:typeName number:num];
        [pickupsQueue addObject:newPickup];
        [newPickup release];
    }
}

- (NSString*) dequeueNextPickupName
{
    NSString* result = nil;
    if([pickupsQueue count])
    {
        PickupSpec* nextPickup = [pickupsQueue objectAtIndex:0];
        result = [nextPickup typeName];
        if(1 == [nextPickup number])
        {
            // done, remove it from queue
            [pickupsQueue removeObject:nextPickup];
        }
        else
        {
            nextPickup.number--;;
        }
    }
    return result;
}


- (NSString*) dequeueNextHealthPack
{
    NSString* result = nil;
    unsigned int index = 0;
    while(index < [pickupsQueue count])
    {
        NSString* cur = [self getPickupNameAtIndex:index];
        if([cur isEqualToString:@"HealthPack"])
        {
            break;
        }
        ++index;
    }
    if(index < [pickupsQueue count])
    {
        result = [self dequeuePickupAtIndex:index];
    }
    return result;
}

- (NSString*) dequeueNextUpgradePack
{
    NSString* result = nil;
    unsigned int index = 0;
    while(index < [pickupsQueue count])
    {
        NSString* cur = [self getPickupNameAtIndex:index];
        if(([cur hasSuffix:@"Upgrade"]) && (![cur hasPrefix:@"Missile"]))
        {
            break;
        }
        ++index;
    }
    if(index < [pickupsQueue count])
    {
        result = [self dequeuePickupAtIndex:index];
    }
    return result;    
}

- (NSString*) dequeueNextMissilePack
{
    NSString* result = nil;
    unsigned int index = 0;
    while(index < [pickupsQueue count])
    {
        NSString* cur = [self getPickupNameAtIndex:index];
        if([cur hasPrefix:@"Missile"])
        {
            break;
        }
        ++index;
    }
    if(index < [pickupsQueue count])
    {
        result = [self dequeuePickupAtIndex:index];
    }
    return result;        
}

- (unsigned int) numPickupsInQueue
{
    unsigned int result = [pickupsQueue count];
    return result;    
}

- (NSString*) getPickupNameAtIndex:(unsigned int)index
{
    NSString* result = nil;
    if(index < [pickupsQueue count])
    {
        PickupSpec* cur = [pickupsQueue objectAtIndex:index];
        result = [cur typeName];
    }
    return result;
}

- (NSString*) dequeuePickupAtIndex:(unsigned int)index
{
    NSString* result = nil;
    if(index < [pickupsQueue count])
    {
        PickupSpec* cur = [pickupsQueue objectAtIndex:index];
        result = [cur typeName];
        if(1 == [cur number])
        {
            // done, remove it from queue
            [pickupsQueue removeObject:cur];
        }
        else
        {
            cur.number--;;
        }        
    }
    return result;
}

- (void) dequeueAndSpawnPickupAtPos:(CGPoint)pos
{
    if([self shouldReleasePickups])
    {   
        // dequeue game manager pickup
        NSString* pickupType = [self dequeueNextPickupName];
        if(pickupType)
        {
            Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:pickupType atPos:pos 
                                                                             isDynamics:YES 
                                                                    groundedBucketIndex:0 
                                                                          layerDistance:0.0f];
            [newLoot spawn];
            [newLoot release];
        }
    }
}

- (void) queueStandardUpgrades
{
    [self queuePickupNamed:@"KillAllBulletUpgrade" number:1];
    [self queuePickupNamed:@"DoubleBulletUpgrade" number:1];
    [self queuePickupNamed:@"KillAllBulletUpgrade" number:1];
}
// returns true when pickups are not rationed, or when there're game-managed pickups available
- (BOOL) shouldReleasePickups
{
    BOOL result = !pickupsRationed;
    if([pickupsQueue count])
    {
        result = YES;
    }
    return result;
}

- (float) getCargoMagnetDistance
{
    float result = 0.0f;
    if(GAMEMODE_TIMEBASED == _gameMode)
    {
        result = 20.0f;
    }
    else
    {
        result = 30.0f;
    }
    return result;
}

- (unsigned int) getUpgradeCargosCountForWeaponLevel:(unsigned int)weaponLevel
{
    unsigned int result = 10 + (10 * weaponLevel);
    return result;
}

- (void) setCargosTowardsMultiplier:(unsigned int)num
{
    [hudDelegate setCargoTowardsMultiplier:num];
}

- (void) triggerAchievementsSummary
{
    // collect names of all the newly completed achievements
    NSDictionary* achievements = [[AchievementsManager getInstance] getGameAchievementsData];
    NSDictionary* achievementsInfo = [[AchievementsManager getInstance] achievementsRegistry];
    for(NSString* cur in achievements)
    {
        AchievementsData* curData = [achievements objectForKey:cur];
        if([curData isDirty])
        {
            [_achievementsCompleted addObject:[[achievementsInfo objectForKey:cur] name]];
        }
    }
}

- (void) updateAchievementsSummary:(NSTimeInterval)elapsed
{
    if(0.0f >= _curAchievementTimer)
    {
        if([_achievementsCompleted count] > 0)
        {
            [hudDelegate showAchievementWithName:[_achievementsCompleted objectAtIndex:0]];
            _curAchievementTimer = 2.0f;
            [_achievementsCompleted removeObjectAtIndex:0];
        }
    }
    else
    {
        _curAchievementTimer -= elapsed;
    }
}

- (void) showAchievementCompletedForIdentifier:(NSString *)identifier
{
    NSDictionary* achievementsInfo = [[AchievementsManager getInstance] achievementsRegistry];
    AchievementRegEntry* achievement = [achievementsInfo objectForKey:identifier];
    if(achievement && (![_achievementsDisplayed containsObject:achievement]))
    {
        [hudDelegate showAchievementWithName:[achievement name]];
        [_achievementsDisplayed addObject:achievement];
    }
}

- (void) showAchievementMessage:(NSString *)message
{
    [hudDelegate showAchievementWithName:message];
}


- (void) showRouteCompleted
{
    _shouldShowRouteCompleted = YES;
}

#pragma mark - tourney
static const float TOURNEY_FIREWORKS_SAFEAREA = 0.9f;
static const float TOURNEY_FIREWORKS_DURATION = 3.0f;
static const float TOURNEY_FIREWORKS_SPAWN_INTERVAL = 0.2f;
#define TOURNEY_FIREWORKS_NUMSPAWNERS (30)
static float sTourneyFireworksSpawnTimers[TOURNEY_FIREWORKS_NUMSPAWNERS];

- (void) tourneyResetAttackCounts
{
    self.lastAttackerName = nil;
    _attackReceivedCount = 0;
    _attackProcessedCount = 0;
    _lastAttackEnum = TOURNEY_ATTACK_INVALID;
    _tourneyFireworksTimer = 0.0f;
    
    // pause the DarkClouds path; to be unpaused when an attack is received;
    [[LevelManager getInstance].curLevel.gameCamera pausePathNamed:@"DarkClouds"];
}

- (void) tourneyShowDarkClouds
{
    TopCam* gameCamera = [[[LevelManager getInstance] curLevel] gameCamera];
    [gameCamera unpausePathNamed:@"DarkClouds"];
    if([gameCamera isAtEndOfPathNamed:@"DarkClouds"])
    {
        [gameCamera resetPathNamed:@"DarkClouds"];
    }
}

- (void) tourneyShowFireworks
{
    if(0.0f >= _tourneyFireworksTimer)
    {
        _tourneyFireworksTimer = TOURNEY_FIREWORKS_DURATION;
        for(unsigned int i = 0; i < TOURNEY_FIREWORKS_NUMSPAWNERS; ++i)
        {
            sTourneyFireworksSpawnTimers[i] = TOURNEY_FIREWORKS_SPAWN_INTERVAL + (i * 0.05f);
        }
    }
}

- (void) tourneyFireworksUpdate:(NSTimeInterval)elapsed
{
    if(0.0f < _tourneyFireworksTimer)
    {
        _tourneyFireworksTimer -= elapsed;
        CGRect playArea = [self getPlayArea];
        CGFloat safeWidth = playArea.size.width * TOURNEY_FIREWORKS_SAFEAREA;
        CGFloat safeHeight = playArea.size.height * TOURNEY_FIREWORKS_SAFEAREA;
        CGFloat safeX = 0.5f * (playArea.size.width - safeWidth);
        CGFloat safeY = 0.5f * (playArea.size.height - safeHeight);
        for(unsigned int i = 0; i < TOURNEY_FIREWORKS_NUMSPAWNERS; ++i)
        {
            float curTimer = sTourneyFireworksSpawnTimers[i];
            curTimer -= elapsed;
            if(curTimer <= 0.0f)
            {
                CGFloat posX = (randomFrac() * safeWidth) + (playArea.origin.x + safeX);
                CGFloat posY = (randomFrac() * safeHeight) + (playArea.origin.y + safeY);
                unsigned int effectIndex = (i % [_tourneyFireworksEffectNames count]);
                [EffectFactory effectNamed:[_tourneyFireworksEffectNames objectAtIndex:effectIndex] atPos:CGPointMake(posX,posY)];   
                curTimer = TOURNEY_FIREWORKS_SPAWN_INTERVAL;
            }
            sTourneyFireworksSpawnTimers[i] = curTimer;
        }
    }
}

- (void) tourneyProcessAttacks:(NSTimeInterval)elapsed
{
    if(_attackReceivedCount > _attackProcessedCount)
    {
        _attackProcessedCount = _attackReceivedCount;
        NSString* effectName = nil;
        NSString* attackString = nil;
        NSString* attacker = [self lastAttackerName];
        if(!attacker)
        {
            attacker = @"Someone";
        }
        switch(_lastAttackEnum)
        {
            case TOURNEY_ATTACK_DARKCLOUDS:
                effectName = @"DarkCloudsReceived";
                attackString = [NSString stringWithFormat:@"%@ just attacked you with Scary Dark Clouds!", attacker];
                [self tourneyShowDarkClouds];
                break;
                
            case TOURNEY_ATTACK_FIREWORKS:
                effectName = @"FireworksReceived";
                attackString = [NSString stringWithFormat:@"%@ just gave you Awesome Fireworks!", attacker];
                [self tourneyShowFireworks];
                break;
                
            case TOURNEY_ATTACK_MUTE:
                effectName = @"MuteReceived";
                attackString = [NSString stringWithFormat:@"%@ just Muted Your Weapon!", attacker];
                [playerShip tourneyMutePlayer];
                break;
        }
        
        if(effectName)
        {
            if(hudDelegate)
            {
                [hudDelegate showTourneyMessage:attackString withIcon:[self lastAttackerIcon]];
            }
            [[SoundManager getInstance] playClip:@"KillBullets"];
            [EffectFactory effectNamed:effectName atPos:[playerShip pos]];
        }
    }
    
    [self tourneyFireworksUpdate:elapsed];
}

#pragma mark - NPTournamentDelegate
-(void)nextpeerDidReceiveTournamentCustomMessage:(NPTournamentCustomMessageContainer*)message
{
    NSError* error;
    NSData* messageData = message.message;
    if(messageData)
    {
        NSNumber* dataNumber = [NSPropertyListSerialization propertyListWithData:messageData
                                                                         options:NSPropertyListImmutable
                                                                          format:NULL
                                                                           error:&error];
        _lastAttackEnum = [dataNumber intValue];
    }
    else
    {
        _lastAttackEnum = TOURNEY_ATTACK_INVALID;
    }
    
    self.lastAttackerName = [NSString stringWithString:[message playerName]];
    self.lastAttackerIcon = [message playerImage];
    ++_attackReceivedCount;
}

-(void)nextpeerDidReceiveTournamentResults:(NPTournamentEndDataContainer*)tournamentContainer
{
    [[TourneyManager getInstance] didEndTournamentWithResults:tournamentContainer];
}


#pragma mark - trigger receiving enemies
- (void) registerTriggerEnemy:(Enemy*)givenEnemy forTriggerLabel:(NSString*)label
{
    [triggerEnemies setObject:givenEnemy forKey:label];
}

- (void) unRegisterTriggerEnemyForLabel:(NSString*)label
{
    [triggerEnemies removeObjectForKey:label];
}

- (void) clearAllTriggerEnemies
{
    [triggerEnemies removeAllObjects];
}

#pragma mark - value sorted enemies

- (Enemy*) getValueEnemyAtIndex:(unsigned int)index
{
    Enemy* result = nil;
    if([valueSortedEnemies count] > 0)
    {
        // if there are enemies in the list, return the top guy for any queries 
        // higher than number of enemies in the list
        if([valueSortedEnemies count] <= index)
        {
            index = 0;
        }
    }
    if(index < [valueSortedEnemies count])
    {
        result = [valueSortedEnemies objectAtIndex:index];
    }
    return result;
}

- (void) addValueSortedenemy:(Enemy*)newEnemy
{
    if(![valueSortedEnemies containsObject:newEnemy])
    {
        unsigned int index = 0;
        while(index < [valueSortedEnemies count])
        {
            Enemy* cur = [valueSortedEnemies objectAtIndex:index];
            if([newEnemy health] < [cur health])
            {
                break;
            }
            ++index;
        }
        if(index >= [valueSortedEnemies count])
        {
            [valueSortedEnemies addObject:newEnemy];
        }
        else
        {
            [valueSortedEnemies insertObject:newEnemy atIndex:index];
        }
    }
}

- (void) removeFromValueSortedEnemy:(Enemy*)enemyToRemove
{
    [valueSortedEnemies removeObject:enemyToRemove];
}


#pragma mark - Gesture Handlers
- (void) handlePanControl:(PanController *)sender
{
    if(panControllerEnabled)
    {
        if([sender panTouch])
        {
            if(sender.isPanning)
            {
                if(sender.justStartedPan)
                {
                    [playerShip startPanning];
                }
                CGSize frameSize = [self getPlayArea].size;
                CGPoint worldTranslate = CGPointMake(frameSize.width * sender.panPosition.x / sender.frameSize.width,
                                                     -frameSize.height * sender.panPosition.y / sender.frameSize.height);
                [playerShip panWithTranslation:worldTranslate];
                
                // STATS: track the number of almost-opposing swipes player has performed
                CGPoint curSwipeTrackingVec = CGPointMake(worldTranslate.x - prevSwipeTranslate.x, worldTranslate.y - prevSwipeTranslate.y);
                float dot = DotProduct(CGPointNormalize(prevSwipeVec), CGPointNormalize(curSwipeTrackingVec));
                prevSwipeVec = curSwipeTrackingVec;
                prevSwipeTranslate = worldTranslate;
                if(0.3f >= dot)
                {
                    ++numOpposingSwipes;
                }
            }
        }
    }
}

- (void) enablePanControl
{
    panControllerEnabled = YES;
    [self.panController setEnabled:YES];
    [self.panController reset];
}

- (void) disablePanControl
{
    panControllerEnabled = NO;
    [self.panController setEnabled:NO];
    [self.panController reset];
}

- (void) dropBomb
{
    [playerShip setShouldDropBomb:YES];
}
@end
