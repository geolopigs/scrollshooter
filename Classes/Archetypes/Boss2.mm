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
#import "SpawnersData.h"
#import "BoarSolo.h"
#import "TurretBasic.h"
#import "TurretDouble.h"
#import "Enemy.h"
#import "EnemyFactory.h"
#import "EnemySpawner.h"
#import "SubSpawner.h"
#import "Loot.h"
#import "LootFactory.h"
#import "EffectFactory.h"
#import "BossWeapon.h"
#import "SoundManager.h"
#import "RenderBucketsManager.h"
#import "Addon.h"
#import "AddonFactory.h"
#import "BossEvent.h"
#import "AchievementsManager.h"
#include "MathUtils.h"

enum BehaviorStates
{
    BEHAVIORSTATE_INTRO = 0,
    BEHAVIORSTATE_CRUISING,
    BEHAVIORSTATE_FINALFIGHT,
    BEHAVIORSTATE_LEAVING,
    BEHAVIORSTATE_RETIRING,
    BEHAVIORSTATE_DESTROYED,        // special-case state for final boss that is static (like the LandingPad)
    
    BEHAVIORSTATE_NUM
};

// anim-states that Boss2 must have
static const NSString* ANIMKEY_INTRO = @"intro";
static const NSString* ANIMKEY_BASIC = @"basic";
static const NSString* ANIMKEY_DESTROYED = @"destroyed";

// effect-addons that Boss2 may have
static const NSString* EFFECTKEY_CRUISE = @"cruise";
static const NSString* EFFECTKEY_DESTROY = @"destroy";
static const NSString* EFFECTKEY_CRITICAL = @"critical";

// spawnerData file keyword
static NSString* const COMPONENTADDON_KEYWORD = @"_compAddons";

@interface Boss2Context (PrivateMethods)
- (void) setupTimelineFromConfig:(NSArray*)configArray;
@end

@implementation Boss2Context

// runtime
@synthesize subSpawners = _subSpawners;
@synthesize timeTillFire = _timeTillFire;
@synthesize behaviorState = _behaviorState;
@synthesize weaverX = _weaverX;
@synthesize weaverY = _weaverY;
@synthesize initPos = _initPos;
@synthesize cruisingTimer = _cruisingTimer;
@synthesize collisionOn = _collisionOn;
@synthesize curAnimState = _curAnimState;
@synthesize bossGroup = _bossGroup;
@synthesize curTimelineEvent = _curTimelineEvent;
@synthesize curTimelineTimer = _curTimelineTimer;
@synthesize destroyTimer = _destroyTimer;

// configs
@synthesize subSpawnerConfigs = _subSpawnerConfigs;
@synthesize dynamicsAddonsIndex = _dynamicsAddonsIndex;
@synthesize spawnEffectBucketIndex = _spawnEffectBucketIndex;
@synthesize faceDir = _faceDir;
@synthesize introVel = _introVel;
@synthesize introDoneBotLeft = _introDoneBotLeft;
@synthesize introDoneTopRight = _introDoneTopRight;
@synthesize cruiseBoxBotLeft = _cruiseBoxBotLeft;
@synthesize cruiseBoxTopRight = _cruiseBoxTopRight;
@synthesize colAreaBotLeft = _colAreaBotLeft;
@synthesize colAreaTopRight = _colAreaTopRight;
@synthesize hasCruiseBox = _hasCruiseBox;
@synthesize spawnersData = _spawnersData;
@synthesize cruisingTimeout = _cruisingTimeout;
@synthesize exitVel = _exitVel;
@synthesize cruisingSpeed = _cruisingSpeed;
@synthesize health = _health;
@synthesize numCargos = _numCargos;
@synthesize isCollidable = _isCollidable;
@synthesize unblockScrollCamName = _unblockScrollCamName;
@synthesize colOrigin = _colOrigin;
@synthesize timeline = _timeline;
@synthesize effectAddonsReg = _effectAddonsReg;
@synthesize destroyDelay = _destroyDelay;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.subSpawners = [NSMutableArray array];
        _behaviorState = BEHAVIORSTATE_INTRO;
        self.weaverX = nil;
        self.weaverY = nil;
        _collisionOn = NO;
        self.curAnimState = nil;
        _curTimelineEvent = 0;
        _curTimelineTimer = 0.0f;
        _destroyTimer = 0.0f;

        // configs
        self.subSpawnerConfigs = nil;
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
        _health = 10;
        _numCargos = 0;
        _introVel = CGPointMake(0.0f, -1.0f);
        _cruisingSpeed = 0.0f;
        _isCollidable = YES;
        self.unblockScrollCamName = nil;
        _colOrigin = CGPointMake(0.0f, 0.0f);
        self.bossGroup = nil;
        self.timeline = [NSMutableArray array];
        self.effectAddonsReg = [NSMutableDictionary dictionary];
        _destroyDelay = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    self.effectAddonsReg = nil;
    self.timeline = nil;
    self.bossGroup = nil;
    self.unblockScrollCamName = nil;
    self.subSpawnerConfigs = nil;
    
    self.curAnimState = nil;
    self.spawnersData = nil;
    self.weaverY = nil;
    self.weaverX = nil;
    self.subSpawners = nil;
    [super dealloc];
}

