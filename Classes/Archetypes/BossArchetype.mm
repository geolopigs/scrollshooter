//
//  BossArchetype.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/22/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "BossArchetype.h"
#import "BossSpawner.h"
#import "DynLineSpawner.h"
#import "Sprite.h"
#import "Enemy.h"
#import "AnimClipData.h"
#import "AnimClip.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "EffectFactory.h"
#import "Effect.h"
#import "FiringPath.h"
#import "GameManager.h"
#import "GameObjectSizes.h"
#import "SineWeaver.h"
#import "AddonData.h"
#import "BoarSolo.h"
#import "TurretBasic.h"
#import "TurretDouble.h"
#import "Enemy.h"
#import "EnemyFactory.h"
#import "Loot.h"
#import "LootFactory.h"
#import "EffectFactory.h"
#import "BossWeapon.h"
#import "SoundManager.h"
#import "RenderBucketsManager.h"
#import "Addon.h"
#import "AddonFactory.h"
#import "AchievementsManager.h"
#include "MathUtils.h"

enum BehaviorStates
{
    BEHAVIORSTATE_INTRO = 0,
    BEHAVIORSTATE_CRUISING,
    BEHAVIORSTATE_LEAVING,
    BEHAVIORSTATE_RETIRING,
    BEHAVIORSTATE_DESTROYED,        // special-case state for final boss that is static (like the LandingPad)
    
    BEHAVIORSTATE_NUM
};

static const NSString* ANIMKEY_INTRO = @"intro";
static const NSString* ANIMKEY_PRIMARY = @"pr";
static const float SPAWNEFFECTADDON_ENEMYHIDDENDELAY = 0.75f;
static const float BOSSFIXTURE_SPAWNEFFECT_HIDDENDELAY = 1.0f;
static const float BOSSFIXTURE_SPAWNEFFECT_SCALE = 1.5f;
static const float BOSSFIXTURE_HIDDENDELAY = 1.5f;

@implementation BossContext

@synthesize enemyLayers;
@synthesize attachedEnemies;
@synthesize timeTillFire;
@synthesize behaviorState;
@synthesize weaverX;
@synthesize weaverY;
@synthesize initPos;
@synthesize cruisingTimer;
@synthesize curWeaponLayer;
@synthesize timeTillNextLayerFire;
@synthesize isNextLayerWaiting;
@synthesize bossWeapon;
@synthesize collisionOn;
@synthesize burningEffectActivated;
@synthesize curAnimState;
@synthesize spawnAddons;
@synthesize bossAddons = _bossAddons;
@synthesize bossActivated = _bossActivated;

@synthesize dynamicsAddonsIndex;
@synthesize spawnEffectBucketIndex;
@synthesize timeBetweenShots;
@synthesize shotSpeed;
@synthesize introVel;
@synthesize introDoneBotLeft;
@synthesize introDoneTopRight;
@synthesize cruiseBoxBotLeft;
@synthesize cruiseBoxTopRight;
@synthesize colAreaBotLeft;
@synthesize colAreaTopRight;
@synthesize hasCruiseBox;
@synthesize addonData;
@synthesize cruisingTimeout;
@synthesize exitVel;
@synthesize cruisingVel;
@synthesize health;
@synthesize numCargos;
@synthesize isCollidable;
@synthesize numWeaponLayers;
@synthesize triggerContext;
@synthesize boarTriggerContext;
@synthesize singleTriggerContext;
@synthesize doubleTriggerContext;
@synthesize unblockScrollCamName;
@synthesize hasDestroyedState;
@synthesize allLayers;
@synthesize bossFixtureClipnames = _bossFixtureClipnames;
@synthesize bossActiveClipnames = _bossActiveClipnames;
@synthesize colOrigin = _colOrigin;
@synthesize bossWeaponEarlyActivation = _bossWeaponEarlyActivation;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.enemyLayers = [NSMutableArray array];
        self.attachedEnemies = [NSMutableArray array];
        behaviorState = BEHAVIORSTATE_INTRO;
        self.weaverX = nil;
        self.weaverY = nil;
        curWeaponLayer = 0;
        timeTillNextLayerFire = 0.0f;
        isNextLayerWaiting = NO;
        self.bossWeapon = [NSMutableArray array];
        collisionOn = NO;
        burningEffectActivated = NO;
        self.curAnimState = nil;
        self.spawnAddons = [NSMutableArray array];
        self.bossAddons = [NSMutableArray array];
        _bossActivated = NO;
        
        // default config params
        introDoneBotLeft = CGPointMake(0.0f, 0.0f);
        introDoneTopRight = CGPointMake(1.0f, 1.0f);
        cruiseBoxBotLeft = CGPointMake(-1000.0f, -1000.0f);
        cruiseBoxTopRight = CGPointMake(3000.0f, 3000.0f);
        colAreaBotLeft = CGPointMake(0.0f, 0.0f);
        colAreaTopRight = CGPointMake(1.0f, 1.0f);
        hasCruiseBox = NO;
        cruisingTimeout = 3600.0f;
        exitVel = CGPointMake(20.0f, 10.0f);
        health = 10;
        numCargos = 0;
        introVel = CGPointMake(0.0f, -1.0f);
        cruisingVel = CGPointMake(0.0f, 0.0f);
        isCollidable = YES;
        self.triggerContext = nil;
        self.boarTriggerContext = nil;
        self.singleTriggerContext = nil;
        self.doubleTriggerContext = nil;
        self.unblockScrollCamName = nil;
        hasDestroyedState = NO;
        allLayers = NO;
        self.bossFixtureClipnames = [NSMutableArray array];
        self.bossActiveClipnames = [NSMutableArray array];
        _colOrigin = CGPointMake(0.0f, 0.0f);
        _bossWeaponEarlyActivation = NO;
    }
    return self;
}

- (void) dealloc
{
    self.bossActiveClipnames = nil;
    self.bossFixtureClipnames = nil;
    self.unblockScrollCamName = nil;
    self.doubleTriggerContext = nil;
    self.singleTriggerContext = nil;
    self.boarTriggerContext = nil;
    self.triggerContext = nil;
    self.bossAddons = nil;
    self.spawnAddons = nil;
    self.curAnimState = nil;
    self.addonData = nil;
    self.bossWeapon = nil;
    self.weaverY = nil;
    self.weaverX = nil;
    self.attachedEnemies = nil;
    self.enemyLayers = nil;
    [super dealloc];
}

- (BOOL) areAttachedEnemiesIncapacitated
{
    BOOL result = YES;
    unsigned int numAttachedEnemies = [attachedEnemies count];
    unsigned int index = 0;
    while(index < numAttachedEnemies)
    {
        Enemy* cur = [attachedEnemies objectAtIndex:index];
        if(![cur incapacitated])
        {
            result = NO;
            break;
        }
        ++index;
    } 
    return result;
}

- (unsigned int) numAttachedEnemiesAlive
{
    unsigned int num = 0;
    unsigned int numAttachedEnemies = [attachedEnemies count];
    unsigned int index = 0;
    while(index < numAttachedEnemies)
    {
        Enemy* cur = [attachedEnemies objectAtIndex:index];
        if(![cur incapacitated])
        {
            ++num;
        }        
        ++index;
    }
    return num;
}

