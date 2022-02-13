//
//  Player.h
//

#import <Foundation/Foundation.h>
#import "DynamicProtocols.h"
#import "PlayerProtocols.h"
#import "CollisionProtocols.h"
#import "AddonProtocols.h"

typedef enum
{
    FlyerTypePoglider = 0,
    FlyerTypePogwing,
    FlyerTypePograng
} FlyerType;

@class Sprite;
@class FiringPath;
@class AnimLinearController;
@class AnimClip;
@class Addon;
@class PlayerStatus;
@class FlyerWeapon;
@interface Player : NSObject<DynamicDelegate,ConstraintDelegate,CollisionDelegate,AddonDelegate>
{
    FlyerType _flyerType;
	Sprite*	renderer;
    NSArray* anim;
    AnimLinearController* animController;
    unsigned int renderBucketIndex;
    unsigned int addonsBucketIndex;
    unsigned int shadowsBucketIndex;
	
    CGPoint initPos;
    CGPoint _respawnPos;
	CGPoint pos;
    CGPoint prevPos;
	CGPoint vel;
    CGPoint displacement;
    CGPoint panVec;
    CGPoint panOrigin;
    BOOL isPanning;
    BOOL isDisplaced;
    BOOL _shouldDropBomb;
    
    PlayerStatus* initPlayerStatus;     // for restoring player health, weapons, etc. from level to level;
                                        // if nil, it's a new game
    
    // health
    BOOL    isPlayerWaitingToRespawn;
    float   timeTillPlayerRespawn;
    int health;
    float   immunityTimer;      // time when player is immune to hits; counts down to zero;
    float   immunityAlpha;      // for blinking the player when it is immune
    float   immunityAlphaVel;   // toggling between +1.0f and -1.0f to result in blink
    BOOL    isAlive;
    unsigned int numKillBulletPacks;
    float killBulletsDuration;
    BOOL    hasQueuedHealthPack;
    
    // weapons
    FlyerWeapon* _weapon;
    BOOL        doAutoFire;
    BOOL        triggeredAutoFire;
    
    // utilities
    float       _magnetDistUpgrade;
    float       _cargoMagnetRadius;
    
    // cargos
    unsigned int cargosCountTowardsMultiplier;
    float cargoCollectedEffectTimer;
    unsigned int _cargosCountTowardsUpgrade;
    
    // attachements
    NSString* _shadowName;
    Addon* shadow;
    Addon* cargoCollectedEffect;
    
    // tourney
    Addon* _tourneyMutePlayer;
    float _mutePlayerTimer;
    
    NSString* _pickupTypename;
    
    // collision
    CGRect colAABB;
}
@property (nonatomic,assign) FlyerType flyerType;
@property (nonatomic,retain) Sprite* renderer;
@property (nonatomic,retain) NSArray* anim;
@property (nonatomic,retain) AnimLinearController* animController;
@property (nonatomic,assign) CGPoint respawnPos;
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGPoint prevPos;
@property (nonatomic,assign) CGPoint vel;
@property (nonatomic,assign) BOOL shouldDropBomb;
@property (nonatomic,retain) PlayerStatus* initPlayerStatus;
@property (nonatomic,assign) BOOL isPlayerWaitingToRespawn;
@property (nonatomic,assign) float timeTillPlayerRespawn;
@property (nonatomic,assign) int health;
@property (nonatomic,assign) float immunityTimer;
@property (nonatomic,readonly) BOOL isAlive;
@property (nonatomic,assign) unsigned int numKillBulletPacks;
@property (nonatomic,assign) float killBulletsDuration;
@property (nonatomic,retain) FlyerWeapon* weapon;
@property (nonatomic,assign) BOOL triggeredAutoFire;
@property (nonatomic,assign) float magnetDistUpgrade;
@property (nonatomic,readonly) float cargoMagnetRadius;
@property (nonatomic,retain) NSString* shadowName;
@property (nonatomic,retain) Addon* cargoCollectedEffect;
@property (nonatomic,retain) NSString* pickupTypename;
@property (nonatomic,assign) CGRect colAABB;

- (id) initAtPos:(CGPoint)givenPos 
   usingDelegate:(NSObject<PlayerInitProtocol>*)initDelegate;

- (void) setRespawnPosToInitPos;
- (void) spawnWithPlayerStatus:(PlayerStatus*)playerStatus;
- (void) incapacitate;
- (void) kill;
- (BOOL) processRespawn:(NSTimeInterval)elapsed;
- (void) startAutoFire;
- (void) stopAutoFire;
- (void) triggerAutoFire;
- (void) unTriggerAutoFire;

// tourney
- (void) tourneyMutePlayer;

// weapons
- (void) addDrawForWeapons;
- (void) updateWeapons:(NSTimeInterval)elapsed;

// controls
- (void) displaceByVector:(CGPoint)vec;
- (void) panWithTranslation:(CGPoint)translate;
- (void) startPanning;

// player status
- (PlayerStatus*) exportPlayerStatus;

@end
