//
//  GameManager.h
//  Curry
//  
//  The GameManager owns the player
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"
#import "GameHudDelegate.h"
#import "GameModes.h"
#import "Nextpeer/NPTournamentDelegate.h"

// Game Notifications
extern NSString* const kNextpeerTourneyDidStart;
extern NSString* const kNextpeerDashboardDidExit;
extern NSString* const kNextpeerDashboardWillAppear;
extern NSString* const kNextpeerTourneyDidEnd;

extern const unsigned int NUM_CARGOS_PER_MULT;

@class PanController;
@class Player;
@class Level;
@class TopCam;
@class Enemy;
@class PlayerStatus;

@interface GameManager : NSObject<NPTournamentDelegate>
{
    unsigned int _gameMode;
    
    NSString* _flyerId;             // selected flyerId for upcoming session
    PlayerStatus* playerStatus;     // to maintain persistent player data across levels
    Player* playerShip;
    Level*  curLevel;
    PanController* panController;
    BOOL panControllerEnabled;
    
    NSMutableArray* enemySpawners;
    NSMutableArray* spawnerTrash;
    NSMutableArray* spawnerTrashTrash;      // this is really the trash that needs to properly shutdown by end of level
    NSMutableDictionary* spawnerRegistry;
    
    NSObject<GameHudDelegate>* hudDelegate;
    
    // variables for tracking player has swiped the screen sufficiently to dismiss the swipe tutorial message
    unsigned int numOpposingSwipes;
    CGPoint prevSwipeVec;
    CGPoint prevSwipeTranslate;
    
    // UI
    BOOL isShowingSwipeTip;
    BOOL _shouldShowRouteCompleted;
    
    // scroll cam start/stop
    NSMutableArray* scrollCamBlockers;  // the spawners that block the scroll cam;
                                        // scroll cam restarts only if these spawners are all hasWoundDown
    BOOL scrollCamBlocked;
    
    // pick-ups policy
    NSMutableArray* pickupsQueue;   // an array of Loot types
    NSMutableArray* basicPickups;   // array of Loots that get added everytime a player spawns
                                    // cleared per level;
    BOOL            pickupsRationed;    // TRUE if game-manager is rationing pickups, this means enemies etc are not allowed to release their own pick-ups
                                        // FALSE means everyone can release whatever they want

    // trigger receiving enemies
    NSMutableDictionary* triggerEnemies;
    
    // active enemies sorted from low to high health
    NSMutableArray* valueSortedEnemies;
    
    // delayed weapons (such as ScatterBomb)
    NSMutableArray* delayedWeapons;
    NSMutableArray* delayedWeaponsTrash;
    
    // player powers
    BOOL isKillBulletsActivated;
    float killBulletsTimer;
    BOOL _hasUsedLifeSaver;
    NSDictionary* _tourneyUtilLookup;
    
    // time-based game mode
    float _gameTimeRemaining;
    float _gameTimeRemainingPrev;
    BOOL _hasTourneyEnded;
    unsigned int _attackReceivedCount;
    unsigned int _attackProcessedCount;
    unsigned int _lastAttackEnum;
    NSString* _lastAttackerName;
    UIImage* _lastAttackerIcon;
    float _tourneyFireworksTimer;
    NSMutableArray* _tourneyFireworksSpawnTimers;
    NSArray* _tourneyFireworksEffectNames;
}
@property (nonatomic,assign) unsigned int gameMode;
@property (nonatomic,retain) NSString* flyerId;
@property (nonatomic,readonly) NSString* flyerType;
@property (nonatomic,retain) PlayerStatus* playerStatus;
@property (nonatomic,retain) Player* playerShip;
@property (nonatomic,retain) Level* curLevel;
@property (nonatomic,retain) PanController* panController;
@property (nonatomic,retain) NSMutableArray* enemySpawners;
@property (nonatomic,retain) NSMutableArray* spawnerTrash;
@property (nonatomic,retain) NSMutableArray* spawnerTrashTrash;
@property (nonatomic,retain) NSMutableDictionary* spawnerRegistry;
@property (nonatomic,retain) NSObject<GameHudDelegate>* hudDelegate;
@property (nonatomic,retain) NSMutableArray* scrollCamBlockers;
@property (nonatomic,retain) NSMutableArray* pickupsQueue;
@property (nonatomic,retain) NSMutableArray* basicPickups;
@property (nonatomic,retain) NSMutableDictionary* triggerEnemies;
@property (nonatomic,retain) NSMutableArray* valueSortedEnemies;
@property (nonatomic,retain) NSMutableArray* delayedWeapons;
@property (nonatomic,retain) NSMutableArray* delayedWeaponsTrash;
@property (nonatomic,assign) BOOL isKillBulletsActivated;
@property (nonatomic,assign) float killBulletsTimer;
@property (nonatomic,assign) BOOL hasUsedLifeSaver;
@property (nonatomic,readonly) BOOL shouldShowRouteCompleted;

// achievements summary
@property (nonatomic,retain) NSMutableArray* achievementsCompleted;
@property (nonatomic,retain) NSMutableArray* achievementsDisplayed;
@property (nonatomic,assign) float curAchievementTimer;