- (unsigned int) numAliveInLayer:(unsigned int)layerIndex
{
    unsigned int num = 0;
    if(layerIndex < [enemyLayers count])
    {
        NSMutableArray* curLayer = [enemyLayers objectAtIndex:layerIndex];
        unsigned int enemyIndex = 0;
        while(enemyIndex < [curLayer count])
        {
            Enemy* cur = [curLayer objectAtIndex:enemyIndex];
            if(![cur incapacitated])
            {
                ++num;
            }
            ++enemyIndex;
        }        
    }
    return num;
}

- (BOOL) hasNextWeaponLayer
{
    BOOL result = NO;
    if((curWeaponLayer+1) < numWeaponLayers)
    {
        result = YES;
    }
    return result;
}

- (BOOL) isFinalLayer
{
    BOOL result = NO;
    if((curWeaponLayer+1) == numWeaponLayers)
    {
        result = YES;
    }
    return result;
}

@end

@interface BossArchetype (PrivateMethods)
- (Enemy*) placeEnemyWithIndex:(unsigned int)index 
             behaviorContext:(id)behaviorContext
                 forTypename:(NSString*)name 
                forGroupName:(NSString*)groupName
                    onParent:(Enemy*)parentEnemy
                 readyToFire:(BOOL)canFire;
- (Enemy*) placeBoarSoloWithIndex:(unsigned int)index 
               behaviorContext:(id)behaviorContext
                   forTypename:(NSString*)name 
                  forGroupName:(NSString*)groupName
                      onParent:(Enemy*)parentEnemy
                   readyToFire:(BOOL)canFire
                      animType:(unsigned int)animType;
- (void) enemy:(Enemy*)givenEnemy placeGunsForWeaponLayer:(unsigned int)layerIndex;
- (void) spawnLayer0ForEnemy:(Enemy*)givenEnemy;
- (void) enemy:(Enemy*)enemy createSpawnEffectAddonAtPos:(CGPoint)pos withScale:(CGPoint)scale withStartDelay:(float)startDelay;
- (void) enemy:(Enemy*)enemy createBossAddon:(NSString*)clipname atPos:(CGPoint)pos withDelay:(float)delay;
- (void) placeBossFixtures:(NSMutableArray*)clipnames onEnemy:(Enemy*)enemy spawnEffect:(BOOL)doSpawnEffect;
- (void) checkBlimpAchievement;
@end

@implementation BossArchetype
@synthesize typeName;
@synthesize sizeName;
@synthesize clipName;
@synthesize addonsName;
@synthesize destructionEffectName;
@synthesize destructionAddonName;
@synthesize soundClipName;
@synthesize introClipName;
@synthesize spawnAddonName;

- (id) initWithTypeName:(NSString*)givenName 
               sizeName:(NSString*)givenSizeName 
               clipName:(NSString*)givenClipName 
             addonsName:(NSString *)givenAddonsName
  destructionEffectName:(NSString *)givenDestructionEffectName
          soundClipName:(NSString*)givenSoundClipName
{
    self = [super init];
    if(self)
    {
        self.typeName = givenName;
        self.sizeName = givenSizeName;
        self.clipName = givenClipName;
        self.addonsName = givenAddonsName;
        self.destructionEffectName = givenDestructionEffectName;
        self.destructionAddonName = nil;
        self.soundClipName = givenSoundClipName;
        self.introClipName = nil;
        self.spawnAddonName = nil;
    }
    return self;
}

- (id) initWithTypeName:(NSString*)givenName 
               sizeName:(NSString*)givenSizeName 
               clipName:(NSString*)givenClipName 
             addonsName:(NSString*)givenAddonsName
  destructionEffectName:(NSString*)givenDestructionEffectName
   destructionAddonName:(NSString*)givenDestructionAddonName
          soundClipName:(NSString*)givenSoundClipName
          introClipName:(NSString*)givenIntroClipName
         spawnAddonName:(NSString*)givenSpawnAddonName
{
    self = [super init];
    if(self)
    {
        self.typeName = givenName;
        self.sizeName = givenSizeName;
        self.clipName = givenClipName;
        self.addonsName = givenAddonsName;
        self.destructionEffectName = givenDestructionEffectName;
        self.destructionAddonName = givenDestructionAddonName;
        self.soundClipName = givenSoundClipName;
        self.introClipName = givenIntroClipName;
        self.spawnAddonName = givenSpawnAddonName;
    }
    return self;
}



- (void) dealloc
{
    self.introClipName = nil;
    self.soundClipName = nil;
    self.destructionAddonName = nil;
    self.destructionEffectName = nil;
    self.addonsName = nil;
    self.clipName = nil;
    self.sizeName = nil;
    self.typeName = nil;
    [super dealloc];
}


#pragma mark - private methods
- (Enemy*) placeEnemyWithIndex:(unsigned int)index 
                       behaviorContext:(id)behaviorContext
                   forTypename:(NSString*)name 
                forGroupName:(NSString*)groupName
                      onParent:(Enemy*)parentEnemy 
                 readyToFire:(BOOL)canFire
{
    CGSize parentRenderSize = [[parentEnemy renderer] size];
    BossContext* parentContext = [parentEnemy behaviorContext];

    // NOTE: this enemy lives in layer-space just like its parent
    // no need to rotate init pos here because addon inherits its parent's rotate
    CGPoint offset = [[parentContext addonData] getOffsetAtIndex:index forGroup:groupName];
    CGPoint newPos = CGPointMake((offset.x * parentRenderSize.width),
                                 (offset.y * parentRenderSize.height));
    
    Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:name AtPos:newPos];
    newEnemy.renderBucketIndex = [parentContext dynamicsAddonsIndex];
    newEnemy.behaviorContext = behaviorContext;
    
    // attach myself as parent
    newEnemy.parentEnemy = parentEnemy;
    newEnemy.parentDelegate = self;
        
    // set weapon
    newEnemy.readyToFire = canFire;
    
    // add it to spawnedEnemies
    [parentContext.attachedEnemies addObject:newEnemy];
    [newEnemy spawn];
    [newEnemy release];
    
    // play the generic spawn effect
    if([self spawnAddonName])
    {
        // play the effect as an Addon
        [self enemy:parentEnemy createSpawnEffectAddonAtPos:newPos withScale:CGPointMake(1.0f,1.0f) withStartDelay:0.0f];
        
        // spawn-effect-addon guys need to be hidden for a bit (until effect is fully visible)
        newEnemy.hiddenTimer = SPAWNEFFECTADDON_ENEMYHIDDENDELAY;
    }
    else
    {
        CGPoint parentPos = [parentEnemy pos];
        CGAffineTransform t = CGAffineTransformMakeRotation([parentEnemy rotate]);
        CGPoint effectOffset = CGPointApplyAffineTransform(newPos, t);
        CGPoint effectPos = CGPointMake(effectOffset.x + parentPos.x, effectOffset.y + parentPos.y);
        [EffectFactory effectNamed:@"SpawnGeneric" atPos:effectPos];
    }    
    return newEnemy;
}

