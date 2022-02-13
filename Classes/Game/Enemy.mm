//
//  Enemy.mm
//

#import "Enemy.h"
#import "DrawCommand.h"
#import "RenderBucketsManager.h"
#import "DynamicManager.h"
#import "CollisionManager.h"
#import "Sprite.h"
#import "AnimLinearController.h"
#import "AnimFrame.h"
#import "AnimClip.h"
#import "AnimProcessor.h"
#import "Texture.h"
#import "FiringPath.h"
#import "Shot.h"
#import "EnemySpawner.h"
#import "StatsManager.h"
#import "GameManager.h"
#import "Addon.h"
#import "Shot.h"
#import "Effect.h"
#import "EffectFactory.h"
#import "LevelManager.h"
#import "Laser.h"
#include "MathUtils.h"

@interface Enemy (PrivateMethods)
- (void) initDefaults;
+ (CGPoint) transformPoint:(CGPoint)localPoint outOfParent:(Enemy*)parent;
@end

@implementation Enemy
@synthesize initDelegate;
@synthesize modelTranslate;
@synthesize scale;
@synthesize rotate;
@synthesize pos;
@synthesize vel;
@synthesize renderer;
@synthesize animController;
@synthesize animClip;
@synthesize hidden;
@synthesize hiddenTimer;
@synthesize animClipRegistry;
@synthesize curAnimClip;
@synthesize renderBucketIndex;
@synthesize renderBucketShadowsIndex;
@synthesize renderBucketAddonsIndex;
@synthesize shouldAddToRenderBucketLayer;
@synthesize isGrounded;
@synthesize mySpawner;
@synthesize behaviorDelegate;
@synthesize spawnedDelegate;
@synthesize parentDelegate;
@synthesize parentEnemy;
@synthesize hasPlayerParent = _hasPlayerParent;
@synthesize collisionResponseDelegate;
@synthesize collisionAABBDelegate;
@synthesize colAABB;
@synthesize killedDelegate;
@synthesize incapacitated;
@synthesize waveIndex;
@synthesize firingPath;
@synthesize readyToFire;
@synthesize removeBulletsWhenIncapacitated = _removeBulletsWhenIncapacitated;
@synthesize health;
@synthesize willRetire;
@synthesize behaviorContext;
@synthesize effectAddons;

#pragma mark - Private Methods
- (void) initDefaults
{
    modelTranslate = CGPointMake(0.0f, 0.0f);
    scale = CGPointMake(1.0f, 1.0f);
    rotate = 0.0f;
    pos = CGPointMake(0.0f, 0.0f);
    vel = CGPointMake(0.0f, 0.0f);
    hidden = NO;
    hiddenTimer = 0.0f;
    renderer = nil;
    self.animController = nil;
    self.animClip = nil;
    self.animClipRegistry = nil;
    self.curAnimClip = nil;
    shouldAddToRenderBucketLayer = NO;
    isGrounded = NO;
    self.mySpawner = nil;
    behaviorDelegate = nil;
    self.spawnedDelegate = nil;
    self.parentDelegate = nil;
    self.parentEnemy = nil;
    _hasPlayerParent = NO;
    self.firingPath = nil;
    readyToFire = YES;
    _removeBulletsWhenIncapacitated = YES;
    self.health = 100;
    willRetire = NO;
    self.behaviorContext = nil;
    renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Dynamics"];
    
    // collision
    colAABB = CGRectMake(0.0f, 0.0f, 10.0f, 10.0f);
    self.collisionResponseDelegate = nil;
    self.collisionAABBDelegate = nil;
    
    self.killedDelegate = nil;
    incapacitated = NO;
    waveIndex = 0;
    
    self.effectAddons = [NSMutableArray array];
    
    // internal cache
    gameplayAreaSize = [[GameManager getInstance] getPlayArea].size;
}

#pragma mark -
#pragma mark Instance Methods
- (id) initAtPos:(CGPoint)givenPos 
   usingDelegate:(NSObject<EnemyInitProtocol>*)archetype
{
	if((self = [super init]))
	{
        [self initDefaults];
		pos = givenPos;
        self.initDelegate = archetype;
        [initDelegate initEnemy:self];
	}
	return self;
}