#pragma mark - private methods

// this method assumes that the SubSpawners have all been created
- (void) setupTimelineFromConfig:(NSArray*)configArray
{
    if(configArray)
    {
        
        for(NSDictionary* cur in configArray)
        {
            // create new BossEvent
            BossEvent* newEvent = [[BossEvent alloc] init];

            NSNumber* posX = [cur objectForKey:@"posX"];
            NSNumber* posY = [cur objectForKey:@"posY"];
            NSNumber* posW = [cur objectForKey:@"posW"];
            NSNumber* posH = [cur objectForKey:@"posH"];
            NSNumber* targetX = [cur objectForKey:@"targetX"];
            NSNumber* targetY = [cur objectForKey:@"targetY"];
            if(posX && posY && posW && posH && targetX && targetY)
            {
                CGPoint targetPoint = CGPointMake([targetX floatValue], [targetY floatValue]);
                CGRect targetRect = CGRectMake([posX floatValue], [posY floatValue],
                                               [posW floatValue], [posH floatValue]);
                [newEvent setFlag:BOSSEVENT_FLAG_TARGETPOS];
                [newEvent setTargetPos:targetPoint doneRect:targetRect];
            }
            NSNumber* delay = [cur objectForKey:@"delay"];
            if(delay)
            {
                [newEvent setFlag:BOSSEVENT_FLAG_DELAY];
                newEvent.delay = [delay floatValue];
            }
            
            NSString* spawnerGroupName = [cur objectForKey:@"spawner"];
            if(spawnerGroupName)
            {
                EnemySpawner* eventSpawner = nil;
                // find a matching spawner
                for(EnemySpawner* curSpawner in _subSpawners)
                {
                    SubSpawnerContext* spawnerContext = [curSpawner spawnerContext];
                    if([spawnerGroupName isEqualToString:[spawnerContext groupName]])
                    {
                        eventSpawner = curSpawner;
                        break;
                    }
                }
                if(eventSpawner)
                {
                    [newEvent setFlag:BOSSEVENT_FLAG_SPAWNER];
                    newEvent.spawner = eventSpawner;
                    newEvent.doneSpawnAnimState = [cur objectForKey:@"doneSpawnAnimState"];
                }
            }
            
            NSString* animState = [cur objectForKey:@"animState"];
            if(animState)
            {
                [newEvent setFlag:BOSSEVENT_FLAG_ANIMSTATE];
                newEvent.animState = animState;
            }
            
            NSNumber* continueToNext = [cur objectForKey:@"continue"];
            if(continueToNext)
            {
                // if TRUE, continue to the next event unconditionally in the next iteration
                newEvent.continueToNext = [continueToNext boolValue];
            }
            
            [_timeline addObject:newEvent];
            [newEvent release];
        }
    }
}

