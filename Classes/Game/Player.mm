//
//  Player.mm
//

#import "Player.h"
#import "DrawCommand.h"
#import "RenderBucketsManager.h"
#import "Sprite.h"
#import "DynamicManager.h"
#import "CollisionManager.h"
#import "FiringPath.h"
#include "MathUtils.h"
#import "AnimLinearController.h"
#import "AnimProcessor.h"
#import "AnimClip.h"
#import "AnimFrame.h"
#import "Texture.h"
#import "GameManager.h"
#import "TourneyManager.h"
#import "GameObjectSizes.h"
#import "LevelManager.h"
#import "StatsManager.h"
#import "SoundManager.h"
#import "Level.h"
#import "LevelAnimData.h"
#import "EffectFactory.h"
#import "Effect.h"
#import "AddonFactory.h"
#import "Addon.h"
#import "Enemy.h"
#import "Shot.h"
#import "Loot.h"
#import "LootFactory.h"
#import "PlayerStatus.h"
#import "AchievementsManager.h"
#import "FlyerWeapon.h"
#import "PlayerInventory.h"
#import "PlayerInventoryIds.h"

#if defined(DEBUG)
#import "DebugOptions.h"
#endif

enum WeaponTypes
{
    PLAYER_WEAPON_BASIC = 0,
    PLAYER_WEAPON_DOUBLE,
    PLAYER_WEAPON_DOUBLE2,
    PLAYER_WEAPON_TRIPLE,
    
    PLAYER_WEAPON_NUM
};

@interface Player (PlayerPrivate)
- (void) autoFire:(NSTimeInterval)elapsed;
- (void) addToRenderBucket:(unsigned int)index atPos:(CGPoint)renderPos atAnimFrameIndex:(int)animFrameIndex;
- (void) resetHealth;
- (void) resetKillAllBullets;
- (void) resetUtilitiesToInitLevel;
- (void) initWeapons;
- (void) shutdownWeapons;
- (void) upgradeWeapon;
- (unsigned int) numUpgradesToDropWhenKilled;
- (void) dropBomb;
@end

@implementation Player
@synthesize flyerType = _flyerType;
@synthesize renderer;
@synthesize anim;
@synthesize animController;
@synthesize respawnPos = _respawnPos;
@synthesize pos;
@synthesize prevPos;
@synthesize vel;
@synthesize shouldDropBomb = _shouldDropBomb;
@synthesize initPlayerStatus;
@synthesize isPlayerWaitingToRespawn;
@synthesize timeTillPlayerRespawn;
@synthesize health;
@synthesize immunityTimer;
@synthesize isAlive;
@synthesize numKillBulletPacks;
@synthesize killBulletsDuration;
@synthesize weapon = _weapon;
@synthesize triggeredAutoFire;
@synthesize magnetDistUpgrade = _magnetDistUpgrade;
@synthesize cargoMagnetRadius = _cargoMagnetRadius;
@synthesize shadowName = _shadowName;
@synthesize cargoCollectedEffect;
@synthesize pickupTypename;
@synthesize colAABB;

static const float PLAYER_SPEED = 20.0f;
static const float PLAYER_SWIPEVELAXIS = PLAYER_SPEED;
static const float PLAYER_SWIPEVELDIAG = PLAYER_SPEED / sqrtf(2.0f);

// health
static const float IMMUNE_TIME_LIMIT = 1.0f;    // player immune for this many seconds after each hit
static const float BLINKING_PERIOD = 4.0f;      // alpha changes per second

// AutoFireShot
static const float PLAYER_AUTOFIRESHOT_VELY = 100.0f;
static const float PLAYER_AUTOFIRESHOT_SPEED = 100.0f;
static const float PLAYER_TRIPLEFIRE_ANGLE = M_PI * 0.05f;
static const unsigned int PLAYER_MISSILEGRADE_MAX = 2;

// Flyer gun offset
// AutoFireShot
static const float PLAYER_GUN_LOCAL_X = 0.0f;
static const float PLAYER_GUN_LOCAL_Y = 8.0f;
static const float PLAYER_LEFTGUN_LOCAL_X = -4.0f;
static const float PLAYER_LEFTGUN_LOCAL_Y = 8.0f;
static const float PLAYER_RIGHTGUN_LOCAL_X = 4.0f;
static const float PLAYER_RIGHTGUN_LOCAL_Y = 8.0f;
static const float EXPLOSION_LOCAL_X = 0.0f;
static const float EXPLOSION_LOCAL_Y = 3.0f;