- (Enemy*) placeBoarSoloWithIndex:(unsigned int)index 
                  behaviorContext:(id)behaviorContext
                      forTypename:(NSString*)name 
                     forGroupName:(NSString*)groupName
                         onParent:(Enemy*)parentEnemy
                      readyToFire:(BOOL)canFire
                         animType:(unsigned int)animType
{
    CGSize parentRenderSize = [[parentEnemy renderer] size];
    BossContext* parentContext = [parentEnemy behaviorContext];
    
    // NOTE: this enemy lives in layer-space just like its parent
    // no need to rotate init pos here because addon inherits its parent's rotate
    CGPoint offset = [[parentContext addonData] getOffsetAtIndex:index forGroup:groupName];
    CGPoint newPos = CGPointMake((offset.x * parentRenderSize.width),
                                 (offset.y * parentRenderSize.height));
    
    Enemy* newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:name AtPos:newPos];
    newEnemy.renderBucketIndex = [parentContext dynamicsAddonsIndex];
    newEnemy.behaviorContext = behaviorContext;
    
    // attach myself as parent
    newEnemy.parentEnemy = parentEnemy;
    newEnemy.parentDelegate = self;
    
    // set weapon
    newEnemy.readyToFire = canFire;
    
    // create gun
    [BoarSolo enemy:newEnemy createGunAddonInBucket:[parentContext dynamicsAddonsIndex]];
    
    // replace it with the given animType
    [BoarSolo enemy:newEnemy replaceAnimWithType:animType];
    
    
    
    // add it to spawnedEnemies
    [parentContext.attachedEnemies addObject:newEnemy];
    [newEnemy spawn];
    [newEnemy release];
    
    // play the generic spawn effect if not AllLayers
    if(![parentContext allLayers])
    {        
        if([self spawnAddonName])
        {
            // play the effect as an Addon
            [self enemy:parentEnemy createSpawnEffectAddonAtPos:newPos withScale:CGPointMake(1.0f,1.0f) withStartDelay:0.0f];

            // spawn-effect-addon guys need to be hidden for a bit (until effect is fully visible)
            newEnemy.hiddenTimer = SPAWNEFFECTADDON_ENEMYHIDDENDELAY;
        }
        else
        {
            CGPoint parentPos = [parentEnemy pos];
            CGAffineTransform t = CGAffineTransformMakeRotation([parentEnemy rotate]);
            CGPoint effectOffset = CGPointApplyAffineTransform(newPos, t);
            CGPoint effectPos = CGPointMake(effectOffset.x + parentPos.x, effectOffset.y + parentPos.y);
            [EffectFactory effectNamed:@"SpawnGeneric" atPos:effectPos];            
        }
    }    
    return newEnemy;    
}

- (void) spawnLayer0ForEnemy:(Enemy *)givenEnemy
{
    BossContext* myContext = [givenEnemy behaviorContext];
    myContext.curWeaponLayer = 0;
    [self enemy:givenEnemy placeGunsForWeaponLayer:0];
    if([myContext allLayers])
    {        
        unsigned int layerIndex = 1;
        while(layerIndex < [myContext numWeaponLayers])
        {
            [self enemy:givenEnemy placeGunsForWeaponLayer:layerIndex];
            ++layerIndex;
        }
    }    
}

- (void) enemy:(Enemy*)enemy createSpawnEffectAddonAtPos:(CGPoint)pos withScale:(CGPoint)scale withStartDelay:(float)startDelay
{
    if([self spawnAddonName])
    {
        BossContext* myContext = [enemy behaviorContext];
        Addon* effectAddon = [[[LevelManager getInstance] addonFactory] createAddonNamed:spawnAddonName atPos:pos];
        effectAddon.renderBucket = [myContext spawnEffectBucketIndex];
        effectAddon.ownsBucket = YES;
        effectAddon.scale = scale;
        if(0.0f < startDelay)
        {
            // with startDelay, Addon behavior update will start the anim at the end of the delay; 
            // so, no need to explicitly playClipForward here
            effectAddon.startDelay = startDelay;
        }
        else
        {
            [effectAddon.anim playClipForward:YES];
        }
        [effectAddon spawnOnParent:enemy];
        [enemy.effectAddons addObject:effectAddon];
        
        // register effect-addon with myContext so that it can be released when the effect anim is done
        [myContext.spawnAddons addObject:effectAddon];
        [effectAddon release];
    }
}

- (void) enemy:(Enemy*)enemy createBossAddon:(NSString*)clipname atPos:(CGPoint)pos withDelay:(float)delay
{
    BossContext* myContext = [enemy behaviorContext];
    Addon* effectAddon = [[[LevelManager getInstance] addonFactory] createAddonNamed:clipname atPos:pos];
    effectAddon.renderBucket = [myContext dynamicsAddonsIndex]; // place this in the same layer as weapons
    effectAddon.ownsBucket = YES;
    if(0.0f < delay)
    {
        // with startDelay, Addon behavior update will start the anim at the end of the delay; 
        // so, no need to explicitly playClipForward here
        effectAddon.startDelay = delay;
    }
    else
    {
        [effectAddon.anim playClipRandomForward:YES];
    }
    [effectAddon spawnOnParent:enemy];
    [enemy.effectAddons addObject:effectAddon];
    
    // register effect-addon with myContext so that it can be released when the effect anim is done
    [myContext.bossAddons addObject:effectAddon];
    [effectAddon release];
}

- (void) placeBossFixtures:(NSMutableArray*)clipnames onEnemy:(Enemy *)enemy spawnEffect:(BOOL)doSpawnEffect
{
    BossContext* myContext = [enemy behaviorContext];

    // if fixtures already in place, clear them out first
    if([myContext.bossAddons count])
    {
        for(Addon* cur in [myContext bossAddons])
        {
            [enemy.effectAddons removeObject:cur];
            [cur kill];
        }
        [myContext.bossAddons removeAllObjects];        
    }
    
    // place fixtures if clips available
    {
        unsigned int weaponIndex = 0;
        for(BossWeapon* cur in [myContext bossWeapon])
        {
            unsigned int fixtureClipIndex = weaponIndex;
            if(fixtureClipIndex >= [clipnames count])
            {
                fixtureClipIndex = 0;
            }
            NSString* curFixtureClip = [clipnames objectAtIndex:fixtureClipIndex];

            if(doSpawnEffect)
            {
                // show spawn effect and then the fixture
                [self enemy:enemy createSpawnEffectAddonAtPos:[cur localPos] 
                  withScale:CGPointMake(BOSSFIXTURE_SPAWNEFFECT_SCALE,BOSSFIXTURE_SPAWNEFFECT_SCALE) 
             withStartDelay:BOSSFIXTURE_SPAWNEFFECT_HIDDENDELAY];
                [self enemy:enemy createBossAddon:curFixtureClip atPos:[cur localPos] withDelay:BOSSFIXTURE_HIDDENDELAY];
            }
            else
            {
                [self enemy:enemy createBossAddon:curFixtureClip atPos:[cur localPos] withDelay:0.0f];                
            }
            ++weaponIndex;
        }
    } 
}