#pragma mark - public methods

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
    NSNumber* cruisingSpeedNumber = [triggerContext objectForKey:@"cruisingSpeed"];
    if(cruisingSpeedNumber)
    {
        _cruisingSpeed = [cruisingSpeedNumber floatValue];
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
    _cruisingTimeout = [[triggerContext objectForKey:@"timeout"] floatValue];
    
    float exitSpeed = [[triggerContext objectForKey:@"exitSpeed"] floatValue];
    float exitDir = [[triggerContext objectForKey:@"exitDir"] floatValue] * M_PI;
    _exitVel = radiansToVector(CGPointMake(0.0f, -1.0f), exitDir, exitSpeed);
    
    _health = [[triggerContext objectForKey:@"health"] intValue];
    _numCargos = [[triggerContext objectForKey:@"cargos"] unsignedIntValue];
    _isCollidable = [[triggerContext objectForKey:@"isCollidable"] boolValue];
    
    self.unblockScrollCamName = [triggerContext objectForKey:@"unblockScroll"];
    
    NSNumber* contextAABBOffsetX = [triggerContext objectForKey:@"colOriginX"];
    NSNumber* contextAABBOffsetY = [triggerContext objectForKey:@"colOriginY"];
    if(contextAABBOffsetX && contextAABBOffsetY)
    {
        _colOrigin = CGPointMake([contextAABBOffsetX floatValue], [contextAABBOffsetY floatValue]);
    }  
    
    self.subSpawnerConfigs = [triggerContext objectForKey:@"subSpawners"];

    NSNumber* contextDestroyDelay = [triggerContext objectForKey:@"destroyDelay"];
    if(contextDestroyDelay)
    {
        _destroyDelay = [contextDestroyDelay floatValue];
    }
}

- (void) setupFromSpawnersData:(SpawnersData *)givenSpawnersData onEnemy:(Enemy*)enemy
{
    self.spawnersData = givenSpawnersData;
    unsigned int numGroups = [_spawnersData numGroups];
    unsigned int index = 0;
    while(index < numGroups)
    {
        NSString* name = [_spawnersData getNameAtIndex:index];
        
        // match keyword
        if([name isEqualToString:COMPONENTADDON_KEYWORD])
        {
            // this is a component group; add all the components as effectAddons
            CGSize parentRenderSize = [[enemy renderer] size];  
            unsigned int numComponents = [_spawnersData getNumComponentsForGroup:name];
            unsigned int compIndex = 0;
            while(compIndex < numComponents)
            {
                NSDictionary* animInfo = [_spawnersData getComponentInfoForGroup:name atIndex:compIndex];
                if(animInfo)
                {
                    CGPoint offset = CGPointMake([[animInfo objectForKey:@"offsetX"] floatValue],
                                                 [[animInfo objectForKey:@"offsetY"] floatValue]);
                    CGPoint effectPos = CGPointMake((offset.x * parentRenderSize.width),
                                                    (offset.y * parentRenderSize.height));
                    effectPos = radiansToVector(effectPos, self.faceDir, 1.0f);
                    float rotate = [[animInfo objectForKey:@"rotate"] floatValue];
                    Addon* effectAddon = [[[LevelManager getInstance] addonFactory] createAddonNamed:[animInfo objectForKey:@"name"] atPos:effectPos];
                    effectAddon.renderBucket = _spawnEffectBucketIndex;
                    effectAddon.ownsBucket = YES;
                    float effectSizeX = [[animInfo objectForKey:@"width"] floatValue] * parentRenderSize.width;
                    float effectSizeY = [[animInfo objectForKey:@"height"] floatValue] * parentRenderSize.height;
                    float effectScaleX = effectSizeX / effectAddon.sprite.size.width;
                    float effectScaleY = effectSizeY / effectAddon.sprite.size.height;
                    effectAddon.scale = CGPointMake(effectScaleX, effectScaleY);
                    effectAddon.rotate = rotate;
                    [effectAddon.anim playClipForward:YES];
                    [effectAddon spawnOnParent:enemy];
                    [enemy.effectAddons addObject:effectAddon];
                    [effectAddon release];
                }
                ++compIndex;
            }
        }
        else
        {
            // default: spawner group
            EnemySpawner* newSpawner = [[EnemyFactory getInstance] createEnemySpawnerFromKey:@"SubSpawner"];
            SubSpawnerContext* newContext = [newSpawner spawnerContext];
            
            // configure spawner context from data
            NSDictionary* spawnerConfig = [_subSpawnerConfigs objectForKey:name];
            [newContext setupFromTriggerContext:spawnerConfig];
            newContext.groupName = name;
            
            // assign Boss as parent
            newContext.parent = enemy;
            CGSize parentRenderSize = [[enemy renderer] size];        
            
            // setup spawn points
            unsigned int numPoints = [_spawnersData getNumForGroup:name];
            unsigned int pointIndex = 0;
            while(pointIndex < numPoints)
            {
                CGPoint offset = [_spawnersData getOffsetAtIndex:pointIndex forGroup:name];
                CGPoint pointPos = CGPointMake(offset.x * parentRenderSize.width,
                                               offset.y * parentRenderSize.height);
                [newContext.spawnPoints addObject:[NSValue valueWithCGPoint:pointPos]];
                ++pointIndex;
            }
            
            // setup spawn effect
            NSDictionary* animInfo = [_spawnersData getSpawnAnimInfoForGroup:name];
            if(animInfo)
            {
                CGPoint offset = CGPointMake([[animInfo objectForKey:@"offsetX"] floatValue],
                                             [[animInfo objectForKey:@"offsetY"] floatValue]);
                CGPoint effectPos = CGPointMake((offset.x * parentRenderSize.width),
                                                (offset.y * parentRenderSize.height));
                effectPos = radiansToVector(effectPos, self.faceDir, 1.0f);
                float rotate = [[animInfo objectForKey:@"rotate"] floatValue];
                Addon* effectAddon = [[[LevelManager getInstance] addonFactory] createAddonNamed:[animInfo objectForKey:@"name"] atPos:effectPos];
                effectAddon.renderBucket = _spawnEffectBucketIndex;
                effectAddon.ownsBucket = YES;
                float effectSizeX = [[animInfo objectForKey:@"width"] floatValue] * parentRenderSize.width;
                float effectSizeY = [[animInfo objectForKey:@"height"] floatValue] * parentRenderSize.height;
                float effectScaleX = effectSizeX / effectAddon.sprite.size.width;
                float effectScaleY = effectSizeY / effectAddon.sprite.size.height;
                effectAddon.scale = CGPointMake(effectScaleX, effectScaleY);
                effectAddon.rotate = rotate;
                newContext.spawnAnim = effectAddon;
                [effectAddon release];
            }
            
            // track boss group
            NSNumber* configIsBossGroup = [spawnerConfig objectForKey:@"bossGroup"];
            if((configIsBossGroup) && ([configIsBossGroup boolValue]))
            {
                self.bossGroup = newSpawner;
                
                // boss group automatically has FinalFight
                newSpawner.hasFinalFight = YES;
            }
            
            // set hasFinalFight flag
            NSNumber* configHasFinalFight = [spawnerConfig objectForKey:@"hasFinalFight"];
            if((configHasFinalFight) && ([configHasFinalFight boolValue]))
            {
                newSpawner.hasFinalFight = YES;
            }
            
            // deactivate first, these need to be explicitly activated by Boss2
            [newSpawner setActivated:NO];
            
            // add new spawner to subSpawners list
            [_subSpawners addObject:newSpawner];
            [newSpawner release];
        }
        ++index;
    }
}

