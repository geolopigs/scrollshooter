//
//  Enemy.h
//

#import <Foundation/Foundation.h>
#import "DynamicProtocols.h"
#import "EnemyProtocol.h"
#import "CollisionProtocols.h"
#import "AddonProtocols.h"

@class Sprite;
@class AnimLinearController;
@class AnimClip;
@class FiringPath;
@class EnemySpawner;
@class Addon;
@class Shot;
@interface Enemy : NSObject<DynamicDelegate,CollisionDelegate,AddonDelegate>
{
    NSObject<EnemyInitProtocol>* initDelegate;
	Sprite*	renderer;
    AnimLinearController* animController;
    AnimClip* animClip;
    BOOL hidden;
    float hiddenTimer;  // use this when you want to hide the enemy and have it automatically become visible after a given duration
    
    // for multi-state animation
    NSMutableDictionary* animClipRegistry;
    AnimClip* curAnimClip;
    
    unsigned int renderBucketIndex;
    unsigned int renderBucketShadowsIndex;
    unsigned int renderBucketAddonsIndex;
    BOOL shouldAddToRenderBucketLayer;
    BOOL isGrounded;
	EnemySpawner* mySpawner;
    
    CGPoint modelTranslate;
    CGPoint scale;
    float rotate;   // in radians
	CGPoint pos;
	CGPoint vel;
	NSObject<EnemyBehaviorProtocol>* behaviorDelegate;
    
    // archetype specific spawned behavior
    NSObject<EnemySpawnedDelegate>* spawnedDelegate;
    
    // Parent info - for enemies that are spawned as add-ons on other enemies
    NSObject<EnemyParentDelegate>* parentDelegate;
    Enemy* parentEnemy;
    BOOL _hasPlayerParent;
    
    // Collision states
    CGRect colAABB;
    NSObject<EnemyCollisionResponse>* collisionResponseDelegate;
    NSObject<EnemyAABBDelegate>* collisionAABBDelegate;
    
    // Kill delegate
    NSObject<EnemyKilledDelegate>* killedDelegate;
    BOOL incapacitated;
    unsigned int waveIndex;
    
    // enemy fire
    FiringPath* firingPath;
    BOOL readyToFire;
    
    // Game status
    int   health;
    BOOL    willRetire;
    id      behaviorContext;
    
    // effect-addons; eg. wakes, shadows, etc.
    NSMutableArray* effectAddons;
    
    // internal cache
    CGSize gameplayAreaSize;
}
@property (nonatomic,retain) NSObject<EnemyInitProtocol>* initDelegate;
@property (nonatomic,assign) CGPoint modelTranslate;
@property (nonatomic,assign) CGPoint scale;
@property (nonatomic,assign) float rotate;
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGPoint vel;
@property (nonatomic,retain) Sprite* renderer;
@property (nonatomic,retain) AnimLinearController* animController;
@property (nonatomic,retain) AnimClip* animClip;
@property (nonatomic,assign) BOOL hidden;
@property (nonatomic,assign) float hiddenTimer;
@property (nonatomic,retain) NSMutableDictionary* animClipRegistry;
@property (nonatomic,retain) AnimClip* curAnimClip;
@property (nonatomic,assign) unsigned int renderBucketIndex;
@property (nonatomic,assign) unsigned int renderBucketShadowsIndex;
@property (nonatomic,assign) unsigned int renderBucketAddonsIndex;
@property (nonatomic,assign) BOOL shouldAddToRenderBucketLayer;
@property (nonatomic,assign) BOOL isGrounded;
@property (nonatomic,retain) EnemySpawner* mySpawner;
@property (nonatomic,retain) NSObject<EnemyBehaviorProtocol>* behaviorDelegate;
@property (nonatomic,retain) NSObject<EnemySpawnedDelegate>* spawnedDelegate;
@property (nonatomic,retain) NSObject<EnemyParentDelegate>* parentDelegate;
@property (nonatomic,retain) Enemy* parentEnemy;
@property (nonatomic,assign) BOOL hasPlayerParent;
@property (nonatomic,assign) CGRect colAABB;
@property (nonatomic,retain) NSObject<EnemyCollisionResponse>* collisionResponseDelegate;
@property (nonatomic,retain) NSObject<EnemyAABBDelegate>* collisionAABBDelegate;
@property (nonatomic,retain) NSObject<EnemyKilledDelegate>* killedDelegate;
@property (nonatomic,readonly) BOOL incapacitated;
@property (nonatomic,assign) unsigned int waveIndex;
@property (nonatomic,retain) FiringPath* firingPath;
@property (nonatomic,assign) BOOL readyToFire;
@property (nonatomic,assign) BOOL removeBulletsWhenIncapacitated;
@property (nonatomic,assign) int health;
@property (nonatomic,assign) BOOL willRetire;
@property (nonatomic,retain) id behaviorContext;
@property (nonatomic,retain) NSMutableArray* effectAddons;

- (id) initAtPos:(CGPoint)givenPos 
   usingDelegate:(NSObject<EnemyInitProtocol>*)archetype;
- (id) initAtPos:(CGPoint)givenPos 
   usingDelegate:(NSObject<EnemyInitProtocol>*)archetype
withSpawnerContext:(id)spawnerContext;

- (void) spawn;
- (void) incapThenKill;
- (void) incapThenKillWithPoints:(BOOL)creditPlayer;
- (void) incapAndKill;
- (void) incapAndKillWithPoints:(BOOL)creditPlayer;
- (void) kill;
- (BOOL) incapacitate;
- (BOOL) incapacitateWithPoints:(BOOL)creditPlayer;
- (Shot*) fireFromPos:(CGPoint)firingPosition dir:(float)dir speed:(float)speed;
- (void) fireFromPos:(CGPoint)firingPosition withVel:(CGPoint)firingVelocity;
- (void) fireWithVel:(CGPoint)firingVelocity;
- (void) triggerGameEvent:(NSString*)label;
- (void) killAllBullets;

// utility methods
+ (CGPoint) transformPoint:(CGPoint)localPoint outOfParentPos:(CGPoint)parentPos parentRotate:(CGFloat)parentRotate;
+ (CGPoint) derivePosFromParentForEnemy:(Enemy*)givenEnemy;

@end