- (id) initAtPos:(CGPoint)givenPos 
   usingDelegate:(NSObject<EnemyInitProtocol>*)archetype
withSpawnerContext:(id)spawnerContext
{
	if((self = [super init]))
	{
        [self initDefaults];
		pos = givenPos;
        self.initDelegate = archetype;
        [initDelegate initEnemy:self withSpawnerContext:spawnerContext];
	}
	return self;
}


- (void) dealloc
{
    self.effectAddons = nil;
    self.killedDelegate = nil;
    self.firingPath = nil;
    self.collisionAABBDelegate = nil;
    self.collisionResponseDelegate = nil;
    self.behaviorContext = nil;
    self.parentEnemy = nil;
    self.parentDelegate = nil;
    self.spawnedDelegate = nil;
    [behaviorDelegate release];
    self.mySpawner = nil;
    self.curAnimClip = nil;
    self.animClipRegistry = nil;
    self.animClip = nil;
    self.animController = nil;
	[renderer release];
    self.initDelegate = nil;
	[super dealloc];
}

- (void) spawn
{
    // perform any type specific pre-spawn operations
    if(spawnedDelegate)
    {
        [spawnedDelegate preSpawn:self];
    }
    
    [[DynamicManager getInstance] addObject:self];
    
    if([self collisionResponseDelegate])
    {
        if([collisionResponseDelegate isPlayerWeapon])
        {
            [[CollisionManager getInstance] addCollisionDelegate:self toSetNamed:@"PlayerFire"];                        
        }
        else if ([collisionResponseDelegate isPlayerCollidable])
        {
            [[CollisionManager getInstance] addCollisionDelegate:self toSetNamed:@"Enemies"];                        
        }
        else if([collisionResponseDelegate isCollidable])
        {
            [[CollisionManager getInstance] addCollisionDelegate:self toSetNamed:@"EnemiesNonCollidable"];
        }
    }
    else
    {
        // no response delegate, default to the Enemies list
        [[CollisionManager getInstance] addCollisionDelegate:self toSetNamed:@"Enemies"];                    
    }

    if(animController)
    {
        [[AnimProcessor getInstance] addController:animController];
    }
    
    if(self.animClip)
    {
        [[AnimProcessor getInstance] addClip:self.animClip];
        [self.animClip playClipForward:YES];
    }
    
    // add all anim clips to processor, but don't play yet; let the delegate play the necessary anim
    if(self.animClipRegistry)
    {
        for(NSString* curName in self.animClipRegistry)
        {
            NSObject<AnimProcDelegate>* curClip = [self.animClipRegistry objectForKey:curName];
            [[AnimProcessor getInstance] addClip:curClip];
        }
    }
    
    // if effect addon available, spawn it
    for(Addon* effectAddon in effectAddons)
    {
        [effectAddon spawnOnParent:self];
    }

    // reset hidden timer
    hiddenTimer = 0.0f;
}

- (void) kill
{
    // remove from parent
    if(parentDelegate)
    {
        [parentDelegate removeFromParent:[self parentEnemy] enemy:self];
    }
    
    // remove all anim clips from processor
    for(NSString* curName in self.animClipRegistry)
    {
        NSObject<AnimProcDelegate>* curClip = [self.animClipRegistry objectForKey:curName];
        [[AnimProcessor getInstance] removeClip:curClip];
    }
    
    if(self.animClip)
    {
        [[AnimProcessor getInstance] removeClip:self.animClip];
    }
    
    if(animController)
    {
        [[AnimProcessor getInstance] removeController:animController];
    }
    
    if(self.killedDelegate)
    {
        [self.killedDelegate killEnemy:self];
    }
    if(self.mySpawner)
    {
        [self.mySpawner removeEnemy:self];
    }
    
    // remove from collision only if not incapacitated; otherwise, the incapacitate() function already removed collision
    if(!incapacitated)
    {
        // remove from valueSorted list
        [[GameManager getInstance] removeFromValueSortedEnemy:self];
        
        [[CollisionManager getInstance] removeCollisionDelegate:self];
        
        // remove all bullets
        if(firingPath)
        {
            [firingPath removeAllShots];
        }    
        incapacitated = YES;
    }
    // clear any effect addons again in case there were destruction effects that got added after incap
    for(Addon* cur in effectAddons)
    {
        [cur kill];
    }
    [effectAddons removeAllObjects];

    [[DynamicManager getInstance] removeObject:self];
}