- (BOOL) isInTimelineSpawnerNamed:(NSString *)spawnerGroupName
{
    BOOL result = NO;
    for(BossEvent* cur in _timeline)
    {
        SubSpawnerContext* curSpawnerContext = [[cur spawner] spawnerContext];
        if([spawnerGroupName isEqualToString:[curSpawnerContext groupName]])
        {
            result = YES;
        }
    }
    return result;
}

@end

@interface Boss2 (PrivateMethods)
- (BOOL) areConditionsMetForFinalFight:(Enemy*)enemy;
- (BOOL) areAllSubSpawnersDestroyed:(Enemy*)enemy;
- (void) activateNonTimelineSubSpawners:(Enemy*)enemy;
- (void) activateTimelineEvent:(unsigned int)index forEnemy:(Enemy*)enemy;
- (void) activateNextTimelineEvent:(Enemy*)enemy;
- (BOOL) areConditionsMetForNextTimelineEvent:(Enemy*)enemy newPos:(CGPoint)newPos elapsed:(NSTimeInterval)elapsed;
- (void) enemy:(Enemy*)enemy startEffectAddonForKey:(const NSString*)key;
- (void) checkSubAchievement;
@end

@implementation Boss2
@synthesize typeName = _typeName;
@synthesize sizeName = _sizeName;
@synthesize spawnersDataName = _spawnersDataName;
@synthesize soundClipName = _soundClipName;
@synthesize incapSoundName = _incapSoundName;
@synthesize introSoundName = _introSoundName;
@synthesize animStates = _animStates;
@synthesize effectAddons = _effectAddons;

