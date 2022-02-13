//
//  Boss2.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/22/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "Boss2.h"
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
static const NSString* ANIMKEY_BASIC = @"basic";
static const float SPAWNEFFECTADDON_ENEMYHIDDENDELAY = 0.75f;
static const float BOSSFIXTURE_SPAWNEFFECT_HIDDENDELAY = 1.0f;
static const float BOSSFIXTURE_SPAWNEFFECT_SCALE = 1.5f;
static const float BOSSFIXTURE_HIDDENDELAY = 1.5f;

@implementation Boss2Context

// runtime
@synthesize enemyLayers = _enemyLayers;
@synthesize attachedEnemies = _attachedEnemies;
@synthesize timeTillFire = _timeTillFire;
@synthesize behaviorState = _behaviorState;
@synthesize weaverX = _weaverX;
@synthesize weaverY = _weaverY;
@synthesize initPos = _initPos;
@synthesize cruisingTimer = _cruisingTimer;
@synthesize curWeaponLayer = _curWeaponLayer;
@synthesize timeTillNextLayerFire = _timeTillNextLayerFire;
@synthesize isNextLayerWaiting = _isNextLayerWaiting;
@synthesize collisionOn = _collisionOn;
@synthesize curAnimState = _curAnimState;

// configs
@synthesize dynamicsAddonsIndex = _dynamicsAddonsIndex;
@synthesize spawnEffectBucketIndex = _spawnEffectBucketIndex;
@synthesize faceDir = _faceDir;
@synthesize timeBetweenShots = _timeBetweenShots;
@synthesize shotSpeed = _shotSpeed;
@synthesize introVel = _introVel;
@synthesize introDoneBotLeft = _introDoneBotLeft;
@synthesize introDoneTopRight = _introDoneTopRight;
@synthesize cruiseBoxBotLeft = _cruiseBoxBotLeft;
@synthesize cruiseBoxTopRight = _cruiseBoxTopRight;
@synthesize colAreaBotLeft = _colAreaBotLeft;
@synthesize colAreaTopRight = _colAreaTopRight;
@synthesize hasCruiseBox = _hasCruiseBox;
@synthesize addonData = _addonData;
@synthesize cruisingTimeout = _cruisingTimeout;
@synthesize exitVel = _exitVel;
@synthesize cruisingVel = _cruisingVel;
@synthesize health = _health;
@synthesize numCargos = _numCargos;
@synthesize isCollidable = _isCollidable;
@synthesize numWeaponLayers = _numWeaponLayers;
@synthesize triggerContext = _triggerContext;
@synthesize unblockScrollCamName = _unblockScrollCamName;
@synthesize colOrigin = _colOrigin;
@synthesize animStates = _animStates;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.enemyLayers = [NSMutableArray array];
        self.attachedEnemies = [NSMutableArray array];
        _behaviorState = BEHAVIORSTATE_INTRO;
        self.weaverX = nil;
        self.weaverY = nil;
        _timeTillNextLayerFire = 0.0f;
        _isNextLayerWaiting = NO;
        _collisionOn = NO;
        self.curAnimState = nil;

        // configs
        _faceDir = 0.0f;
        _introDoneBotLeft = CGPointMake(0.0f, 0.0f);
        _introDoneTopRight = CGPointMake(1.0f, 1.0f);
        _cruiseBoxBotLeft = CGPointMake(-1000.0f, -1000.0f);
        _cruiseBoxTopRight = CGPointMake(3000.0f, 3000.0f);
        _colAreaBotLeft = CGPointMake(0.0f, 0.0f);
        _colAreaTopRight = CGPointMake(1.0f, 1.0f);
        _hasCruiseBox = NO;
        _cruisingTimeout = 3600.0f;
        _exitVel = CGPointMake(20.0f, 10.0f);
        _health = 10.0f;
        _numCargos = 0;
        _introVel = CGPointMake(0.0f, -1.0f);
        _cruisingVel = CGPointMake(0.0f, 0.0f);
        _isCollidable = YES;
        self.triggerContext = nil;
        self.unblockScrollCamName = nil;
        _colOrigin = CGPointMake(0.0f, 0.0f);
        self.animStates = [NSMutableArray array];
    }
    return self;
}

- (void) dealloc
{
    self.animStates = nil;
    self.unblockScrollCamName = nil;
    self.triggerContext = nil;
    
    self.curAnimState = nil;
    self.addonData = nil;
    self.weaverY = nil;
    self.weaverX = nil;
    self.attachedEnemies = nil;
    self.enemyLayers = nil;
    [super dealloc];
}