// called when incapacitated
- (void) checkBlimpAchievement
{
    if(([typeName isEqualToString:@"MidBlimp0"]) ||
       ([typeName isEqualToString:@"LargeBlimp"]) ||
       ([typeName isEqualToString:@"LargeBlimpTurrets"]) ||
       ([typeName isEqualToString:@"LargeBlimpBSD"]))
       
    {
        // only consider the Boss blimps
        [[AchievementsManager getInstance] blimpKilled];
    }
    else if([typeName isEqualToString:@"BoarPumpkinBlimp"])
    {
        // pumpkin boss
        [[AchievementsManager getInstance] pumpkinKilled];
    }
}


#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:sizeName];
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:sizeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize colSize:colSize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
    
    // anim
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    AnimClipData* clipData = [animData getClipForName:clipName];
    AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
    [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_PRIMARY];
    givenEnemy.curAnimClip = newClip;
    [newClip release];

    if([self introClipName])
    {
        clipData = [animData getClipForName:introClipName];
        newClip = [[AnimClip alloc] initWithClipData:clipData];
        [givenEnemy.animClipRegistry setObject:newClip forKey:ANIMKEY_INTRO];
        [newClip release];
    }
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(NSObject<EnemySpawnerContextDelegate>*)givenSpawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];

    // init delegate
    givenEnemy.spawnedDelegate = self;  
    
    // init the enemy's context
    BossContext* newContext = [[BossContext alloc] init];
    if([givenSpawnerContext isMemberOfClass:[BossSpawnerContext class]])
    {
        BossSpawnerContext* spawnerContext = (BossSpawnerContext*)givenSpawnerContext;
        newContext.dynamicsAddonsIndex = [spawnerContext dynamicsAddonsIndex];
        newContext.spawnEffectBucketIndex = [spawnerContext dynamicsAddonsIndex];
        givenEnemy.renderBucketShadowsIndex = [spawnerContext dynamicsShadowsIndex];
        givenEnemy.renderBucketIndex = [spawnerContext dynamicsBucketIndex];
        givenEnemy.renderBucketAddonsIndex = [newContext dynamicsAddonsIndex];
    }
    else if([givenSpawnerContext isMemberOfClass:[DynLineSpawnerContext class]])
    {
        newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"BigAddons"];
        newContext.spawnEffectBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"BigAddons2"];
        givenEnemy.renderBucketShadowsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Shadows"];
        givenEnemy.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"BigDynamics"];
        givenEnemy.renderBucketAddonsIndex = [newContext dynamicsAddonsIndex];
    }
    
    newContext.behaviorState = BEHAVIORSTATE_INTRO;
    newContext.addonData = [[LevelManager getInstance] getAddonDataForName:addonsName];
    newContext.numWeaponLayers = [newContext.addonData numWeaponLayers];
    
    // init from trigger context
    CGRect playArea = [[GameManager getInstance] getPlayArea];
    NSDictionary* triggerContext = [givenSpawnerContext spawnerTriggerContext];
    if(triggerContext)
    {
        float introSpeed = [[triggerContext objectForKey:@"introSpeed"] floatValue];
        float introDir = [[triggerContext objectForKey:@"introDir"] floatValue] * M_PI;
        newContext.introVel = radiansToVector(CGPointMake(0.0f, -1.0f), introDir, introSpeed);

        NSNumber* faceDirNumber = [triggerContext objectForKey:@"faceDir"];
        if(faceDirNumber)
        {
            givenEnemy.rotate = [faceDirNumber floatValue] * M_PI;
        }
        NSNumber* cruisingDirNumber = [triggerContext objectForKey:@"cruisingDir"];
        NSNumber* cruisingSpeedNumber = [triggerContext objectForKey:@"cruisingSpeed"];
        if(cruisingDirNumber && cruisingSpeedNumber)
        {
            float cruisingDir = [cruisingDirNumber floatValue] * M_PI;
            float cruisingSpeed = [cruisingSpeedNumber floatValue];
            newContext.cruisingVel = radiansToVector(CGPointMake(0.0f, -1.0f), cruisingDir, cruisingSpeed);
        }
        
        float doneX = [[triggerContext objectForKey:@"introDoneX"] floatValue];
        float doneY = [[triggerContext objectForKey:@"introDoneY"] floatValue];
        float doneW = [[triggerContext objectForKey:@"introDoneW"] floatValue];
        float doneH = [[triggerContext objectForKey:@"introDoneH"] floatValue];
        newContext.introDoneBotLeft = CGPointMake((doneX * playArea.size.width) + playArea.origin.x,
                                                 (doneY * playArea.size.height) + playArea.origin.y);
        newContext.introDoneTopRight = CGPointMake((doneW * playArea.size.width) + newContext.introDoneBotLeft.x,
                                                  (doneH * playArea.size.height) + newContext.introDoneBotLeft.y);
        NSNumber* cruiseX = [triggerContext objectForKey:@"cruiseBoxX"];
        NSNumber* cruiseY = [triggerContext objectForKey:@"cruiseBoxY"];
        NSNumber* cruiseW = [triggerContext objectForKey:@"cruiseBoxW"];
        NSNumber* cruiseH = [triggerContext objectForKey:@"cruiseBoxH"];
        if(cruiseX && cruiseY && cruiseW && cruiseH)
        {   
            newContext.hasCruiseBox = YES;
            newContext.cruiseBoxBotLeft = CGPointMake(([cruiseX floatValue] * playArea.size.width) + playArea.origin.x,
                                                      ([cruiseY floatValue] * playArea.size.height) + playArea.origin.y);
            newContext.cruiseBoxTopRight = CGPointMake(([cruiseW floatValue] * playArea.size.width) + newContext.cruiseBoxBotLeft.x,
                                                       ([cruiseH floatValue] * playArea.size.height) + newContext.cruiseBoxBotLeft.y);
        }
        
        NSNumber* colAreaX = [triggerContext objectForKey:@"colAreaX"];
        NSNumber* colAreaY = [triggerContext objectForKey:@"colAreaY"];
        NSNumber* colAreaW = [triggerContext objectForKey:@"colAreaW"];
        NSNumber* colAreaH = [triggerContext objectForKey:@"colAreaH"];
        if(colAreaX && colAreaY && colAreaW && colAreaH)
        {
            newContext.colAreaBotLeft = CGPointMake(([colAreaX floatValue] * playArea.size.width) + playArea.origin.x,
                                                      ([colAreaY floatValue] * playArea.size.height) + playArea.origin.y);
            newContext.colAreaTopRight = CGPointMake(([colAreaW floatValue] * playArea.size.width) + newContext.colAreaBotLeft.x,
                                                       ([colAreaH floatValue] * playArea.size.height) + newContext.colAreaBotLeft.y);            
        }
        
        float wVel = [[triggerContext objectForKey:@"weaveXVel"] floatValue];
        float wRange = [[triggerContext objectForKey:@"weaveXRange"] floatValue];
        SineWeaver* newWeaverX = [[SineWeaver alloc] initWithRange:wRange vel:wVel];
        newContext.weaverX = newWeaverX;
        [newWeaverX release];
        wVel = [[triggerContext objectForKey:@"weaveYVel"] floatValue];
        wRange = [[triggerContext objectForKey:@"weaveYRange"] floatValue];
        SineWeaver* newWeaverY = [[SineWeaver alloc] initWithRange:wRange vel:wVel];
        newContext.weaverY = newWeaverY;
        [newWeaverY release];
        newContext.timeBetweenShots = 1.0f / [[triggerContext objectForKey:@"shotFreq"] floatValue];
        newContext.shotSpeed = [[triggerContext objectForKey:@"shotSpeed"] floatValue];
        newContext.cruisingTimeout = [[triggerContext objectForKey:@"timeout"] floatValue];
        
        float exitSpeed = [[triggerContext objectForKey:@"exitSpeed"] floatValue];
        float exitDir = [[triggerContext objectForKey:@"exitDir"] floatValue] * M_PI;
        newContext.exitVel = radiansToVector(CGPointMake(0.0f, -1.0f), exitDir, exitSpeed);
        
        newContext.health = [[triggerContext objectForKey:@"health"] intValue];
        newContext.numCargos = [[triggerContext objectForKey:@"cargos"] unsignedIntValue];
        newContext.isCollidable = [[triggerContext objectForKey:@"isCollidable"] boolValue];
        
        newContext.boarTriggerContext = [triggerContext objectForKey:@"boarSpec"];
        newContext.singleTriggerContext = [triggerContext objectForKey:@"turretSingleSpec"];
        newContext.doubleTriggerContext = [triggerContext objectForKey:@"turretDoubleSpec"];
        newContext.unblockScrollCamName = [triggerContext objectForKey:@"unblockScroll"];

        newContext.bossFixtureClipnames = [triggerContext objectForKey:@"bossWeaponIdleClips"];
        newContext.bossActiveClipnames = [triggerContext objectForKey:@"bossWeaponActiveClips"];
        NSDictionary* bossWeaponConfig = [triggerContext objectForKey:@"bossWeapon"];
        if(bossWeaponConfig)
        {
            AddonData* data = [[LevelManager getInstance] getAddonDataForName:addonsName];
            unsigned int num = [data getNumForGroup:@"BossWeapon"];
            if(num > 0)
            {
                // init BossWeapon based on placement in the BossWeapon layer
                unsigned int weaponIndex = 0;
                CGSize renderSize = [[givenEnemy renderer] size];
                while(weaponIndex < num)
                {
                    BossWeapon* newWeapon = [[BossWeapon alloc] initFromConfig:bossWeaponConfig];
                    CGPoint offset = [data getOffsetAtIndex:weaponIndex forGroup:@"BossWeapon"];
                    CGPoint newPos = CGPointMake((offset.x * renderSize.width),
                                                 (offset.y * renderSize.height));
                    newPos.x += newWeapon.localPos.x;
                    newPos.y += newWeapon.localPos.y;
                    newWeapon.localPos = newPos;
                    
                    // randomly offset the timing a bit
                    newWeapon.timeTillFire += ((1.0f + randomFrac()) * (weaponIndex * [newWeapon shotDelay]));
                    [newContext.bossWeapon addObject:newWeapon];
                    [newWeapon release];
                    ++weaponIndex;
                }
            }
            else
            {
                BossWeapon* newWeapon = [[BossWeapon alloc] initFromConfig:bossWeaponConfig];
                [newContext.bossWeapon addObject:newWeapon];
                [newWeapon release];
                
            }
        }
        newContext.triggerContext = triggerContext;
        
        NSNumber* contextHasDestroyed = [triggerContext objectForKey:@"destroyedState"];
        if(contextHasDestroyed)
        {
            newContext.hasDestroyedState = [contextHasDestroyed boolValue];
        }
        NSNumber* contextAllLayers = [triggerContext objectForKey:@"allLayers"];
        if(contextAllLayers)
        {
            newContext.allLayers = [contextAllLayers boolValue];
        }
        
        NSNumber* contextAABBOffsetX = [triggerContext objectForKey:@"colOriginX"];
        NSNumber* contextAABBOffsetY = [triggerContext objectForKey:@"colOriginY"];
        if(contextAABBOffsetX && contextAABBOffsetY)
        {
            newContext.colOrigin = CGPointMake([contextAABBOffsetX floatValue], [contextAABBOffsetY floatValue]);
        }
        
        NSNumber* contextEarlyActivation = [triggerContext objectForKey:@"bossWeaponEarly"];
        if(contextEarlyActivation)
        {
            newContext.bossWeaponEarlyActivation = [contextEarlyActivation boolValue];
        }
    }
    
    // init colAABB
    CGRect colAABB = [givenEnemy colAABB];
    colAABB.origin.x += [newContext colOrigin].x;
    colAABB.origin.y += [newContext colOrigin].y;
    givenEnemy.colAABB = colAABB;
    
    // init velocity
    givenEnemy.vel = [newContext introVel];
    
    // context dependent runtime params
    givenEnemy.health = newContext.health;
    givenEnemy.behaviorContext = newContext;
    [newContext release];
}