- (BOOL) incapacitate
{
    BOOL shouldImmediatelyKill = YES;
    shouldImmediatelyKill = [self incapacitateWithPoints:YES];
    return shouldImmediatelyKill;
}

- (BOOL) incapacitateWithPoints:(BOOL)creditPlayer
{
    BOOL shouldImmediatelyKill = YES;
    
    if(!incapacitated)
    {
        incapacitated = YES;

        // remove from valueSorted list
        [[GameManager getInstance] removeFromValueSortedEnemy:self];
        
        // credit the player
        if(creditPlayer)
        {
            [[StatsManager getInstance] destroyedEnemyNamed:[self.initDelegate getEnemyTypeName] andNumShots:[firingPath numOutstandingShots]];
        }
        // track number of incapacitated in spawner (spawner needs this to know whether it hasWoundDown)
        [mySpawner setNumIncapacitated:[mySpawner numIncapacitated] + 1];
        [mySpawner decrIncapsForWave:waveIndex];
        
        // remove all bullets
        if(firingPath && _removeBulletsWhenIncapacitated)
        {
            [firingPath removeAllShots];
        }
        
        // clear any effect addons
        for(Addon* cur in effectAddons)
        {
            [cur kill];
        }
        [effectAddons removeAllObjects];

        // remove collision
        [[CollisionManager getInstance] removeCollisionDelegate:self];

        // ask delegate to incapacitate
        if(self.killedDelegate)
        {
            shouldImmediatelyKill = [self.killedDelegate incapacitateEnemy:self showPoints:creditPlayer];
        }
    }
    return shouldImmediatelyKill;
}

- (void) incapThenKill
{
    BOOL shouldKill = [self incapacitate];
    if(shouldKill)
    {
        [self kill];
    }
}

- (void) incapThenKillWithPoints:(BOOL)creditPlayer
{
    BOOL shouldKill = [self incapacitateWithPoints:creditPlayer];
    if(shouldKill)
    {
        [self kill];
    }    
}

- (void) incapAndKill
{
    [self incapacitate];
    [self kill];
}

- (void) incapAndKillWithPoints:(BOOL)creditPlayer
{
    [self incapacitateWithPoints:creditPlayer];
    [self kill];
}

- (Shot*) fireFromPos:(CGPoint)firingPosition dir:(float)dir speed:(float)speed
{
    Shot* result = nil;
    if((readyToFire) && (!incapacitated))
    {
        Shot* newShot = [firingPath addShot:firingPosition dir:dir speed:speed];
        if([newShot isFriendly])
        {
            // isFriendly is another term for isParticleEffect; don't add any collision
        }
        else
        {
            [[CollisionManager getInstance] addCollisionDelegate:newShot toSetNamed:@"EnemyFire"];
        }
        result = newShot;
    }
    return result;
}

- (void) fireFromPos:(CGPoint)firingPosition withVel:(CGPoint)firingVelocity
{
    if((readyToFire) && (!incapacitated))
    {
        Shot* newShot = [firingPath addShot:firingPosition withVelocity:firingVelocity];
        if([newShot isFriendly])
        {
            // isFriendly is another term for isParticleEffect; don't add any collision
        }
        else
        {
            [[CollisionManager getInstance] addCollisionDelegate:newShot toSetNamed:@"EnemyFire"];
        }
    }
}

- (void) fireWithVel:(CGPoint)firingVelocity
{
    [self fireFromPos:pos withVel:firingVelocity];
}

// handles calls from GameManager when this enemy is triggered by the triggerEnemies dictionary
- (void) triggerGameEvent:(NSString *)label
{
    [behaviorDelegate enemyBehavior:self receiveTrigger:label];
}

- (void) killAllBullets
{
    // kill my bullets
    if(firingPath)
    {
        [firingPath removeAllShots];
    }
    
    // kill any bullets owned by the behavior delegate
    [behaviorDelegate enemyBehaviorKillAllBullets:self];
}

#pragma mark -
#pragma mark DynamicProtocols
- (BOOL) isViewConstrained
{
    return NO;
}