- (void) setupFromContextDictionary:(NSDictionary*)triggerContext
{
    float introSpeed = [[triggerContext objectForKey:@"introSpeed"] floatValue];
    float introDir = [[triggerContext objectForKey:@"introDir"] floatValue] * M_PI;
    _introVel = radiansToVector(CGPointMake(0.0f, -1.0f), introDir, introSpeed);
    
    NSNumber* faceDirNumber = [triggerContext objectForKey:@"faceDir"];
    if(faceDirNumber)
    {
        _faceDir = [faceDirNumber floatValue] * M_PI;
    }
    NSNumber* cruisingDirNumber = [triggerContext objectForKey:@"cruisingDir"];
    NSNumber* cruisingSpeedNumber = [triggerContext objectForKey:@"cruisingSpeed"];
    if(cruisingDirNumber && cruisingSpeedNumber)
    {
        float cruisingDir = [cruisingDirNumber floatValue] * M_PI;
        float cruisingSpeed = [cruisingSpeedNumber floatValue];
        _cruisingVel = radiansToVector(CGPointMake(0.0f, -1.0f), cruisingDir, cruisingSpeed);
    }
    
    CGRect playArea = [[GameManager getInstance] getPlayArea];
    float doneX = [[triggerContext objectForKey:@"introDoneX"] floatValue];
    float doneY = [[triggerContext objectForKey:@"introDoneY"] floatValue];
    float doneW = [[triggerContext objectForKey:@"introDoneW"] floatValue];
    float doneH = [[triggerContext objectForKey:@"introDoneH"] floatValue];
    _introDoneBotLeft = CGPointMake((doneX * playArea.size.width) + playArea.origin.x,
                                              (doneY * playArea.size.height) + playArea.origin.y);
    _introDoneTopRight = CGPointMake((doneW * playArea.size.width) + _introDoneBotLeft.x,
                                               (doneH * playArea.size.height) + _introDoneBotLeft.y);
    NSNumber* cruiseX = [triggerContext objectForKey:@"cruiseBoxX"];
    NSNumber* cruiseY = [triggerContext objectForKey:@"cruiseBoxY"];
    NSNumber* cruiseW = [triggerContext objectForKey:@"cruiseBoxW"];
    NSNumber* cruiseH = [triggerContext objectForKey:@"cruiseBoxH"];
    if(cruiseX && cruiseY && cruiseW && cruiseH)
    {   
        _hasCruiseBox = YES;
        _cruiseBoxBotLeft = CGPointMake(([cruiseX floatValue] * playArea.size.width) + playArea.origin.x,
                                                  ([cruiseY floatValue] * playArea.size.height) + playArea.origin.y);
        _cruiseBoxTopRight = CGPointMake(([cruiseW floatValue] * playArea.size.width) + _cruiseBoxBotLeft.x,
                                                   ([cruiseH floatValue] * playArea.size.height) + _cruiseBoxBotLeft.y);
    }
    
    NSNumber* colAreaX = [triggerContext objectForKey:@"colAreaX"];
    NSNumber* colAreaY = [triggerContext objectForKey:@"colAreaY"];
    NSNumber* colAreaW = [triggerContext objectForKey:@"colAreaW"];
    NSNumber* colAreaH = [triggerContext objectForKey:@"colAreaH"];
    if(colAreaX && colAreaY && colAreaW && colAreaH)
    {
        _colAreaBotLeft = CGPointMake(([colAreaX floatValue] * playArea.size.width) + playArea.origin.x,
                                                ([colAreaY floatValue] * playArea.size.height) + playArea.origin.y);
        _colAreaTopRight = CGPointMake(([colAreaW floatValue] * playArea.size.width) + _colAreaBotLeft.x,
                                                 ([colAreaH floatValue] * playArea.size.height) + _colAreaBotLeft.y);            
    }
    
    float wVel = [[triggerContext objectForKey:@"weaveXVel"] floatValue];
    float wRange = [[triggerContext objectForKey:@"weaveXRange"] floatValue];
    SineWeaver* newWeaverX = [[SineWeaver alloc] initWithRange:wRange vel:wVel];
    self.weaverX = newWeaverX;
    [newWeaverX release];
    wVel = [[triggerContext objectForKey:@"weaveYVel"] floatValue];
    wRange = [[triggerContext objectForKey:@"weaveYRange"] floatValue];
    SineWeaver* newWeaverY = [[SineWeaver alloc] initWithRange:wRange vel:wVel];
    self.weaverY = newWeaverY;
    [newWeaverY release];
    _timeBetweenShots = 1.0f / [[triggerContext objectForKey:@"shotFreq"] floatValue];
   _shotSpeed = [[triggerContext objectForKey:@"shotSpeed"] floatValue];
    _cruisingTimeout = [[triggerContext objectForKey:@"timeout"] floatValue];
    
    float exitSpeed = [[triggerContext objectForKey:@"exitSpeed"] floatValue];
    float exitDir = [[triggerContext objectForKey:@"exitDir"] floatValue] * M_PI;
    _exitVel = radiansToVector(CGPointMake(0.0f, -1.0f), exitDir, exitSpeed);
    
    _health = [[triggerContext objectForKey:@"health"] unsignedIntValue];
    _numCargos = [[triggerContext objectForKey:@"cargos"] unsignedIntValue];
    _isCollidable = [[triggerContext objectForKey:@"isCollidable"] boolValue];
    
    self.unblockScrollCamName = [triggerContext objectForKey:@"unblockScroll"];
    
    self.triggerContext = triggerContext;
    
    NSNumber* contextAABBOffsetX = [triggerContext objectForKey:@"colOriginX"];
    NSNumber* contextAABBOffsetY = [triggerContext objectForKey:@"colOriginY"];
    if(contextAABBOffsetX && contextAABBOffsetY)
    {
        _colOrigin = CGPointMake([contextAABBOffsetX floatValue], [contextAABBOffsetY floatValue]);
    }    
    
    self.animStates = [triggerContext objectForKey:@"animStates"];
}