#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    if(![givenEnemy incapacitated])
    {
        BossContext* myContext = [givenEnemy behaviorContext];
        
        float newPosX = [givenEnemy pos].x + (elapsed * givenEnemy.vel.x);
        float newPosY = [givenEnemy pos].y + (elapsed * givenEnemy.vel.y);
        
        if(![myContext collisionOn])
        {
            CGPoint bl = [myContext colAreaBotLeft];
            CGPoint tr = [myContext colAreaTopRight];
            if((newPosX >= bl.x) && (newPosX <= tr.x) &&
               (newPosY >= bl.y) && (newPosY <= tr.y))
            {
                myContext.collisionOn = YES;
                
                // ok to fire
                givenEnemy.readyToFire = YES;
                if([myContext allLayers])
                {
                    // allLayers mode, only go through and active layer0
                    for(Enemy* cur in [[myContext enemyLayers] objectAtIndex:0])
                    {
                        if(![cur incapacitated])
                        {
                            cur.readyToFire = YES;
                        }
                    }
                }
                else
                {
                    for(Enemy* cur in myContext.attachedEnemies)
                    {
                        cur.readyToFire = YES;
                    }
                }
            }
        }
        
        if(BEHAVIORSTATE_INTRO == myContext.behaviorState)
        {
            BOOL introIsDone = NO;
            if(([myContext curAnimState]) && (myContext.curAnimState == ANIMKEY_INTRO))
            {
                if([givenEnemy.curAnimClip playbackState] == ANIMCLIP_STATE_DONE)
                {
                    introIsDone = YES;
                    
                    // switch to primary anim
                    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_PRIMARY];
                    [givenEnemy.curAnimClip playClipForward:YES];
                    myContext.curAnimState = ANIMKEY_PRIMARY;
                    
                    // also spawn the first set of gunners (this was not done at preSpawn for bosses with INTRO)
                    [self spawnLayer0ForEnemy:givenEnemy];
                }
            }
            else
            {
                CGPoint bl = myContext.introDoneBotLeft;
                CGPoint tr = myContext.introDoneTopRight;
                if((newPosX >= bl.x) && (newPosX <= tr.x) &&
                   (newPosY >= bl.y) && (newPosY <= tr.y))
                {
                    introIsDone = YES;
                }
                
            }
            
            if(introIsDone)
            {
                // when ship is fully in view, go to cruising
                myContext.behaviorState = BEHAVIORSTATE_CRUISING;
                [myContext.weaverX reset];
                myContext.weaverX.base = newPosX;
                [myContext.weaverY reset];
                myContext.weaverY.base = newPosY;
                myContext.initPos = CGPointMake(newPosX, newPosY);
                myContext.cruisingTimer = myContext.cruisingTimeout;
                
                givenEnemy.vel = [myContext cruisingVel];
                
                // ok to fire
                if(![myContext collisionOn])
                {
                    myContext.collisionOn = YES;
                    givenEnemy.readyToFire = YES;
                    if([myContext allLayers])
                    {
                        // allLayers mode, only go through and active layer0
                        for(Enemy* cur in [[myContext enemyLayers] objectAtIndex:0])
                        {
                            if(![cur incapacitated])
                            {
                                cur.readyToFire = YES;
                            }
                        }
                    }
                    else if([myContext.spawnAddons count])
                    {
                        // if spawn effect Addons, delay readyToFire
                        myContext.timeTillNextLayerFire = 2.0f;
                        myContext.isNextLayerWaiting = YES;
                    }
                    else
                    {
                        // otherwise, ask the attachedEnemies to fire away
                        for(Enemy* cur in myContext.attachedEnemies)
                        {
                            cur.readyToFire = YES;
                        }
                    }
                }
            }
        }
        else if(BEHAVIORSTATE_CRUISING == myContext.behaviorState)
        {
            myContext.weaverX.base += (elapsed * givenEnemy.vel.x);
            myContext.weaverY.base += (elapsed * givenEnemy.vel.y);
            
            newPosX = [myContext.weaverX update:elapsed];
            newPosY = [myContext.weaverY update:elapsed];
            
            myContext.cruisingTimer -= elapsed;
            
            if(0.0f > myContext.cruisingTimer)
            {
                givenEnemy.vel = myContext.exitVel;
                myContext.behaviorState = BEHAVIORSTATE_LEAVING;
            }
            else if(([myContext allLayers]) && ([myContext hasNextWeaponLayer]))
            { 
                // all layers spawned, activate one layer at a time
                unsigned int curIndex = [myContext curWeaponLayer];
                if([myContext numAliveInLayer:curIndex] <= ([[myContext.enemyLayers objectAtIndex:curIndex] count]/3))
                {
                    // activate the next layer when less than a fourth of current layer is alive
                    unsigned int nextLayer = [myContext curWeaponLayer] + 1;
                    for(Enemy* cur in [[myContext enemyLayers] objectAtIndex:nextLayer])
                    {
                        if(![cur incapacitated])
                        {
                            cur.readyToFire = YES;
                        }
                    }
                    myContext.curWeaponLayer = nextLayer;
                }
            }
            else if([myContext isNextLayerWaiting])
            {
                // check of activation of the next layer
                myContext.timeTillNextLayerFire -= elapsed;
                if(0.0f > [myContext timeTillNextLayerFire])
                {
                    for(Enemy* cur in myContext.attachedEnemies)
                    {
                        if(![cur incapacitated])
                        {
                            cur.readyToFire = YES;
                        }
                    }
                    myContext.timeTillNextLayerFire = 0.0f;
                    myContext.isNextLayerWaiting = NO;
                }
            }
            else 
            {
                unsigned int curIndex = [myContext curWeaponLayer];
                unsigned int curCount = 1;
                if(((curIndex+1) < [myContext.enemyLayers count]) &&
                   (curCount < [[myContext.enemyLayers objectAtIndex:curIndex] count] / 3))
                {
                    curCount = [[myContext.enemyLayers objectAtIndex:curIndex] count] / 3;
                }
                else if((curIndex+1) == [myContext.enemyLayers count])
                {
                    // if final layer, need to kill them all
                    curCount = 0;
                }
                if([myContext numAliveInLayer:curIndex] <= curCount)
                {
                    // check for spawning of the next layer
                    if([myContext hasNextWeaponLayer])
                    {
                        // if more weapon layers, go to next layer
                        unsigned int nextLayer = [myContext curWeaponLayer] + 1;
                        assert(nextLayer < [myContext numWeaponLayers]);
                        [self enemy:givenEnemy placeGunsForWeaponLayer:nextLayer];
                        myContext.curWeaponLayer = nextLayer;
                        myContext.timeTillNextLayerFire = 2.0f;
                        myContext.isNextLayerWaiting = YES;
                    }
                    else if((([myContext numCargos] == 0) || (![myContext isCollidable])) &&
                            ([myContext areAttachedEnemiesIncapacitated]))
                    {
                        // if this boss is not collidable or has no cargo, it leaves after its last attached enemy is gone
                        myContext.cruisingTimer = 0.0f;  
                        
                        if([myContext hasDestroyedState])
                        {
                            // if it has destroyed state, go to destroyed state
                            myContext.behaviorState = BEHAVIORSTATE_DESTROYED;
                        }
                    }
                    else if([myContext bossWeapon])
                    {
                        BOOL activateBossNow = [myContext bossWeaponEarlyActivation];
                        if(!activateBossNow)
                        {
                            activateBossNow = [myContext areAttachedEnemiesIncapacitated];
                        }
                        if(activateBossNow)
                        {
                            // if no more attachedenemies, activate boss-weapon
                            if(![myContext bossActivated])
                            {
                                if([myContext bossActiveClipnames])
                                {
                                    [self placeBossFixtures:[myContext bossActiveClipnames] onEnemy:givenEnemy spawnEffect:NO];
                                }
                                myContext.bossActivated = YES;
                            }
                            
                            // fire boss weapon
                            for(BossWeapon* cur in [myContext bossWeapon])
                            {
                                [cur enemyFire:givenEnemy elapsed:elapsed];
                            }
                        }
                    }
                }
            }
            
            // clamp position within cruiseBox if one is given
            if([myContext hasCruiseBox])
            {
                CGPoint bl = myContext.cruiseBoxBotLeft;
                CGPoint tr = myContext.cruiseBoxTopRight;
                if(newPosX < bl.x)
                {
                    newPosX = bl.x;
                }
                else if(newPosX > tr.x)
                {
                    newPosX = tr.x;
                }
                if(newPosY < bl.y)
                {
                    newPosY = bl.y;
                }
                else if(newPosY > tr.y)
                {
                    newPosY = tr.y;
                }
            }
        }
        else if(BEHAVIORSTATE_LEAVING == myContext.behaviorState)
        {
            CGRect playArea = [[GameManager getInstance] getPlayArea];
            float buffer = 0.5f;
            CGPoint retireBl = CGPointMake((-buffer * playArea.size.width) + playArea.origin.x,
                                           (-buffer * playArea.size.height) + playArea.origin.y);
            CGPoint retireTr = CGPointMake(((1.0f + buffer) * playArea.size.width) + playArea.origin.x,
                                           ((1.0f + buffer) * playArea.size.height) + playArea.origin.y);
            if((newPosX < retireBl.x) || (newPosX > retireTr.x) ||
               (newPosY < retireBl.y) || (newPosY > retireTr.y))
            {
                givenEnemy.willRetire = YES;
                myContext.behaviorState = BEHAVIORSTATE_RETIRING;
            }        
        }
        else if((BEHAVIORSTATE_DESTROYED == [myContext behaviorState]) ||
                (BEHAVIORSTATE_RETIRING == [myContext behaviorState]))
        {
            // continuously unblock camera because game-manager may add a block after this boss has been defeated
            if([myContext unblockScrollCamName])
            {
                [[GameManager getInstance] unblockScrollCamFor:[myContext unblockScrollCamName]];
            }        
        }
        givenEnemy.pos = CGPointMake(newPosX, newPosY);
        
        // clear out any spawn-effect addons whose anim is done
        NSMutableArray* trashArray = [NSMutableArray array];
        for(Addon* cur in [myContext spawnAddons])
        {
            if(ANIMCLIP_STATE_DONE == [[cur anim] playbackState])
            {
                [trashArray addObject:cur];
                [givenEnemy.effectAddons removeObject:cur];
                [cur kill];
            }
        }
        for(Addon* cur in trashArray)
        {
            [myContext.spawnAddons removeObject:cur];
        }
        [trashArray removeAllObjects];
    }
}