- (id) initWithTypeName:(NSString*)givenTypeName 
               sizeName:(NSString*)givenSizeName 
       spawnersDataName:(NSString*)givenSpawnersDataName 
             animStates:(NSDictionary *)givenAnimStates
{
    self = [super init];
    if(self)
    {
        self.typeName = givenTypeName;
        self.sizeName = givenSizeName;
        self.spawnersDataName = givenSpawnersDataName;
        self.soundClipName = nil;
        self.introSoundName = nil;
        self.incapSoundName = nil;
        self.animStates = givenAnimStates;
        self.effectAddons = nil;
    }
    return self;
}


- (void) dealloc
{
    self.effectAddons = nil;
    self.animStates = nil;
    self.incapSoundName = nil;
    self.introSoundName = nil;
    self.soundClipName = nil;
    self.spawnersDataName = nil;
    self.sizeName = nil;
    self.typeName = nil;
    [super dealloc];
}


#pragma mark - private methods

- (BOOL) areConditionsMetForFinalFight:(Enemy *)enemy
{
    BOOL result = NO;
    Boss2Context* myContext = [enemy behaviorContext];
    if([myContext bossGroup])
    {
        SubSpawnerContext* spawnerContext = [myContext.bossGroup spawnerContext];
        if([SubSpawner isClearToMoveOutOfCurrentWave:[myContext bossGroup]])
        {
            // if bossGroup is on the last wave, then we're good to proceed to FinalFight
            result = (([spawnerContext nextWave]+1) == [spawnerContext getNumWaves]);            
        }
    }
    return result;
}

- (BOOL) areAllSubSpawnersDestroyed:(Enemy *)enemy
{
    BOOL result = YES;
    Boss2Context* myContext = [enemy behaviorContext];
    for(EnemySpawner* cur in [myContext subSpawners])
    {
        SubSpawnerContext* spawnerContext = [cur spawnerContext];
        if([spawnerContext nextWave] < [spawnerContext getNumWaves])
        {
            result = NO;
            break;
        }
        if(![spawnerContext isSpawnerDestroyed])
        {
            result = NO;
            break;
        }
    }
    return result;
}

- (void) activateNonTimelineSubSpawners:(Enemy *)enemy
{
    Boss2Context* myContext = [enemy behaviorContext];
    for(EnemySpawner* cur in [myContext subSpawners])
    {
        SubSpawnerContext* curSpawnerContext = [cur spawnerContext];
        if(![myContext isInTimelineSpawnerNamed:[curSpawnerContext groupName]])
        {
            [cur activateWithContext:nil];
        }
    }
}

// Boss2 currently only supports single-flag BossEvents
// so, for example, if DELAY is specified, it would ignore the TARGETPOS and SPAWNER settings, and so on
- (void) activateTimelineEvent:(unsigned int)index forEnemy:(Enemy *)enemy
{
    Boss2Context* myContext = [enemy behaviorContext];
    if(index < [[myContext timeline] count])
    {
        BossEvent* nextEvent = [[myContext timeline] objectAtIndex:index];
        if([nextEvent isSetFlag:BOSSEVENT_FLAG_DELAY])
        {
            myContext.curTimelineTimer = [nextEvent delay];
        }
        else if([nextEvent isSetFlag:BOSSEVENT_FLAG_TARGETPOS])
        {
            CGPoint targetPos = [nextEvent getTargetPos];
            CGPoint dir = CGPointMake(targetPos.x - [enemy pos].x, targetPos.y - [enemy pos].y);
            CGPoint vel = CGPointNormalize(dir);
            vel.x *= [myContext cruisingSpeed];
            vel.y *= [myContext cruisingSpeed];
            enemy.vel = vel;
        }
        else if([nextEvent isSetFlag:BOSSEVENT_FLAG_SPAWNER])
        {
            if(![nextEvent.spawner activated])
            {
                nextEvent.hasPlayedDoneSpawnAnim = NO;
                [nextEvent.spawner activateWithContext:nil];
            }
        }
        else if([nextEvent isSetFlag:BOSSEVENT_FLAG_ANIMSTATE])
        {
            // switch my anim state
            enemy.curAnimClip = [enemy.animClipRegistry objectForKey:[nextEvent animState]];
            assert([enemy curAnimClip]);
            [enemy.curAnimClip playClipForward:YES];
            myContext.curAnimState = [nextEvent animState];
        }
    }
    myContext.curTimelineEvent = index;
}

- (void) activateNextTimelineEvent:(Enemy *)enemy
{
    Boss2Context* myContext = [enemy behaviorContext];
    unsigned int nextIndex = [myContext curTimelineEvent] + 1;
    [self activateTimelineEvent:nextIndex forEnemy:enemy];
}

