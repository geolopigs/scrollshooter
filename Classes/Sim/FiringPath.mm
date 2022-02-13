//
//  FiringPath.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "FiringPath.h"
#import "Shot.h"
#import "FiringPathRenderer.h"
#import "RenderBucketsManager.h"
#import "DrawCommand.h"
#import "Texture.h"
#import "DynamicProtocols.h"
#import "CollisionManager.h"
#import "AnimClipData.h"
#import "AnimClip.h"
#import "AnimProcessor.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "GameObjectSizes.h"
#import "GameManager.h"
#import "EffectFactory.h"
#import "Player.h"
#include "MathUtils.h"

@interface FiringPath (PrivateMethods)
- (void) removeAllShotsWithEffects:(BOOL)shouldPlayEffects;
- (void) addToShotsSortedByTimer:(Shot*)newShot;
@end

@implementation FiringPath
@synthesize isTrailAnim = _isTrailAnim;
@synthesize vel;
@synthesize shotRenderSize;
@synthesize shotColSize;
@synthesize effectiveArea;
@synthesize shotRenderRotation;
@synthesize shotRenderRotationDegrees;
@synthesize shotLifeSpan;
@synthesize shotHasLifeSpan;
@synthesize isFriendly = _isFriendly;
@synthesize timeBetweenShots = _timeBetweenShots;
@synthesize shotPos = _shotPos;
@synthesize purgeList;
@synthesize shots;
@synthesize texture;
@synthesize renderer;
@synthesize animClipData;
@synthesize destructionEffectName;
@synthesize timeTillFire = _timeFillFire;

+ (FiringPath*) firingPathWithName:(NSString *)name
{
    FiringPath* newFiring = [self firingPathWithName:name dir:M_PI speed:50.0f lifeSpan:0.0f hasDestructionEffect:YES isTrailAnim:NO];
    return newFiring;
}

+ (FiringPath*) playerFiringPathWithName:(NSString*)name dir:(float)dir speed:(float)speed
{
    FiringPath* newFiring = [self firingPathWithName:name dir:dir speed:speed lifeSpan:0.0f hasDestructionEffect:NO isTrailAnim:NO];
    newFiring.isFriendly = YES;
    return newFiring;        
}

+ (id) firingPathWithName:(NSString *)name dir:(float)dir speed:(float)speed
{
    FiringPath* newFiring = [self firingPathWithName:name dir:dir speed:speed lifeSpan:0.0f hasDestructionEffect:YES isTrailAnim:NO];
    return newFiring;    
}

+ (id) firingPathWithName:(NSString *)name 
                      dir:(float)dir 
                    speed:(float)speed 
     hasDestructionEffect:(BOOL)hasDestructionEffect
{
    FiringPath* newFiring = [self firingPathWithName:name dir:dir speed:speed lifeSpan:0.0f hasDestructionEffect:YES isTrailAnim:NO];
    return newFiring;        
}

+ (id) firingPathWithName:(NSString *)name 
                      dir:(float)dir 
                    speed:(float)speed
     hasDestructionEffect:(BOOL)hasDestructionEffect 
              isTrailAnim:(BOOL)isTrail
{
    FiringPath* newFiring = [self firingPathWithName:name dir:dir speed:speed lifeSpan:0.0f hasDestructionEffect:YES isTrailAnim:NO];
    return newFiring;        
}
+ (id) firingPathWithName:(NSString *)name 
                      dir:(float)dir 
                    speed:(float)speed
                 lifeSpan:(float)lifeSpan
     hasDestructionEffect:(BOOL)hasDestructionEffect 
              isTrailAnim:(BOOL)isTrail
{
    CGPoint velocity = radiansToVector(CGPointMake(0.0f,1.0f), dir, speed);
    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    NSString* effectName = nil;
    if(hasDestructionEffect)
    {
        effectName = [name stringByAppendingString:@"Gone"];
    }
    FiringPath* newFiring = [[FiringPath alloc] initWithVelocity:velocity 
                                                  shotRenderSize:[[GameObjectSizes getInstance] renderSizeFor:name] 
                                                     shotColSize:[[GameObjectSizes getInstance] colSizeFor:name]
                                                        capacity:10 
                                                    animClipData:[animData getClipForName:name]
                                           destructionEffectName:effectName];
    newFiring.shotRenderRotation = dir;
    newFiring.shotRenderRotationDegrees = RadiansToDegrees(dir);
    if(0.0f < lifeSpan)
    {
        newFiring.shotHasLifeSpan = YES;
        newFiring.shotLifeSpan = lifeSpan;
    }
    newFiring.isTrailAnim = isTrail;
    return newFiring;    
}