- (NSString*) getEnemyTypeName
{
    return typeName;
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    BossContext* myContext = [givenEnemy behaviorContext];
    for(Enemy* cur in [myContext attachedEnemies])
    {
        [cur killAllBullets];
    }
}

#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    BossContext* myContext = [enemy behaviorContext];
    
    if(([myContext areAttachedEnemiesIncapacitated]) || ([myContext bossActivated]))
    {
        // only takes damage if all its subcomponents are dead
        enemy.health--;
        
        // play bullet hit effect
        CGRect myAABB = [enemy getAABB];
        CGPoint hitPos = CGPointMake(givenAABB.origin.x + (0.5f * givenAABB.size.width),
                                     myAABB.origin.y);
        [EffectFactory effectNamed:@"BulletHit" atPos:hitPos];
        
        if((![myContext burningEffectActivated]) && ([self destructionAddonName]))
        {
            Addon* fireAddon = [[[LevelManager getInstance] addonFactory] createAddonNamed:destructionAddonName atPos:CGPointMake(0.0f, 0.0f)];
            fireAddon.renderBucket = [myContext dynamicsAddonsIndex];
            fireAddon.ownsBucket = YES;
            [fireAddon.anim playClipForward:YES];
            [fireAddon spawnOnParent:enemy];
            [enemy.effectAddons addObject:fireAddon];
            [fireAddon release];
            myContext.burningEffectActivated = YES;
        }
    }
}