- (BOOL) areConditionsMetForNextTimelineEvent:(Enemy *)enemy newPos:(CGPoint)newPos elapsed:(NSTimeInterval)elapsed
{
    BOOL result = NO;
    Boss2Context* myContext = [enemy behaviorContext];
    unsigned int curIndex = [myContext curTimelineEvent];
    if(curIndex < [[myContext timeline] count])
    {
        BossEvent* curEvent = [[myContext timeline] objectAtIndex:curIndex];
        if([curEvent isSetFlag:BOSSEVENT_FLAG_DELAY])
        {
            myContext.curTimelineTimer -= elapsed;
            if(0.0f >= [myContext curTimelineTimer])
            {
                result = YES;
            }
        }
        else if([curEvent isSetFlag:BOSSEVENT_FLAG_TARGETPOS])
        {
            if([curEvent doesTargetContainPos:newPos])
            {
                // yes
                result = YES;
                
                // stop cruising vel
                enemy.vel = CGPointMake(0.0f, 0.0f);
            }
        }
        else if([curEvent isSetFlag:BOSSEVENT_FLAG_SPAWNER])
        {
            SubSpawnerContext* spawnerContext = [[curEvent spawner] spawnerContext];
            if([curEvent doneSpawnAnimState])
            {
                if(![curEvent hasPlayedDoneSpawnAnim])
                {
                    if([spawnerContext hasSpawnedFinalWave])
                    {
                        // play done anim
                        enemy.curAnimClip = [enemy.animClipRegistry objectForKey:[curEvent doneSpawnAnimState]];
                        assert([enemy curAnimClip]);
                        [enemy.curAnimClip playClipForward:YES];
                        myContext.curAnimState = [curEvent doneSpawnAnimState];
                        
                        curEvent.hasPlayedDoneSpawnAnim = YES;
                    }
                }
            }
            result = [spawnerContext isSpawnerDestroyed];
        }
        else if([curEvent isSetFlag:BOSSEVENT_FLAG_ANIMSTATE])
        {
            if([enemy.curAnimClip playbackState] == ANIMCLIP_STATE_DONE)
            {
                result = YES;
            }
        }
        
        // continue to next unconditionally
        if([curEvent continueToNext])
        {
            result = YES;
        }
    }
    return result;
}

- (void) enemy:(Enemy *)enemy startEffectAddonForKey:(NSString *)key
{
    Boss2Context* myContext = [enemy behaviorContext];
    Addon* effect = [myContext.effectAddonsReg objectForKey:key];
    if(effect)
    {
        [effect.anim playClipForward:YES];
        [effect spawnOnParent:enemy];
        [enemy.effectAddons addObject:effect];
        [effect release];
    }
}

- (void) checkSubAchievement
{
    if(([_typeName isEqualToString:@"BoarSubL2"]) ||
       ([_typeName isEqualToString:@"BoarSubL6"]))  
    {
        // only consider the Boss blimps
        [[AchievementsManager getInstance] subKilled];
    }

}

#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:_sizeName];
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:_sizeName];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize colSize:colSize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];
            
    // anim
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    givenEnemy.animClipRegistry = [NSMutableDictionary dictionary];
    for(NSString* curAnimState in _animStates)
    {
        NSString* curAnimName = [_animStates objectForKey:curAnimState];
        AnimClipData* clipData = [animData getClipForName:curAnimName];
        AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
        [givenEnemy.animClipRegistry setObject:newClip forKey:curAnimState];
        [newClip release];
    }
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_BASIC];
        
    // must have at least the BASIC animstate
    assert(givenEnemy.curAnimClip);

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
    
    // init from trigger context
    NSDictionary* triggerContext = [givenSpawnerContext spawnerTriggerContext];
    if(triggerContext)
    {
        [newContext setupFromContextDictionary:triggerContext];

        // add-on data
        [newContext setupFromSpawnersData:[[LevelManager getInstance] getSpawnersDataForName:_spawnersDataName] onEnemy:givenEnemy];
        [newContext setupTimelineFromConfig:[triggerContext objectForKey:@"timeline"]];
    }


    // initial anim-state
    givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_BASIC];
    newContext.curAnimState = ANIMKEY_BASIC;

    // orientation
    givenEnemy.rotate = [newContext faceDir];

    // init colAABB
    CGRect colAABB = [givenEnemy colAABB];
    colAABB.origin.x += [newContext colOrigin].x;
    colAABB.origin.y += [newContext colOrigin].y;
    givenEnemy.colAABB = colAABB;
    
    // init velocity
    givenEnemy.vel = [newContext introVel];
    
    // effect addons
    for(NSString* curEffectKey in _effectAddons)
    {
        NSString* curEffectName = [_effectAddons objectForKey:curEffectKey];
        Addon* effect = [[[LevelManager getInstance] addonFactory] createAddonNamed:curEffectName atPos:CGPointMake(0.0f, 0.0f)];
        effect.renderBucket = [newContext dynamicsAddonsIndex];
        effect.ownsBucket = YES;
        [newContext.effectAddonsReg setObject:effect forKey:curEffectKey];
    }    
    
    // context dependent runtime params
    givenEnemy.health = newContext.health;
    givenEnemy.behaviorContext = newContext;
    [newContext release];
}



