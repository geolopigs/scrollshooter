//
//  Loot.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "Loot.h"
#import "Sprite.h"
#import "AnimClip.h"
#import "AnimFrame.h"
#import "Texture.h"
#import "DrawCommand.h"
#import "RenderBucketsManager.h"
#import "AnimProcessor.h"
#import "DynamicManager.h"
#import "CollisionManager.h"


@implementation Loot
@synthesize sprite;
@synthesize animClip;
@synthesize pos;
@synthesize vel;
@synthesize collisionSize;
@synthesize renderScale;
@synthesize layerDistance;
@synthesize releasedAsDynamic;
@synthesize isAlive;
@synthesize renderBucketIndex;
@synthesize behaviorDelegate;
@synthesize lootContext;
@synthesize collisionResponseDelegate;
@synthesize collectedDelegate;
@synthesize collisionAABBDelegate;

- (id) initAtPos:(CGPoint)givenPos isDynamics:(BOOL)isDynamics
   usingDelegate:(NSObject<LootInitDelegate>*)initDelegate
{
    self = [super init];
    if (self) 
    {
        pos = givenPos;
        vel = CGPointMake(0.0f, 0.0f);
        collisionSize = CGSizeMake(1.0f, 1.0f);
        renderScale = CGPointMake(1.0f, 1.0f);
        releasedAsDynamic = NO;
        layerDistance = 0.0f;

        renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Addons"];
        
        self.sprite = nil;
        self.animClip = nil;
        self.behaviorDelegate = nil;
        self.lootContext = nil;
        self.collisionResponseDelegate = nil;
        self.collectedDelegate = nil;
        self.collisionAABBDelegate = nil;
        
        [initDelegate initLoot:self isDynamics:isDynamics];
        
        isAlive = NO;   // not alive until spawned
    }
    
    return self;
}

- (void) dealloc
{
    self.collisionAABBDelegate = nil;
    self.collectedDelegate = nil;
    self.collisionResponseDelegate = nil;
    self.lootContext = nil;
    self.behaviorDelegate = nil;
    self.animClip = nil;
    self.sprite = nil;
    [super dealloc];
}

- (void) spawn
{
    isAlive = YES;
    [[DynamicManager getInstance] addObject:self];
    [[CollisionManager getInstance] addCollisionDelegate:self toSetNamed:@"Loots"];
    [[AnimProcessor getInstance] addClip:self.animClip];
    [self.animClip playClipRandomForward:YES];
}

- (void) kill
{
    [[AnimProcessor getInstance] removeClip:self.animClip];
    [[CollisionManager getInstance] removeCollisionDelegate:self];
    [[DynamicManager getInstance] removeObject:self];
    isAlive = NO;
}

#pragma mark -
#pragma mark DynamicDelegate

- (BOOL) isViewConstrained
{
    return NO;
}

- (void) addDraw
{
    SpriteInstance* instanceData = [[SpriteInstance alloc] init];
    AnimFrame* curFrame = [[self animClip] currentFrame];
    instanceData.texture = [[curFrame texture] texName];
    instanceData.pos = self.pos;
    CGPoint curScale = self.renderScale;
    instanceData.scale = CGPointMake(curScale.x * [curFrame renderScale].x, curScale.y * [curFrame renderScale].y);
    instanceData.rotate = [curFrame renderRotate];
    instanceData.texcoordScale = CGPointMake(([[curFrame texture] getImageWidthTexcoord] * [curFrame scale].x),
                                             ([[curFrame texture] getImageHeightTexcoord] * [curFrame scale].y));
    instanceData.texcoordTranslate = [curFrame translate];
    instanceData.colorR = [curFrame colorR];
    instanceData.colorG = [curFrame colorG];
    instanceData.colorB = [curFrame colorB];
    instanceData.alpha = [curFrame colorA];
	DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:self.sprite DrawData:instanceData];
    [[RenderBucketsManager getInstance] addCommand:cmd toBucket:renderBucketIndex];
	[instanceData release];
    [cmd release];
}

- (void) updateBehavior:(NSTimeInterval)elapsed
{
	[self.behaviorDelegate update:elapsed forLoot:self];
}


#pragma mark -
#pragma mark CollisionDelegate
- (CGRect) getAABB
{
    CGRect result;
    if(self.collisionAABBDelegate)
    {
        result = [self.collisionAABBDelegate getAABB:self];
    }
    else
    {
        float halfWidth = collisionSize.width * 0.5f;
        float halfHeight = collisionSize.height * 0.5f;
        result = CGRectMake(pos.x - halfWidth, pos.y - halfHeight, collisionSize.width, collisionSize.height);
    }
    return result;
}

- (void) respondToCollisionFrom:(NSObject<CollisionDelegate>*)theOtherObject
{
    if(self.collectedDelegate)
    {
        [self.collectedDelegate collectLoot:self];
    }
    [self kill];
}

- (BOOL) isCollisionOn
{
    BOOL result = YES;
    if(self.collisionResponseDelegate)
    {
        result = [self.collisionResponseDelegate isCollisionOn:self];
    }
    return result;
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

@end