static const float CARGO_X = 0.0f;
static const float CARGO_Y = -5.0f;
static const float CARGODROPS_X = 0.0f;
static const float CARGODROPS_Y = -12.0f;    // additional offset on top of the CARGO offset
static const float CARGODOWN1_VEL_X = 0.0f;
static const float CARGODOWN1_VEL_Y = -100.0f;
static const float CARGODOWN2_VEL_X = 0.0f;
static const float CARGODOWN2_VEL_Y = -70.0f;

static const float SHADOW_X = 15.0f;
static const float SHADOW_Y = -15.0f;
static const float SHADOW_SCALE_X = 0.5f;
static const float SHADOW_SCALE_Y = 0.5f;

static const unsigned int INIT_KILLBULLETS_NUM = 0;

static const float CARGOCOLLECTEDEFFECT_DURATION = 0.5f;

// utilties
static const float CARGOMAGNET_BASICRADIUS = 30.0f;
static const float CARGOMAGNET_LARGERADIUS = 95.0f;
static const float PICKUPMAGNET_BASICRADIUS = 20.0f;
static const float TOURNEY_MUTEPLAYER_DURATION = 3.0f;
static const unsigned int TOURNEY_PICKUP_MULTIPLIER_STEPS = 3;
static const float TOURNEY_PICKUP_SPEEDUP_TIME = 5.0f;

#pragma mark -
#pragma mark Instance Methods
- (id) initAtPos:(CGPoint)givenPos 
   usingDelegate:(NSObject<PlayerInitProtocol>*)initDelegate
{
	if((self = [super init]))
	{
        _flyerType = FlyerTypePoglider;
        
        initPos = givenPos;
        _respawnPos = givenPos;
		pos = givenPos;
        prevPos = pos;
		vel = CGPointMake(0.0f, 0.0f);
        displacement = CGPointMake(0.0f, 0.0f);
        
        RenderBucketsManager* bucketsMgr = [RenderBucketsManager getInstance];
        renderBucketIndex = [bucketsMgr getIndexFromName:@"Player"];
        addonsBucketIndex = [bucketsMgr getIndexFromName:@"PlayerAddons"];
        shadowsBucketIndex = [bucketsMgr getIndexFromName:@"Shadows"];
		renderer = nil;
        _shadowName = nil;

        // pan variables
        panVec = CGPointMake(0.0f, 0.0f);
        panOrigin = CGPointMake(0.0f, 0.0f);
        isPanning = NO;
        isDisplaced = NO;
        _shouldDropBomb = NO;
        
        // weapons
        self.weapon = nil;
        self.magnetDistUpgrade = PICKUPMAGNET_BASICRADIUS;
        _cargoMagnetRadius = CARGOMAGNET_BASICRADIUS;
        
        if(initDelegate)
		{
			[initDelegate initPlayer:self];
		}
        
        doAutoFire = NO;
        triggeredAutoFire = NO;
        numKillBulletPacks = INIT_KILLBULLETS_NUM;
        killBulletsDuration = 5.0f;
        
        // health
        [self resetHealth];
        isAlive = NO;           // I am not alive until I get spawned
        
        cargosCountTowardsMultiplier = 0;
        [[GameManager getInstance] setCargosTowardsMultiplier:0];
        _cargosCountTowardsUpgrade = 0;
        
        _pickupTypename = nil;

        self.initPlayerStatus = nil;
        
    }
	return self;
}

- (void) dealloc
{
    self.pickupTypename = nil;
    self.shadowName = nil;
    self.initPlayerStatus = nil;
    self.weapon = nil;

    self.animController = nil;
    self.anim = nil;
	[renderer release];
	[super dealloc];
}

- (void) setRespawnPosToInitPos
{
    _respawnPos = initPos;
}