#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
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
            
            givenEnemy.vel = CGPointMake(0.0f, 0.0f);
            
            // activate the sub-spawners
            [self activateNonTimelineSubSpawners:givenEnemy];
            
            // activate the first event in timeline
            [self activateTimelineEvent:0 forEnemy:givenEnemy];
            
            // ok to fire
            if(![myContext collisionOn])
            {
                myContext.collisionOn = YES;
                givenEnemy.readyToFire = YES;
            }
            
            // start CRUISE effect
            [self enemy:givenEnemy startEffectAddonForKey:EFFECTKEY_CRUISE];
        }
    }
    else if((BEHAVIORSTATE_CRUISING == myContext.behaviorState) || 
            (BEHAVIORSTATE_FINALFIGHT == [myContext behaviorState]))
    {
        myContext.weaverX.base += (elapsed * givenEnemy.vel.x);
        myContext.weaverY.base += (elapsed * givenEnemy.vel.y);
        
        newPosX = [myContext.weaverX update:elapsed];
        newPosY = [myContext.weaverY update:elapsed];
        
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
        
        if(BEHAVIORSTATE_CRUISING == [myContext behaviorState])
        {
            // process timeline
            if([self areConditionsMetForNextTimelineEvent:givenEnemy newPos:CGPointMake(newPosX, newPosY) elapsed:elapsed])
            {
                [self activateNextTimelineEvent:givenEnemy];
            }
            
            // process transition condition
            myContext.cruisingTimer -= elapsed;
            if((0.0f > myContext.cruisingTimer) ||
               ([self areAllSubSpawnersDestroyed:givenEnemy]))
            {
                givenEnemy.vel = myContext.exitVel;
                myContext.behaviorState = BEHAVIORSTATE_LEAVING;

                // show explosion if one is specified
                [self enemy:givenEnemy startEffectAddonForKey:EFFECTKEY_DESTROY];
            }                
            else if([self areConditionsMetForFinalFight:givenEnemy])
            {
                // trigger FinalFight on all SubSpawners
                for(EnemySpawner* cur in [myContext subSpawners])
                {
                    [cur triggerFinalFight];
                }
                myContext.behaviorState = BEHAVIORSTATE_FINALFIGHT;
            }
        }
    }
    else if(BEHAVIORSTATE_DESTROYED == [myContext behaviorState])
    {
        myContext.destroyTimer -= elapsed;
        if(0.0f >= [myContext destroyTimer])
        {
            myContext.behaviorState = BEHAVIORSTATE_LEAVING;
            givenEnemy.vel = myContext.exitVel;
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
    else if(BEHAVIORSTATE_RETIRING == [myContext behaviorState])
    {
        // continuously unblock camera because game-manager may add a block after this boss has been defeated
        if([myContext unblockScrollCamName])
        {
            [[GameManager getInstance] unblockScrollCamFor:[myContext unblockScrollCamName]];
        }        
    }
        
    if(![givenEnemy incapacitated])
    {
        // update sub-spawners
        for(EnemySpawner* cur in [myContext subSpawners])
        {
            [cur update:elapsed];
        }
    }        

    givenEnemy.pos = CGPointMake(newPosX, newPosY);
}

- (NSString*) getEnemyTypeName
{
    return _typeName;
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    Boss2Context* myContext = [givenEnemy behaviorContext];
    for(EnemySpawner* cur in [myContext subSpawners])
    {
        [cur killAllBullets];
    }
}

#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    int prevHealth = [enemy health];
    enemy.health--;
    
    // if the enemy's health just dropped below 1/3, start the burning addon
    Boss2Context* myContext = [enemy behaviorContext];
    int initHealth_2 = [myContext health] / 2;
    if((prevHealth >= initHealth_2) && ([enemy health] < initHealth_2))
    {
        // show explosion and setup EXPLODING state
        [self enemy:enemy startEffectAddonForKey:EFFECTKEY_CRITICAL];        
    }

    // play bullet hit effect
    CGRect myAABB = [enemy getAABB];
    CGPoint hitPos = CGPointMake(givenAABB.origin.x + (0.5f * givenAABB.size.width),
                                 myAABB.origin.y);
    [EffectFactory effectNamed:@"BulletHit" atPos:hitPos];
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
    if([myContext behaviorState] == BEHAVIORSTATE_FINALFIGHT)
    {
        result = YES;
    }
    return result;
}