- (id) initWithVelocity:(CGPoint)velocity 
         shotRenderSize:(CGSize)rsize 
            shotColSize:(CGSize)csize 
               capacity:(unsigned int)capacity 
           animClipData:(AnimClipData*)clipData
  destructionEffectName:(NSString*)effectName
{
    self = [super init];
    if(self)
    {
        self.purgeList = [NSMutableArray arrayWithCapacity:5];
        self.shots = [NSMutableArray arrayWithCapacity:capacity];
        _isTrailAnim = NO;
        self.vel = velocity;
        self.shotRenderSize = rsize;
        self.shotColSize = csize;
        self.shotRenderRotation = 0.0f;
        self.shotRenderRotationDegrees = 0.0f;
        self.shotLifeSpan = 0.0f;
        self.shotHasLifeSpan = NO;
        _isFriendly = NO;
        _timeBetweenShots = 0.5f;
        _shotPos = CGPointMake(0.0f, 0.0f);
        
        self.effectiveArea = [[GameManager getInstance] getPlayArea];
        
        self.texture = nil;
        
        FiringPathRenderer* newRenderer = [[FiringPathRenderer alloc] initWithSize:shotRenderSize colSize:csize];
        self.renderer = newRenderer;
        [newRenderer release];
        self.renderer.tex = self.texture.texName;
        renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Bullets"];
        self.animClipData = clipData;
        self.destructionEffectName = effectName;
        _timeFillFire = _timeBetweenShots;
    }
    return self;
}


- (void) dealloc
{
    if([shots count])
    {
        // I think this will never be reached because Shots retain their spawner
        // leave the code here anyway
        [self removeAllShotsWithEffects:NO];
    }
    self.animClipData = nil;
    [renderer release];
    [texture release];
    [shots release];
    [purgeList release];
    [super dealloc];
}

- (void) addToShotsSortedByTimer:(Shot *)newShot
{
    unsigned int index = 0;
    for(Shot* cur in shots)
    {
        if([cur timer] > [newShot timer])
        {
            break;
        }
        ++index;
    }
    [shots insertObject:newShot atIndex:index];
}

#pragma mark -
#pragma mark Accessor methods
- (Shot*) addShot:(CGPoint)pos
{
    Shot* newShot = [self addShot:pos withVelocity:self.vel];
    return newShot;
}

- (Shot*) addShot:(CGPoint)pos withVelocity:(CGPoint)velocity
{
    Shot* newShot = [Shot shotWithPosition:pos 
                                  velocity:velocity 
                                renderSize:self.shotRenderSize 
                                   colSize:self.shotColSize 
                                    rotate:shotRenderRotationDegrees];
    newShot.hasLifeSpan = shotHasLifeSpan;
    newShot.isFriendly = _isFriendly;
    newShot.timer = shotLifeSpan;
    newShot.mySpawner = self;
    if(animClipData)
    {
        AnimClip* newAnimClip = [[AnimClip alloc] initWithClipData:animClipData];
        newShot.animClip = newAnimClip;
        
        if(!_isTrailAnim)
        {
            // if not Trail, then let the anim play
            [[AnimProcessor getInstance] addClip:newShot.animClip];
            [newShot.animClip playClipForward:YES];
        }
        [newAnimClip release];
    }
    
    if(shotHasLifeSpan)
    {
        [self addToShotsSortedByTimer:newShot];
    }
    else
    {
        [shots addObject:newShot];
    }
    return newShot;    
}

