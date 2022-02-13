//
//  Shot.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "Shot.h"
#import "FiringPath.h"

@implementation Shot
@synthesize pos;
@synthesize vel;
@synthesize renderSize;
@synthesize colSize;
@synthesize scale;
@synthesize rotate;
@synthesize timer;
@synthesize hasLifeSpan;
@synthesize isFriendly;
@synthesize animClip;
@synthesize mySpawner;

+ (id) shotWithPosition:(CGPoint)position velocity:(CGPoint)velocity renderSize:(CGSize)size colSize:(CGSize)csize rotate:(float)rotation
{
    Shot* newShot = [Shot alloc];
    [newShot initWithPosition:position velocity:velocity renderSize:size colSize:csize rotate:rotation];
    [newShot autorelease];
    return newShot;
}

+ (id) shotWithPosition:(CGPoint)position velocity:(CGPoint)velocity renderSize:(CGSize)size colSize:(CGSize)csize
{
    Shot* newShot = [Shot shotWithPosition:position velocity:velocity renderSize:size colSize:csize rotate:0.0f];
    return newShot;
}

- (id) initWithPosition:(CGPoint)position velocity:(CGPoint)velocity renderSize:(CGSize)size colSize:(CGSize)csize rotate:(float)rotation
{
    self = [super init];
    if(self)
    {
        self.pos = position;
        self.vel = velocity;
        renderSize = size;
        colSize = csize;
        scale = CGPointMake(1.0f, 1.0f);
        rotate = rotation;
        self.mySpawner = nil;
        self.animClip = nil;
        
        // default to no lifespan
        hasLifeSpan = NO;
        isFriendly = NO;
        timer = 0.0f;
    }
    return self;
}

- (void) dealloc
{
    self.animClip = nil;
    self.mySpawner = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark CollisionDelegate
- (CGRect) getAABB
{
    float halfWidth = colSize.width * 0.5f;
    float halfHeight = colSize.height * 0.5f;
    CGRect result = CGRectMake(pos.x - halfWidth, pos.y - halfHeight, colSize.width, colSize.height);
    return result;
}

- (void) respondToCollisionFrom:(NSObject<CollisionDelegate> *)theOtherObject
{
    // I've hit something, remove myself
    [self.mySpawner removeShot:self];
}

- (BOOL) isCollisionOn
{
    return YES;
}

- (BOOL) isBullet
{
    return YES;
}

- (BOOL) isFriendlyToPlayer
{
    BOOL result = isFriendly;
    return result;
}

@end