#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    Boss2Context* myContext = [givenEnemy behaviorContext];
    // stop sound effect clip if this enemy type has one
    if(_soundClipName)
    {
        [[SoundManager getInstance] stopEffectClip:_soundClipName];
    }
    
    if(![givenEnemy incapacitated])
    {
        // enemy was killed from retirement (not incapacitated)
        
        // go to DESTROYED state
        givenEnemy.vel = myContext.exitVel;
        myContext.behaviorState = BEHAVIORSTATE_DESTROYED;
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_DESTROYED];
        [givenEnemy.curAnimClip playClipForward:YES];
        myContext.curAnimState = ANIMKEY_DESTROYED;
    }

    // clear subSpawners
    myContext.bossGroup = nil;
    [myContext.timeline removeAllObjects];
    for(EnemySpawner* cur in [myContext subSpawners])
    {
        [cur shutdownSpawner];
    }
    [myContext.subSpawners removeAllObjects];
    
    // clear effect addons
    [myContext.effectAddonsReg removeAllObjects];
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    // play sound
    if(_incapSoundName)
    {
        [[SoundManager getInstance] playClip:_incapSoundName];        
    }

    // show explosion if one is specified
    [self enemy:givenEnemy startEffectAddonForKey:EFFECTKEY_DESTROY];

    Boss2Context* myContext = [givenEnemy behaviorContext];
    
    AnimClip* destroyedClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_DESTROYED];
    if(destroyedClip)
    {
        // go to DESTROYED state
        myContext.behaviorState = BEHAVIORSTATE_DESTROYED;
        givenEnemy.curAnimClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_DESTROYED];
        [givenEnemy.curAnimClip playClipForward:YES];
        myContext.curAnimState = ANIMKEY_DESTROYED;
        
        // clear subSpawners
        [myContext.timeline removeAllObjects];
        myContext.bossGroup = nil;
        for(EnemySpawner* cur in [myContext subSpawners])
        {
            [cur shutdownSpawner];
        }
        [myContext.subSpawners removeAllObjects];
        
        // set destroy timer
        myContext.destroyTimer = [myContext destroyDelay];
    }
    else
    {
        // no DESTROYED anim, then just go to LEAVING state
        givenEnemy.vel = myContext.exitVel;
        myContext.behaviorState = BEHAVIORSTATE_LEAVING;
        
        // incap all sub enemies
        for(EnemySpawner* cur in [myContext subSpawners])
        {
            for(Enemy* curEnemy in [cur spawnedEnemies])
            {
                [curEnemy incapThenKill];
            }
        }
    }
        
    
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
    
    // check achievement
    [self checkSubAchievement];
    
    // returns true for enemy to be killed immediately
    return NO;
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
        
    // start sound effect clip if this enemy type has one
    if(_soundClipName)
    {
        [[SoundManager getInstance] startEffectClip:_soundClipName];
    }
    
    // start the current anim
    // if INTRO anim specified, play it first (spawn first set of enemies only after INTRO is done)
    AnimClip* introClip = [givenEnemy.animClipRegistry objectForKey:ANIMKEY_INTRO];
    if(introClip)
    {
        myContext.curAnimState = ANIMKEY_INTRO;
        givenEnemy.curAnimClip = introClip;
        
        if(_introSoundName)
        {
            [[SoundManager getInstance] playClip:_introSoundName];
        }
    }
    [givenEnemy.curAnimClip playClipForward:YES];    
}

@end