- (void) spawnWithPlayerStatus:(PlayerStatus *)playerStatus
{
    if(!isAlive)
    {
        self.initPlayerStatus = playerStatus;
        
        // health
        [self resetHealth];
        
        if(initPlayerStatus)
        {
            // restore from player status
            [self.weapon setCurLevel:[initPlayerStatus weaponGrade]];
        }
        else
        {
            // reset weapon back to basic
            [self.weapon resetWeaponLevel];
        }

        // weapons
        [self initWeapons];
        
        // add anim-controller for playback processing
        [[AnimProcessor getInstance] addController:animController];

        // queue any basic pickups triggered for this level
        [[GameManager getInstance] queueFromBasicPickups];
        
        shadow = [[[LevelManager getInstance] addonFactory] createAddonNamed:[self shadowName] atPos:CGPointMake(SHADOW_X, SHADOW_Y)];
        shadow.scale = CGPointMake(SHADOW_SCALE_X, SHADOW_SCALE_Y);
        
        cargosCountTowardsMultiplier = 0;
        [[GameManager getInstance] setCargosTowardsMultiplier:0];
        _cargosCountTowardsUpgrade = 0;
        
        Addon* pickedupEffect = [[[LevelManager getInstance] addonFactory] createAddonNamed:@"CargoPickedup" atPos:CGPointMake(0.0f, 0.0f)];
        self.cargoCollectedEffect = pickedupEffect;
        [pickedupEffect release];
                
        // collision
        //colAABB = CGRectMake(0.0f, 0.0f, 10.0f, 10.0f);
        
        // respawning book keeping
        pos = _respawnPos;
        isPanning = NO;
        isDisplaced = NO;
        [self startPanning];    // reset panOrigin to pos
        
        [[DynamicManager getInstance] addObject:self];
        [[CollisionManager getInstance] addCollisionDelegate:self toSetNamed:@"Player"];
        [shadow spawnOnParent:self];
        [cargoCollectedEffect spawnOnParent:self];
        [cargoCollectedEffect.anim playClipForward:YES];
        cargoCollectedEffectTimer = 0.0f;
        
        // make player immune to hits for a bit
        immunityTimer = IMMUNE_TIME_LIMIT;
        immunityAlpha = 0.0f;
        immunityAlphaVel = -1.0f;
        
        // tourney
        if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
        {
            _tourneyMutePlayer = [[[LevelManager getInstance] addonFactory] createAddonNamed:@"MutePlayer" atPos:CGPointMake(0.0f, 0.0f)];
            [_tourneyMutePlayer spawnOnParent:self];
            [_tourneyMutePlayer.anim playClipForward:YES];
            _mutePlayerTimer = 0.0f;
        }
        
        // flag that I am alive
        isAlive = YES;
    }
}

- (void) kill
{
    if(isAlive)
    {
        // flag that I am dead
        isAlive = NO;
        
        // set current pos.x as respawn pos.x so that the camera doesn't
        // snap to the center of the route
        _respawnPos.x = pos.x;
        _respawnPos.y = initPos.y;
        
        [cargoCollectedEffect kill];
        [shadow kill];
        [[CollisionManager getInstance] removeCollisionDelegate:self];
        [[DynamicManager getInstance] removeObject:self];
        
        [[AnimProcessor getInstance] removeController:animController];
        
        [self stopAutoFire];
        [shadow release];
        self.cargoCollectedEffect = nil;
        
        // tourney
        if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
        {
            [[TourneyManager getInstance] didKillPlayer];
            [_tourneyMutePlayer kill];
            _tourneyMutePlayer = nil;
        }

        [self.weapon removeAllShots];
        [self shutdownWeapons];
    }
}

- (void) incapacitate
{
    if(isAlive)
    {
        // play down effect
        // play hit explosion
        [EffectFactory effectNamed:@"FlyerHitExplosion" atPos:CGPointMake(pos.x, pos.y)];
        
        [self kill];
    }
}


- (BOOL) processRespawn:(NSTimeInterval)elapsed
{
    BOOL result = NO;
    if(isPlayerWaitingToRespawn)
    {
        if(0.0f < timeTillPlayerRespawn)
        {
            timeTillPlayerRespawn -= elapsed;
        }
        else
        {
            timeTillPlayerRespawn = 0.0f;
            isPlayerWaitingToRespawn = NO;
            result = YES;
        }
    }
    return result;
}

- (void) startAutoFire
{
    doAutoFire = YES;
    
    // play basic weapon fire sound
    [[SoundManager getInstance] startEffectClip:@"FlyerBasicWeapon"];
}

- (void) stopAutoFire
{
    // stop basic weapon fire sound
    [[SoundManager getInstance] stopEffectClip:@"FlyerBasicWeapon"];

    doAutoFire = NO;
}

- (void) triggerAutoFire
{
    triggeredAutoFire = YES;
    [self startAutoFire];
}