- (void) updateBehavior:(NSTimeInterval)elapsed
{
	[self.behaviorDelegate update:elapsed forEnemy:self];
    [firingPath update:elapsed];
    
    // register enemy with GameManager valueSorted list
    if(![self incapacitated])
    {
        if(([self collisionResponseDelegate]) && 
           (![collisionResponseDelegate isPlayerWeapon]) &&
           ([collisionResponseDelegate isCollidable]))
        {
            CGRect myAABB = [self getAABB];
            CGRect playArea = [[GameManager getInstance] getPlayArea];
            const float buffer = 0.1f;
            float botLeftY = playArea.origin.y - (buffer * playArea.size.height);
            float topRightY = playArea.origin.y + playArea.size.height + (buffer * playArea.size.height);
            if((myAABB.origin.y > botLeftY) && (myAABB.origin.y < topRightY))
            {
                [[GameManager getInstance] addValueSortedenemy:self];
            }
        }
    }
    
    hiddenTimer -= elapsed;
    if(hiddenTimer <= 0.0f)
    {
        hiddenTimer = 0.0f;
    }
}


- (void) addDraw
{
    if((![self hidden]) && (hiddenTimer <= 0.0f))
    {
        CGPoint renderPos = [Enemy derivePosFromParentForEnemy:self];
        CGPoint renderScale = scale;
                
        // retrieve anim info
        SpriteInstance* instanceData = [[SpriteInstance alloc] init];
        if([self animController])
        {
            AnimFrame* curFrame = [[self animController] currentFrame];
            instanceData.texture = [[curFrame texture] texName];
            instanceData.pos = renderPos;
            instanceData.texcoordScale = CGPointMake(([[curFrame texture] getImageWidthTexcoord] * [curFrame scale].x),
                                                     ([[curFrame texture] getImageHeightTexcoord] * [curFrame scale].y));
            instanceData.texcoordTranslate = [curFrame translate];
            instanceData.rotate = RadiansToDegrees(rotate) + [curFrame renderRotate];
            instanceData.colorR = [curFrame colorR];
            instanceData.colorG = [curFrame colorG];
            instanceData.colorB = [curFrame colorB];
            instanceData.alpha = [curFrame colorA];
        }
        else if([self animClip])
        {
            AnimFrame* curFrame = [[self animClip] currentFrame];
            instanceData.texture = [[curFrame texture] texName];
            
            instanceData.pos = renderPos;
            instanceData.texcoordScale = CGPointMake(([[curFrame texture] getImageWidthTexcoord] * [curFrame scale].x),
                                                     ([[curFrame texture] getImageHeightTexcoord] * [curFrame scale].y));
            instanceData.texcoordTranslate = [curFrame translate];
            CGPoint clipScale = CGPointMake(curFrame.renderScale.x * renderScale.x, curFrame.renderScale.y * renderScale.y);
            renderScale = clipScale;
            instanceData.rotate = RadiansToDegrees(rotate) + [curFrame renderRotate];
            instanceData.colorR = [curFrame colorR];
            instanceData.colorG = [curFrame colorG];
            instanceData.colorB = [curFrame colorB];
            instanceData.alpha = [curFrame colorA];
        }
        else if([self curAnimClip])
        {
            AnimFrame* curFrame = [[self curAnimClip] currentFrame];
            instanceData.texture = [[curFrame texture] texName];
            
            instanceData.pos = renderPos;
            instanceData.texcoordScale = CGPointMake(([[curFrame texture] getImageWidthTexcoord] * [curFrame scale].x),
                                                     ([[curFrame texture] getImageHeightTexcoord] * [curFrame scale].y));
            instanceData.texcoordTranslate = [curFrame translate];
            instanceData.rotate = RadiansToDegrees(rotate) + [curFrame renderRotate];        
            instanceData.colorR = [curFrame colorR];
            instanceData.colorG = [curFrame colorG];
            instanceData.colorB = [curFrame colorB];
            instanceData.alpha = [curFrame colorA];
        }

        // add draw for auxillary stuff first so that enemy draw on top of addons by default
        // (any addons that need to draw above an enemy would need to be explicitly assigned to an Addons render-bucket)
        for(Addon* effectAddon in effectAddons)
        {
            [effectAddon addDrawAsAddonToBucketIndex:renderBucketShadowsIndex];
        }
        
        // add draw for self
        instanceData.localTranslate = modelTranslate;
        instanceData.pos = renderPos;
        instanceData.scale = renderScale;
        DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:renderer DrawData:instanceData];
        [[RenderBucketsManager getInstance] addCommand:cmd toBucket:renderBucketIndex];
        [cmd release];
        [instanceData release];
    }

    // draw bullets
    [self.firingPath addDraw];
}