- (Shot*) addShot:(CGPoint)pos dir:(float)dir speed:(float)speed
{
    float newShotRotate = normalizeAngle(shotRenderRotation + dir);
    CGPoint newShotPos = radiansToVector(CGPointMake(0.0f, 1.0f), newShotRotate, 0.5f * shotRenderSize.height);
    newShotPos.x += pos.x;
    newShotPos.y += pos.y;
    CGPoint newShotVel = radiansToVector(CGPointMake(0.0f, 1.0f), newShotRotate, speed);
    Shot* newShot = [Shot shotWithPosition:newShotPos 
                                  velocity:newShotVel 
                                renderSize:self.shotRenderSize 
                                   colSize:self.shotColSize 
                                    rotate:RadiansToDegrees(newShotRotate)];
    newShot.hasLifeSpan = shotHasLifeSpan;
    newShot.isFriendly = _isFriendly;
    newShot.timer = shotLifeSpan;
    newShot.mySpawner = self;
    if(animClipData)
    {
        AnimClip* newAnimClip = [[AnimClip alloc] initWithClipData:animClipData];
        newShot.animClip = newAnimClip;
        
        if(!_isTrailAnim)
        {
            // if not Trail, then let the anim play
            [[AnimProcessor getInstance] addClip:newShot.animClip];
            [newShot.animClip playClipForward:YES];
        }
        [newAnimClip release];
    }
    if(shotHasLifeSpan)
    {
        [self addToShotsSortedByTimer:newShot];
    }
    else
    {
        [shots addObject:newShot];
    }
    return newShot;    
}

- (void) removeShot:(Shot *)shot
{
    [purgeList addObject:shot];
}

- (void) removeAllShotsWithEffects:(BOOL)shouldPlayEffects
{
    [purgeList removeAllObjects];
    for(Shot* cur in shots)
    {
        // trigger a destruction effect
        if((shouldPlayEffects) && (destructionEffectName))
        {
            [EffectFactory effectNamed:destructionEffectName atPos:[cur pos]];
        }
        
        // remove from Collision
        [[CollisionManager getInstance] removeCollisionDelegate:cur];
        
        // clear out animClip
        if(cur.animClip)
        {
            [[AnimProcessor getInstance] removeClip:cur.animClip];
            cur.animClip = nil;
        }
        
        // disown the Shot
        cur.mySpawner = nil;
    }
    [shots removeAllObjects];    
}

- (void) removeAllShots
{
    [self removeAllShotsWithEffects:YES];
}

- (void) update:(NSTimeInterval)elapsed
{
    for(Shot* cur in shots)
    {
        cur.pos = CGPointMake(cur.pos.x + (elapsed * cur.vel.x), cur.pos.y + (elapsed * cur.vel.y));
        if((cur.pos.y > (effectiveArea.origin.y + effectiveArea.size.height)) ||
           (cur.pos.y < effectiveArea.origin.y) ||
           (cur.pos.x > (effectiveArea.origin.x + effectiveArea.size.width)) ||
           (cur.pos.x < effectiveArea.origin.x))
        {
            [self removeShot:cur];
        }
        else if(shotHasLifeSpan)
        {
            cur.timer -= elapsed;
            if(0.0f >= cur.timer)
            {
                [self removeShot:cur];
            }
        }
    }
    
    // retire shots 
    for(Shot* cur in purgeList)
    {
        // clear out animClip
        if(cur.animClip)
        {
            [[AnimProcessor getInstance] removeClip:cur.animClip];
            cur.animClip = nil;
        }
            
        // disown the Shot
        cur.mySpawner = nil;
        [shots removeObject:cur];
        
        // remove from Collision
        [[CollisionManager getInstance] removeCollisionDelegate:cur];
    }
    [purgeList removeAllObjects];
}

- (BOOL) player:(Player*)player fire:(NSTimeInterval)elapsed
{
    BOOL fired = NO;
    _timeTillFire -= elapsed;
    if(0 >= _timeTillFire)
    {
        Shot* newShot = [self addShot:CGPointMake(player.pos.x + _shotPos.x, player.pos.y + _shotPos.y)];
        [[CollisionManager getInstance] addCollisionDelegate:newShot toSetNamed:@"PlayerFire"];
        _timeTillFire = _timeBetweenShots;
        fired = YES;
    }
    
    return fired;
}

- (void) addDraw
{
    if(0 < [shots count])
    {
        BOOL isAnimated = (nil != self.animClipData);
        FiringPathInstance* data = [[FiringPathInstance alloc] initWithShots:shots isAnimated:isAnimated isTrail:_isTrailAnim];
        DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:renderer DrawData:data];
        [[RenderBucketsManager getInstance] addCommand:cmd toBucket:renderBucketIndex];
        [cmd release];
        [data release];
    }
}

- (unsigned int) numOutstandingShots
{
    return [shots count];
}

// brute force collision checks
- (void) collideWithEnemies:(NSSet*)enemyArray
{
    // do nothing
}

@end