- (void) unTriggerAutoFire
{
    [self stopAutoFire];
    triggeredAutoFire = NO;
}

#pragma mark - tourney
- (void) tourneyMutePlayer
{
    _mutePlayerTimer = TOURNEY_MUTEPLAYER_DURATION;
    [self stopAutoFire];
}


#pragma mark - weapons


- (void) initWeapons
{    
    if(triggeredAutoFire)
    {
        [self startAutoFire];
    }
    [self resetKillAllBullets];
    [self resetUtilitiesToInitLevel];
    _shouldDropBomb = NO;
}

- (void) shutdownWeapons
{
    // do nothing
}

- (void) addDrawForWeapons
{ 
    [self.weapon addDraw];
}

- (void) updateWeapons:(NSTimeInterval)elapsed
{
    if((doAutoFire) && (!isPlayerWaitingToRespawn))
    {
        // fire secondary here instead of in autoFire because the valueSortedEnemies list in GameManager
        // gets reset after every updateWeapons call
        [self.weapon player:self fireSecondary:elapsed];
    }
    [self.weapon update:elapsed];
}

- (PlayerStatus*) exportPlayerStatus
{
    PlayerStatus* result = [[PlayerStatus alloc] init];
    result.health = health;
    result.numKillBulletPacks = numKillBulletPacks;
    result.weaponGrade = [self.weapon curLevel];
    result.cargoMagnetRadius = _cargoMagnetRadius;
    return result;
}

#pragma mark -
#pragma mark Controls
- (void) panWithTranslation:(CGPoint)translate
{
    panVec = translate;
    isPanning = YES;
    isDisplaced = NO;
}

- (void) startPanning
{
    panOrigin = pos;
}

- (void) displaceByVector:(CGPoint)vec
{
    isPanning = NO;
    displacement = vec;
    isDisplaced = YES;
}

#pragma mark -
#pragma mark Private methods
- (void) autoFire:(NSTimeInterval)elapsed
{
    if(!isPlayerWaitingToRespawn)
    {
        [self.weapon player:self firePrimary:elapsed];
    }
}


- (void) addToRenderBucket:(unsigned int)index atPos:(CGPoint)renderPos atAnimFrameIndex:(int)animFrameIndex
{
    SpriteInstance* instanceData = [[SpriteInstance alloc] init];
    
    // retrieve anim frame from the controller that corresponds to the current Hit frame
    // animHit tracks the Hit frame (for when the player gets hit)
    // anim is an array of controllers, each of which corresponds to an animHit frame

    // retrieve the last frame (TODO: remove the animHit dimension altogether and only have one linear controller)
    // we no longer have the shaky anim frames
    int curHitFrameIndex = [anim count] - 1;
    assert(curHitFrameIndex < [anim count]);
    
    AnimLinearController* curHitAnim = [anim objectAtIndex:curHitFrameIndex];
    AnimFrame* curFrame = [curHitAnim currentFrameAtIndex:animFrameIndex];
    
    float blinkAlpha = 1.0f;
    if(0.0f < immunityTimer)
    {
        blinkAlpha = immunityAlpha;
    }
    instanceData.alpha = blinkAlpha;
    instanceData.texture = [[curFrame texture] texName];
    instanceData.pos = renderPos;
    instanceData.texcoordScale = [curFrame scale];
    instanceData.texcoordTranslate = [curFrame translate];
	DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:renderer DrawData:instanceData];
	[[RenderBucketsManager getInstance] addCommand:cmd toBucket:index];
	[instanceData release];
    [cmd release];
}

- (void) resetHealth
{
    isPlayerWaitingToRespawn = NO;
    timeTillPlayerRespawn = 0.0f;
    immunityTimer = 0.0f;
    immunityAlpha = 0.0f;
    immunityAlphaVel = -1.0f;
    hasQueuedHealthPack = NO;
    
    if(initPlayerStatus)
    {
        // restore from player status
        health = [initPlayerStatus health];
    }
    else
    {
        health = [[PlayerInventory getInstance] curHealthSlots];
    }
    // inform stats manager
    [[StatsManager getInstance] updateHealth:health];
}