- (BOOL) areAttachedEnemiesIncapacitated
{
    BOOL result = YES;
    unsigned int numAttachedEnemies = [_attachedEnemies count];
    unsigned int index = 0;
    while(index < numAttachedEnemies)
    {
        Enemy* cur = [_attachedEnemies objectAtIndex:index];
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
    unsigned int numAttachedEnemies = [_attachedEnemies count];
    unsigned int index = 0;
    while(index < numAttachedEnemies)
    {
        Enemy* cur = [_attachedEnemies objectAtIndex:index];
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
    NSMutableArray* curLayer = [_enemyLayers objectAtIndex:layerIndex];
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
    return num;
}

- (BOOL) hasNextWeaponLayer
{
    BOOL result = NO;
    if((_curWeaponLayer+1) < _numWeaponLayers)
    {
        result = YES;
    }
    return result;
}

- (BOOL) isFinalLayer
{
    BOOL result = NO;
    if((_curWeaponLayer+1) == _numWeaponLayers)
    {
        result = YES;
    }
    return result;
}

@end

@interface Boss2 (PrivateMethods)
@end

@implementation Boss2
@synthesize typeName = _typeName;
@synthesize sizeName = _sizeName;
@synthesize addonsName = _addonsName;
@synthesize soundClipName = _soundClipName;

- (id) initWithTypeName:(NSString*)givenTypeName sizeName:(NSString*)givenSizeName addonsName:(NSString*)givenAddonsName
{
    self = [super init];
    if(self)
    {
        self.typeName = givenTypeName;
        self.sizeName = givenSizeName;
        self.addonsName = givenAddonsName;
        self.soundClipName = nil;
    }
    return self;
}


- (void) dealloc
{
    self.soundClipName = nil;
    self.addonsName = nil;
    self.sizeName = nil;
    self.typeName = nil;
    [super dealloc];
}


#pragma mark - private methods

#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:_sizeName];
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:_sizeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize colSize:colSize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
            
    // set collision AABB
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // install delegates
    givenEnemy.behaviorDelegate = self;
    givenEnemy.killedDelegate = self;
    givenEnemy.spawnedDelegate = self;  

    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}

- (void) initEnemy:(Enemy *)givenEnemy withSpawnerContext:(NSObject<EnemySpawnerContextDelegate>*)givenSpawnerContext
{
    // init the enemy itself
    [self initEnemy:givenEnemy];

    // init the enemy's context
    Boss2Context* newContext = [[Boss2Context alloc] init];
    newContext.dynamicsAddonsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"BigAddons"];
    newContext.spawnEffectBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"BigAddons2"];
    givenEnemy.renderBucketShadowsIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Shadows"];
    givenEnemy.renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"BigDynamics"];
    givenEnemy.renderBucketAddonsIndex = [newContext dynamicsAddonsIndex];
    
    newContext.behaviorState = BEHAVIORSTATE_INTRO;
    newContext.addonData = [[LevelManager getInstance] getAddonDataForName:_addonsName];
    newContext.numWeaponLayers = [newContext.addonData numWeaponLayers];
    
    // init from trigger context
    NSDictionary* triggerContext = [givenSpawnerContext spawnerTriggerContext];
    if(triggerContext)
    {
        [newContext setupFromContextDictionary:triggerContext];
    }

    // anim
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    for(NSString* curAnimState in [newContext animStates])
    {
        NSString* curAnimName = [[newContext animStates] objectForKey:curAnimState];
        AnimClipData* clipData = [animData getClipForName:curAnimName];
        AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
        [givenEnemy.animClipRegistry setObject:newClip forKey:curAnimState];
        [newClip release];
    }
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_BASIC];
    newContext.curAnimState = ANIMKEY_BASIC;

    // must have at least the BASIC animstate
    assert(givenEnemy.curAnimClip);

    // orientation
    givenEnemy.rotate = [newContext faceDir];

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
        Boss2Context* myContext = [givenEnemy behaviorContext];
        
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
                    
                    // switch to basic anim
                    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_BASIC];
                    [givenEnemy.curAnimClip playClipForward:YES];
                    myContext.curAnimState = ANIMKEY_BASIC;
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
                    
                    // also ask the attached enemies to fire
                    for(Enemy* cur in myContext.attachedEnemies)
                    {
                        cur.readyToFire = YES;
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
    }
}