- (BOOL) isPlayerCollidable
{
    return YES;
}

- (BOOL) isPlayerWeapon
{
    return NO;
}

- (BOOL) isCollidable
{
    return YES;
}

- (BOOL) isCollisionOnFor:(Enemy *)enemy
{
    BOOL result = NO;
    
    BossContext* myContext = [enemy behaviorContext];
    if(([myContext isCollidable]) &&
       (([myContext areAttachedEnemiesIncapacitated]) || ([myContext bossActivated])))
    {
            result = YES;
    }
    return result;
}


#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    // stop sound effect clip if this enemy type has one
    if(soundClipName)
    {
        [[SoundManager getInstance] stopEffectClip:soundClipName];
    }
    
    if(![givenEnemy incapacitated])
    {
        // enemy was killed from retirement (not incapacitated)
        // need to remove its attached enemies
        BossContext* myContext = [givenEnemy behaviorContext];
        unsigned int numAttachedEnemies = [myContext.attachedEnemies count];
        unsigned int index = 0;
        while(index < numAttachedEnemies)
        {
            Enemy* cur = [myContext.attachedEnemies objectAtIndex:index];
            
            // remove parent delegate first so that the kill function won't try to also remove itself from the attachedEnemies
            cur.parentDelegate = nil;
            [cur kill];
            ++index;
        }
        // clear out local enemy arrays
        [myContext.attachedEnemies removeAllObjects];
        [myContext.enemyLayers removeAllObjects];
        
        // clean out bossWeapons
        for(BossWeapon* cur in [myContext bossWeapon])
        {
            [cur killAllComponents];
        }
        [myContext.bossWeapon removeAllObjects];
        
        // clear out spawn-effect addons
        [myContext.spawnAddons removeAllObjects];
        [myContext.bossAddons removeAllObjects];
    }
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    // play sound
    [[SoundManager getInstance] playClip:@"BlimpExplosion"];

    // play destruction effect
    if([self destructionEffectName])
    {
        [EffectFactory effectNamed:[self destructionEffectName] atPos:givenEnemy.pos rotated:[givenEnemy rotate]];
    }
    
    BossContext* myContext = [givenEnemy behaviorContext];
    unsigned int numAttachedEnemies = [myContext.attachedEnemies count];
    unsigned int index = 0;
    while(index < numAttachedEnemies)
    {
        Enemy* cur = [myContext.attachedEnemies objectAtIndex:index];

        // remove parent delegate first so that the kill function won't try to also remove itself from the attachedEnemies
        cur.parentDelegate = nil;
        [cur incapAndKillWithPoints:showPoints];
        ++index;
    }
    
    // clear out local enemy arrays
    [myContext.attachedEnemies removeAllObjects];
    [myContext.enemyLayers removeAllObjects];

    // clean out bossWeapons
    for(BossWeapon* cur in [myContext bossWeapon])
    {
        [cur killAllComponents];
    }
    [myContext.bossWeapon removeAllObjects];

    // clear out spawn-effect addons
    [myContext.spawnAddons removeAllObjects];
    [myContext.bossAddons removeAllObjects];

    // drop loots
    if([[GameManager getInstance] shouldReleasePickups])
    {   
        CGPoint enemyPos = [givenEnemy pos];
        unsigned int numCargos = [myContext numCargos];
        unsigned int index = 0;
        float initSwingVelFactor = 0.7f;
        float initSwingVelFactorIncr = -1.0f;
        const float CARGO_OFFSETX = 20.0f;
        const float CARGO_OFFSETY = 20.0f;
        while(index < numCargos)
        {
            CGPoint dropPos = CGPointMake(enemyPos.x + (randomFrac() * CARGO_OFFSETX) - (CARGO_OFFSETX * 0.5f),
                                          enemyPos.y + (randomFrac() * CARGO_OFFSETY) - (CARGO_OFFSETY * 0.5f));
            // dequeue missile-upgrade first before dequeueing other pickups
            NSString* pickupType = [[GameManager getInstance] dequeueNextMissilePack];
            if(!pickupType)
            {
                pickupType = [[GameManager getInstance] dequeueNextPickupName];
            }
            if(pickupType)
            {
                Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:pickupType atPos:dropPos 
                                                                                 isDynamics:YES 
                                                                        groundedBucketIndex:0 
                                                                              layerDistance:0.0f];
                [newLoot spawn];
                [newLoot release];
            }
            else
            {
                [LootFactory spawnCargoPackAtPos:dropPos 
                              initSwingVelFactor:initSwingVelFactor 
                                        introVel:CGPointMake(0.5f * initSwingVelFactorIncr, 1.5f)];
                initSwingVelFactor += initSwingVelFactorIncr;
                if(-1.0f >= initSwingVelFactor)
                {
                    initSwingVelFactorIncr *= -1.0f;
                }
            }
            ++index;
        }
    }
    
    // show points gained
    if(showPoints)
    {
        CGPoint effectPos = [givenEnemy pos];
        [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                               atPos:effectPos 
                             withVel:CGPointMake(0.0f, 7.0f) 
                               scale:CGPointMake(0.3f, 0.3f)
                            duration:1.5f 
                           colorRed:1 green:1 blue:1 alpha:1];
    }
    
    // track achievements
    [self checkBlimpAchievement];
    
    // clean up config pointers
    myContext.triggerContext = nil;
    myContext.boarTriggerContext = nil;
    myContext.singleTriggerContext = nil;
    myContext.doubleTriggerContext = nil;

    // returns true for enemy to be killed immediately
    return YES;
}
#pragma mark - EnemySpawnedDelegate