- (void) resetKillAllBullets
{
    if(initPlayerStatus)
    {
        // restore from player status
        numKillBulletPacks = [initPlayerStatus numKillBulletPacks];
    }
    else
    {
        numKillBulletPacks = [[PlayerInventory getInstance] curNumBombs];
        if((0 == [[StatsManager getInstance] continuesRemaining]) && (0 == numKillBulletPacks))
        {
            // if no continues left, reward player one more killbullets
            numKillBulletPacks = 1;
        }
    }
    [[StatsManager getInstance] updateNumKillBullets:numKillBulletPacks];
}

- (void) resetUtilitiesToInitLevel
{
    if(initPlayerStatus)
    {
        // restore from player status
        _cargoMagnetRadius = [initPlayerStatus cargoMagnetRadius];
    }
    else
    {
        _cargoMagnetRadius = CARGOMAGNET_BASICRADIUS;
        if([[PlayerInventory getInstance] hasCargoMagnet])
        {
            _cargoMagnetRadius = CARGOMAGNET_LARGERADIUS;
        }
    }
}

- (void) upgradeWeapon
{
    [self.weapon upgradeWeaponLevel];
    if([self.weapon isPrimaryAtMax])
    {
        [[AchievementsManager getInstance] maxMissilesCompleted];
        [[AchievementsManager getInstance] maxGunsCompleted];
    }
}

- (unsigned int) numUpgradesToDropWhenKilled
{
    unsigned int result = 0;
    if([self.weapon getResetLevel] < [self.weapon curLevel])
    {
        unsigned int numPickedUp = [self.weapon curLevel] - [self.weapon getResetLevel];
        unsigned int cap = 3;
        if(3 < [self.weapon getResetLevel])
        {
            cap = 1;
        }
        else if(1 < [self.weapon getResetLevel])
        {
            cap = 2;
        }
        if(numPickedUp > cap)
        {
            numPickedUp = cap;
        }
        result = numPickedUp;
    }
    return result;
}


#pragma mark -
#pragma mark DynamicProtocols
- (BOOL) isViewConstrained
{
    return YES;
}

- (void) addDraw
{
    int animFrameIndex = [animController currentFrameIndex];
    [self addToRenderBucket:renderBucketIndex atPos:pos atAnimFrameIndex:animFrameIndex];

    [shadow addDrawAsAddonAtAnimFrameIndex:animFrameIndex toBucketIndex:shadowsBucketIndex withAlpha:1.0f];
    
    if(cargoCollectedEffectTimer > 0.0f)
    {
        [cargoCollectedEffect addDrawAsAddonToBucketIndex:addonsBucketIndex];
    }
    if(_mutePlayerTimer > 0.0f)
    {
        [_tourneyMutePlayer addDrawAsAddonToBucketIndex:addonsBucketIndex];
    }
}


- (void) updateBehavior:(NSTimeInterval)elapsed
{
	CGPoint newPos = pos;
    
    // process sim
    if(isPanning)
    {
        prevPos = pos;
        newPos.x = panOrigin.x + panVec.x;
        newPos.y = panOrigin.y + panVec.y;
        isPanning = NO;        

        // process anim
        float diffX = newPos.x - pos.x;
        if(diffX < -0.1f)
        {
            [[self animController] targetRangeMin];
        }
        else if(0.1f < diffX)
        {
            [[self animController] targetRangeMax];
        }
    }
    else if(isDisplaced)
    {
        prevPos = pos;
        newPos.x = pos.x + displacement.x;
        newPos.y = pos.y + displacement.y;
        isDisplaced = NO;

        // process anim
        float diffX = newPos.x - pos.x;
        if(diffX < -0.1f)
        {
            [[self animController] targetRangeMin];
        }
        else if(0.1f < diffX)
        {
            [[self animController] targetRangeMax];
        }
    }
    else
    {
        [[self animController] targetRangeMedian];
    }
    
    // process health
    if(0.0f < immunityTimer)
    {
        immunityTimer -= elapsed;
        immunityAlpha += (elapsed * BLINKING_PERIOD * immunityAlphaVel);
        if((immunityAlphaVel > 0.0f) && (immunityAlpha >= 1.0f))
        {
            immunityAlphaVel = -1.0f;
            immunityAlpha = 1.0f;
        }
        else if((immunityAlphaVel < 0.0f) && (immunityAlpha <= 0.0f))
        {
            immunityAlphaVel = 1.0f;
            immunityAlpha = 0.0f;
        }
    }
    
    // commit new pos
    pos = newPos;
    
    if(doAutoFire)
    {
        [self autoFire:elapsed];
    }
    
    // drop bomb
    if(_shouldDropBomb)
    {
        [self dropBomb];
        _shouldDropBomb = NO;
        [GameManager getInstance].hasUsedLifeSaver = YES;    // if player has manually dropped a bomb, take away their lifesaver
    }
    
    // process effects timer
    if(cargoCollectedEffectTimer >= 0.0f)
    {
        cargoCollectedEffectTimer -= elapsed;
        if(cargoCollectedEffectTimer < 0.0f)
        {
            cargoCollectedEffectTimer = 0.0f;
        }
    }
    
    // process tourney mute player effects
    if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
    {
        if(_mutePlayerTimer > 0.0f)
        {
            _mutePlayerTimer -= elapsed;
            if(_mutePlayerTimer <= 0.0f)
            {
                [self startAutoFire];
                _mutePlayerTimer = 0.0f;
            }
        }
    }
}