@property (nonatomic,assign) float gameTimeRemaining;
@property (nonatomic,assign) BOOL hasTourneyEnded;
@property (nonatomic,retain) UIImage* lastAttackerIcon;
@property (nonatomic,retain) NSString* lastAttackerName;

+(GameManager*) getInstance;
+(void) destroyInstance;

// Notes on level flow calls:
//  newGame -- performs init when entering from the Frontend
//      gotoNextLevel -- starts up the level
//          restartCurrentLevel -- this method does lightweight restart of the current level
//          finishCurrentLevel -- this method does not shutdown the level, it is for putting the current level into a completed, non-playable state
//      exitCurrentLevel -- this method does the actual shutdown
//  exitGame -- performs all the shutdown prior to going back to the Frontend
- (void) newGame;
- (void) exitGame;
- (void) gotoNextLevel;
- (void) exitCurrentLevel;
- (void) restartCurrentLevel;
- (void) finishCurrentLevel;
- (void) restartTriggers;       // used in Timebased mode to restart the trigger path without restarting the whole level

- (void) addDraw;
- (void) update:(NSTimeInterval)elapsed;
- (void) postDynamicUpdate:(NSTimeInterval)elapsed;
- (CGRect) getPlayArea;
- (CGRect) getPlayFrame;

- (void) stopAllEnemySpawners;
- (void) incapThenKillAllEnemies;
- (void) killPlayer;
- (void) killAllBullets:(float)duration;
- (void) triggerNewSpawnerWithName:(NSString*)name triggerContext:(NSDictionary*)context;
- (void) triggerNewInstanceSpawnerWithName:(NSString*)name triggerContext:(NSDictionary*)context;
- (void) stopSpawnerWithName:(NSString*)name;
- (void) addNewGroundSpawnerWithName:(NSString*)name 
                      positionsArray:(NSArray *)positionsArray 
                       layerDistance:(float)dist
                 renderBucketShadows:(unsigned int)bucketShadows
                        renderBucket:(unsigned int)bucket
                  renderBucketAddons:(unsigned int)bucketAddons
                       forObjectType:(NSString *)objectTypename
                              asName:(NSString*)triggerName;


- (CGPoint) getCamSpacePlayerPos;


// game state conditions
- (BOOL) isAtEndOfLevel;
- (BOOL) isPlayerDead;

// trigger events
- (void) startPlayerAutofire;
- (void) stopPlayerAutofire;
- (void) startScrollCam;
- (void) stopScrollCam;
- (BOOL) scrollCamHasStopped;
- (void) blockScrollCamFor:(NSString*)spawnerTriggerName;
- (BOOL) blockScrollTriggerFor:(NSString*)spawnerTriggerName;
- (void) unblockScrollCamFor:(NSString*)spawnerTriggerName;
- (void) respawnPlayerAfterDelay:(float)delay;
- (void) showCountdown:(NSString*)text;
- (void) showLevelLabel:(NSString*)text;
- (void) showMessage:(NSString*)text;
- (void) dismissMessage;
- (void) triggerEnemy:(NSString*)label;
- (void) triggerAchievementsSummary;
- (void) showAchievementCompletedForIdentifier:(NSString*)identifier;
- (void) showAchievementMessage:(NSString *)message;
- (void) showRouteCompleted;

// pick-ups policy
- (void) queueFromBasicPickups;
- (void) queueBasicPickupNamed:(NSString*)typeName number:(unsigned int)num;
- (void) queuePickupNamed:(NSString*)typeName number:(unsigned int)num;
- (NSString*) dequeueNextPickupName;
- (BOOL) shouldReleasePickups;
- (void) startRationingPickups;
- (void) stopRationingPickups;
- (unsigned int) numPickupsInQueue;
- (NSString*) getPickupNameAtIndex:(unsigned int)index;
- (NSString*) dequeuePickupAtIndex:(unsigned int)index;
- (NSString*) dequeueNextHealthPack;
- (NSString*) dequeueNextUpgradePack;
- (NSString*) dequeueNextMissilePack;
- (void) dequeueAndSpawnPickupAtPos:(CGPoint)pos;
- (float) getCargoMagnetDistance;
- (unsigned int) getUpgradeCargosCountForWeaponLevel:(unsigned int)weaponLevel;
- (void) setCargosTowardsMultiplier:(unsigned int)num;

// trigger receiving enemies
- (void) registerTriggerEnemy:(Enemy*)givenEnemy forTriggerLabel:(NSString*)label;
- (void) unRegisterTriggerEnemyForLabel:(NSString*)label;
- (void) clearAllTriggerEnemies;

// value sorted enemies accessors
- (Enemy*) getValueEnemyAtIndex:(unsigned int)index;
- (void) addValueSortedenemy:(Enemy*)newEnemy;
- (void) removeFromValueSortedEnemy:(Enemy*)enemyToRemove;

// gesture handlers
- (void) handlePanControl:(PanController*)sender;
- (void) enablePanControl;
- (void) disablePanControl;
- (void) dropBomb;
@end