- (void) enemy:(Enemy*)givenEnemy placeGunsForWeaponLayer:(unsigned int)layerIndex
{
    BossContext* myContext = [givenEnemy behaviorContext];
    assert(layerIndex < [[myContext enemyLayers] count]);
    NSMutableArray* curLayerArray = [[myContext enemyLayers] objectAtIndex:layerIndex];
    
    NSString* boarName = @"BoarSoloGun";
    NSString* boarGroupName = @"BoarSoloGun";
    NSString* boarSpecName = @"boarSpec";
    NSString* singleName = @"TurretSingle";
    NSString* singleGroupName = @"TurretSingle";
    NSString* singleSpecName = @"turretSingleSpec";
    NSString* doubleName = @"TurretDouble";
    NSString* doubleGroupName = @"TurretDouble";
    NSString* doubleSpecName = @"turretDoubleSpec";
    if(0 < layerIndex)
    {
        boarGroupName = [boarName stringByAppendingFormat:@"_%d",layerIndex];
        boarSpecName = [boarSpecName stringByAppendingFormat:@"_%d",layerIndex];
        singleGroupName = [singleName stringByAppendingFormat:@"_%d",layerIndex];
        singleSpecName = [singleSpecName stringByAppendingFormat:@"_%d",layerIndex];
        doubleGroupName = [doubleName stringByAppendingFormat:@"_%d",layerIndex];
        doubleSpecName = [doubleSpecName stringByAppendingFormat:@"_%d",layerIndex];
    }
    
    // Boar
    unsigned int num = [[myContext addonData] getNumForGroup:boarGroupName];
    unsigned int index = 0;
    while(index < num)
    {
        // init its context given the spawner's context
        BoarSoloContext* newContext = [[BoarSoloContext alloc] init];
        newContext.timeTillFire = 0.0f;
        newContext.idleTimer = 0.0f;
        newContext.idleDelay = 1.0f;
        newContext.hasCargo = YES;
        NSDictionary* boarSpec = [myContext.triggerContext objectForKey:boarSpecName];
        [newContext setupFromTriggerContext:boarSpec];
 
        // default on boss is Helmet
        unsigned int animType = BOARSOLO_ANIMTYPE_HELMET;
        if(boarSpec && (randomFrac() <= 0.5f))
        {
            // half prob replace it with the specified anim
            animType = [BoarSolo animTypeFromName:[boarSpec objectForKey:@"animType"]];
        }
        Enemy* newEnemy = [self placeBoarSoloWithIndex:index 
                                       behaviorContext:newContext
                                           forTypename:boarName 
                                          forGroupName:boarGroupName
                                              onParent:givenEnemy 
                                           readyToFire:NO
                                              animType:animType];
        
        
        // hide sub-enemies that are intended as firing points only
        if([newContext hidden])
        {
            newEnemy.hidden = YES;
        }
        newEnemy.health = [newContext initHealth];

        [curLayerArray addObject:newEnemy];
        [newContext release];
        
        ++index;
    }
    
    // Single
    num = [[myContext addonData] getNumForGroup:singleGroupName];
    index = 0;
    while(index < num)
    {
        // init its context given the spawner's context
        TurretBasicContext* newContext = [[TurretBasicContext alloc] init];
        newContext.timeTillFire = 0.0f;
        [newContext setupFromTriggerContext:[myContext.triggerContext objectForKey:singleSpecName]];
        Enemy* newEnemy = [self placeEnemyWithIndex:index 
                  behaviorContext:newContext
                      forTypename:@"TurretBasic" 
                     forGroupName:singleGroupName
                         onParent:givenEnemy 
                      readyToFire:NO];
        [curLayerArray addObject:newEnemy];

        [newContext release];        
        ++index;
    }
    
    // Double
    num = [[myContext addonData] getNumForGroup:doubleGroupName];
    index = 0;
    while(index < num)
    {
        // init its context given the spawner's context
        TurretDoubleContext* newContext = [[TurretDoubleContext alloc] init];
        newContext.timeTillFire = 0.0f;
        newContext.idleTimer = 0.0f;
        [newContext setupFromTriggerContext:[myContext.triggerContext objectForKey:doubleSpecName]];
        
        Enemy* newEnemy = [self placeEnemyWithIndex:index 
                                    behaviorContext:newContext
                                        forTypename:doubleName 
                                       forGroupName:doubleGroupName
                                           onParent:givenEnemy 
                                        readyToFire:NO];
        newEnemy.health = [newContext initHealth];
        [curLayerArray addObject:newEnemy];
        [newContext release];        
        ++index;
    }
}


- (void) preSpawn:(Enemy *)givenEnemy
{
    BossContext* myContext = [givenEnemy behaviorContext];
    
    // setup my weapons
    myContext.timeTillFire = 0.1f;
    
    // setup entrance
    myContext.behaviorState = BEHAVIORSTATE_INTRO;
    myContext.collisionOn = NO;

    // setup enemyLayers array to organize spawned enemies by layer
    unsigned int layerIndex = 0;
    while(layerIndex < [myContext numWeaponLayers])
    {
        NSMutableArray* newArray = [NSMutableArray array];
        [myContext.enemyLayers addObject:newArray];
        ++layerIndex;
    }
        
    // start sound effect clip if this enemy type has one
    if(soundClipName)
    {
        [[SoundManager getInstance] startEffectClip:soundClipName];
    }
    
    // start the current anim
    // if INTRO anim specified, play it first (spawn first set of enemies only after INTRO is done)
    // otherwise, go ahead and spawn the first set of enemies
    AnimClip* introClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_INTRO];
    if(introClip)
    {
        myContext.curAnimState = ANIMKEY_INTRO;
        givenEnemy.curAnimClip = introClip;
    }
    else
    {
        // spawn gunners
        [self spawnLayer0ForEnemy:givenEnemy];
    }
    [givenEnemy.curAnimClip playClipForward:YES];
    
    // place boss fixtures if any specified in the config
    if([myContext bossFixtureClipnames])
    {
        [self placeBossFixtures:[myContext bossFixtureClipnames] onEnemy:givenEnemy spawnEffect:YES];
    }
}


#pragma mark - EnemyParentDelegate
- (void) removeFromParent:(Enemy*)parent enemy:(Enemy*)givenEnemy
{
    BossContext* myContext = [parent behaviorContext];
    [myContext.attachedEnemies removeObject:givenEnemy];
}

@end