- (void) dropBomb
{
    if(numKillBulletPacks)
    {
        [[SoundManager getInstance] playClip:@"KillBullets"];
        [[GameManager getInstance] killAllBullets:killBulletsDuration];
        [EffectFactory effectNamed:@"KillBullets" atPos:pos];
     
        --numKillBulletPacks;
        [[StatsManager getInstance] updateNumKillBullets:numKillBulletPacks];    
    }
}

- (void) updatePhysics:(NSTimeInterval)elapsed
{
}

- (void) updateCollision:(NSTimeInterval)elapsed
{
    
}

- (CGPoint) getPos
{
    return pos;
}

#pragma mark - ConstraintDelegate methods

- (void) setPosX:(float)newX
{
    pos.x = newX;
}

- (void) setPosY:(float)newY
{
    pos.y = newY;
}

- (void) setPos:(CGPoint)newPos
{
    pos = newPos;
}
- (void) setVel:(CGPoint)newVel
{
    vel = newVel;
}

#pragma mark -
#pragma mark CollisionDelegate
- (CGRect) getAABB
{
    CGRect result = CGRectMake(pos.x + colAABB.origin.x, pos.y + colAABB.origin.y, colAABB.size.width, colAABB.size.height);
    return result;
}

- (void) respondToCollisionFrom:(NSObject<CollisionDelegate>*)theOtherObject
{
    if([theOtherObject isMemberOfClass:[Loot class]])
    {
        // friendlys
        
        Loot* loot = (Loot*) theOtherObject;
        NSString* lootTypeName = [[loot behaviorDelegate] getTypeName];
        if([lootTypeName isEqualToString:@"HealthPack"])
        {
            // health pack
            if(health < [[PlayerInventory getInstance] curHealthSlots])
            {
                ++health;
                [[StatsManager getInstance] updateHealth:health];
            }
        }
        else if(([lootTypeName isEqualToString:@"DoubleBulletUpgrade"]) ||
                ([lootTypeName isEqualToString:@"LaserUpgrade"]) ||
                ([lootTypeName isEqualToString:@"BoomerangUpgrade"]))
        {
            [self upgradeWeapon];
        }
        else if([lootTypeName isEqualToString:@"KillAllBulletUpgrade"])
        {
            if(numKillBulletPacks < [[PlayerInventory getInstance] curBombSlots])
            {
                ++numKillBulletPacks;
                [[StatsManager getInstance] updateNumKillBullets:numKillBulletPacks];
            }
        }
        else if([[TourneyManager getInstance] isMultiplayerUtilPickup:lootTypeName])
        {
            [[TourneyManager getInstance] pushAttackForPickup:loot fromPos:pos];
        }
        else
        {
            // picked up cargo, switch ON the Cargo add-on
            ++cargosCountTowardsMultiplier;
            if(0 == (cargosCountTowardsMultiplier % NUM_CARGOS_PER_MULT))
            {
                [[StatsManager getInstance] incrementScoreMultiplier];
                cargosCountTowardsMultiplier = 0;
                [EffectFactory textEffectForMultiplier:[[StatsManager getInstance] sessionMultiplier] atPos:pos]; 
                
                // check and spawn tourney pickups
                if([[GameManager getInstance] gameMode] == GAMEMODE_TIMEBASED)
                {
                    unsigned int curSessionMult = [[StatsManager getInstance] sessionMultiplier];
                    if((0 < curSessionMult) && (0 == (curSessionMult % TOURNEY_PICKUP_MULTIPLIER_STEPS)))
                    {
                        [[TourneyManager getInstance] speedUpPickupsTimerBy:TOURNEY_PICKUP_SPEEDUP_TIME];
                    }
                }
            }
            [[GameManager getInstance] setCargosTowardsMultiplier:cargosCountTowardsMultiplier];

            ++_cargosCountTowardsUpgrade;
            if(0 == (_cargosCountTowardsUpgrade % [[GameManager getInstance] getUpgradeCargosCountForWeaponLevel:[self.weapon curLevel]]))
            {
                if([self pickupTypename])
                {
                    CGPoint lootPos = pos;
                    lootPos.y = [[GameManager getInstance] getPlayArea].size.height * 1.1f;
                    [LootFactory spawnDynamicLootFromKey:[self pickupTypename] atPos:lootPos];
                    _cargosCountTowardsUpgrade = 0;
                }
            }
            
            // credit player with cargo
            [[StatsManager getInstance] collectedCargo:1];
            
            // show cargo collected effect
            cargoCollectedEffectTimer = CARGOCOLLECTEDEFFECT_DURATION;
        }
        
        // play sound
        [[SoundManager getInstance] playClip:@"CargoCollected"];
        
        // credit the player with a collection point
        [[StatsManager getInstance] creditCollection:1];
    }
    else
    {
        // hostiles
        
        if((0.0f >= immunityTimer) && (![theOtherObject isFriendlyToPlayer]))
        {
            if(([theOtherObject isBullet]) && (1 >= health) && (0 < numKillBulletPacks) && (![[GameManager getInstance] hasUsedLifeSaver]))
            {
                // if hit by a bullet and about to die, drop a bomb to save myself
                // this is available only once per lifetime and only if player has not double-tapped a bomb before
                [self dropBomb];
                [GameManager getInstance].hasUsedLifeSaver = YES;
            }
            else if(1 < health)
            {
                // decrement health
                --health;
                
#if defined(DEBUG)
                if([[DebugOptions getInstance] isPlayerInvincible])
                {
                    // if invincible, add health back
                    health = [[PlayerInventory getInstance] curHealthSlots];
                }
#endif
                
                [[StatsManager getInstance] updateHealth:health];
                if((1 == health) && (!hasQueuedHealthPack))
                {
                    // if player is almost dead, queue a health pack
                    [[GameManager getInstance] queuePickupNamed:@"HealthPack" number:1]; 
                    
                    // only allow one health pack per lifetime
                    hasQueuedHealthPack = YES;
                }
                
                
                // make player immune to hits for a bit
                immunityTimer = IMMUNE_TIME_LIMIT;
                immunityAlpha = 0.0f;
                immunityAlphaVel = -1.0f;

                // reset multiplier
                cargosCountTowardsMultiplier = 0;
                [[StatsManager getInstance] dropScoreMultiplier];
                [[GameManager getInstance] setCargosTowardsMultiplier:0];
                
                // play sound
                [[SoundManager getInstance] playClip:@"PeterExplosion"];
                
                // play hit explosion
                [EffectFactory effectNamed:@"FlyerHitExplosion" atPos:CGPointMake(pos.x + EXPLOSION_LOCAL_X, pos.y + EXPLOSION_LOCAL_Y)];
            }
            else
            {  
                --health;
                [[StatsManager getInstance] updateHealth:health];
                
                if(GAMEMODE_TIMEBASED == [[GameManager getInstance] gameMode])
                {
                    // in time-based mode, all enemies are incapacitated upon player kill
                    [EffectFactory effectNamed:@"KillBullets" atPos:pos];
                }
                // play sound
                [[SoundManager getInstance] playClip:@"PeterExplosion"];
                
                // clear player status because after legitly getting killed, all attributes start fresh
                self.initPlayerStatus = nil;
                
                // reset multiplier
                cargosCountTowardsMultiplier = 0;
                [[StatsManager getInstance] dropScoreMultiplier];
                [[GameManager getInstance] setCargosTowardsMultiplier:0];
                [[GameManager getInstance] killPlayer];
            }
        }
    }
}

- (BOOL) isCollisionOn
{
    return YES;
}

- (BOOL) isBullet
{
    return NO;
}

- (BOOL) isFriendlyToPlayer
{
    BOOL result = YES;
    return result;
}


#pragma mark -
#pragma mark AddonDelegate
- (CGPoint) worldPosition
{
    return pos;
}

- (float) rotation
{
    return 0.0f;
}
@end