- (NSString*) getEnemyTypeName
{
    return _typeName;
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    Boss2Context* myContext = [givenEnemy behaviorContext];
    for(Enemy* cur in [myContext attachedEnemies])
    {
        [cur killAllBullets];
    }
}

#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    Boss2Context* myContext = [enemy behaviorContext];
    
    if([myContext areAttachedEnemiesIncapacitated])
    {
        // only takes damage if all its subcomponents are dead
        enemy.health--;
        
        // play bullet hit effect
        CGPoint hitPos = CGPointMake(givenAABB.origin.x + (0.5f * givenAABB.size.width),
                                     givenAABB.origin.y + (0.5f * givenAABB.size.height));
        [EffectFactory effectNamed:@"BulletHit" atPos:hitPos];
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
    
    Boss2Context* myContext = [enemy behaviorContext];
    if(([myContext isCollidable]) &&
       ([myContext areAttachedEnemiesIncapacitated]))
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
    if(_soundClipName)
    {
        [[SoundManager getInstance] stopEffectClip:_soundClipName];
    }
    
    if(![givenEnemy incapacitated])
    {
        // enemy was killed from retirement (not incapacitated)
        // need to remove its attached enemies
        Boss2Context* myContext = [givenEnemy behaviorContext];
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
    }
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy
{
    // play sound
    [[SoundManager getInstance] playClip:@"BlimpExplosion"];

    Boss2Context* myContext = [givenEnemy behaviorContext];
    unsigned int numAttachedEnemies = [myContext.attachedEnemies count];
    unsigned int index = 0;
    while(index < numAttachedEnemies)
    {
        Enemy* cur = [myContext.attachedEnemies objectAtIndex:index];

        // remove parent delegate first so that the kill function won't try to also remove itself from the attachedEnemies
        cur.parentDelegate = nil;
        [cur incapAndKill];
        ++index;
    }
    
    // clear out local enemy arrays
    [myContext.attachedEnemies removeAllObjects];
    [myContext.enemyLayers removeAllObjects];

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
    CGPoint effectPos = [givenEnemy pos];
    [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                           atPos:effectPos 
                         withVel:CGPointMake(0.0f, 7.0f) 
                           scale:CGPointMake(0.3f, 0.3f)
                        duration:1.5f 
                       colorRGBA:1.0f :1.0f :1.0f :1.0f];

    
    // returns true for enemy to be killed immediately
    return YES;
}
#pragma mark - EnemySpawnedDelegate



- (void) preSpawn:(Enemy *)givenEnemy
{
    Boss2Context* myContext = [givenEnemy behaviorContext];
    
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
    if(_soundClipName)
    {
        [[SoundManager getInstance] startEffectClip:_soundClipName];
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
    [givenEnemy.curAnimClip playClipForward:YES];    
}


#pragma mark - EnemyParentDelegate
- (void) removeFromParent:(Enemy*)parent enemy:(Enemy*)givenEnemy
{
    Boss2Context* myContext = [parent behaviorContext];
    [myContext.attachedEnemies removeObject:givenEnemy];
}

@end