#pragma mark -
#pragma mark CollisionDelegate
- (CGRect) getAABB
{
    CGRect result;
    if(collisionAABBDelegate)
    {
        result = [collisionAABBDelegate getAABB:self];
    }
    else
    {
        float halfWidth = colAABB.size.width * 0.5f;
        float halfHeight = colAABB.size.height * 0.5f;
        result = CGRectMake(pos.x + colAABB.origin.x - halfWidth, pos.y + colAABB.origin.y - halfHeight, 
                            colAABB.size.width, colAABB.size.height);
    }
    return result;
}

- (void) respondToCollisionFrom:(NSObject<CollisionDelegate> *)theOtherObject
{
    // credit player with bullet hit regardless; more points, more fun
    [[StatsManager getInstance] creditBulletHits:1];

    // only respond to collision if enemy is within play area;
    // this is to prevent player having the advantage of killing off screen enemies before they even have a chance to enter the screen
    // collision AABB origin is at bottom-left corner
    CGRect myAABB = [self getAABB];
    if(myAABB.origin.y > gameplayAreaSize.height)
    {
        // hit when outside of the screen, don't take damage
    }
    else
    {
        // inform delegate
        if(collisionResponseDelegate)
        {
            [collisionResponseDelegate enemy:self respondToCollisionWithAABB:[theOtherObject getAABB]];
        }
        
        if(!incapacitated)
        {
            // kill myself
            if(0 >= self.health)
            {
                [self incapThenKill];
            }
        }
    }
}

- (BOOL) isCollisionOn
{
    BOOL result = YES;
    if(collisionResponseDelegate)
    {
        result = [collisionResponseDelegate isCollisionOnFor:self];
    }
    return result;
}

- (BOOL) isBullet
{
    BOOL result = NO;
    if([[self behaviorDelegate] isMemberOfClass:[Laser class]])
    {
        result = YES;
    }
    return result;
}

- (BOOL) isFriendlyToPlayer
{
    BOOL result = NO;
    return result;
}

#pragma mark -
#pragma mark AddonDelegate
- (CGPoint) worldPosition
{
    return [Enemy derivePosFromParentForEnemy:self];
}

- (float) rotation
{
    return rotate;
}

#pragma mark - utility methods
+ (CGPoint) transformPoint:(CGPoint)localPoint outOfParentPos:(CGPoint)parentPos parentRotate:(CGFloat)parentRotate
{
    CGPoint result;
    CGPoint upPos = parentPos;
    CGAffineTransform t = CGAffineTransformMakeRotation(parentRotate);
    CGPoint offset = CGPointApplyAffineTransform(localPoint, t);
    result.x = offset.x + upPos.x;
    result.y = offset.y + upPos.y;
    return result;
}

+ (CGPoint) derivePosFromParentForEnemy:(Enemy*)givenEnemy
{
    // adjust renderpos based on parent if one exists (up to two levels up)
    // if none, just return the givenEnemy's pos
    Enemy* parentEnemy = [givenEnemy parentEnemy];
    CGPoint myPos = [givenEnemy pos];
    if(parentEnemy)
    {
        myPos = [Enemy transformPoint:myPos outOfParentPos:[parentEnemy pos] parentRotate:[parentEnemy rotate]];
        if([parentEnemy parentEnemy])
        {
            CGPoint grandParentPos = [[parentEnemy parentEnemy] pos];
            CGFloat grandParentRotate = [[parentEnemy parentEnemy] rotate];
            myPos = [Enemy transformPoint:myPos outOfParentPos:grandParentPos parentRotate:grandParentRotate];
        }
    }
    else if([givenEnemy hasPlayerParent])
    {
        CGPoint playerPos = [[[GameManager getInstance] playerShip] pos];
        myPos = [Enemy transformPoint:[givenEnemy pos] outOfParentPos:playerPos parentRotate:0.0f];
    }
    return myPos;
}


@end
