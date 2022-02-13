//
//  BoarFighterArchetype.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/31/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "BoarFighterArchetype.h"
#import "Sprite.h"
#import "AnimLinearController.h"
#import "Enemy.h"
#import "AnimClipData.h"
#import "AnimClip.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "EffectFactory.h"
#import "Effect.h"
#import "LootFactory.h"
#import "Loot.h"
#import "FiringPath.h"
#import "SoundManager.h"
#import "GameObjectSizes.h"

@implementation BoarFighterContext
@synthesize distTillTurn;
@synthesize lastY;
@synthesize finalSpeed;
@synthesize accel;
@synthesize timeTillFire;
@synthesize firingSlot;
@end


static const float TIME_TILL_FIRE = 2.2f;
static const float EXPLOSION_VEL_X = 0.0f;
static const float EXPLOSION_VEL_Y = 0.0f;
static const float EXPLOSION_LOCAL_X = 0.0f;
static const float EXPLOSION_LOCAL_Y = -6.0f * 0.75f;

@implementation BoarFighterArchetype



#pragma mark -
#pragma mark EnemyInitProtocol
- (void) initEnemy:(Enemy*)givenEnemy
{
    CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:@"BoarFighter"];
	Sprite* enemyRenderer = [[Sprite alloc] initWithSize:mySize];
	givenEnemy.renderer = enemyRenderer;
    [enemyRenderer release];

    LevelAnimData* animData = [[[LevelManager getInstance] curLevel] animData];
    
    // init anim controller
    AnimClipData* data = [animData getClipForName:@"BoarFighter"];
    AnimLinearController* newController = [[AnimLinearController alloc] initFromAnimClipData:data];
    givenEnemy.animController = newController;
    [newController release];
    
    // install the behavior delegate
    givenEnemy.behaviorDelegate = self;
    
    // set collision AABB
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:@"BoarFighter"];
    givenEnemy.colAABB = CGRectMake(0.0f, 0.0f, colSize.width, colSize.height);
    givenEnemy.collisionResponseDelegate = self;
    
    // install killed delegate
    givenEnemy.killedDelegate = self;
    
    // game status
    givenEnemy.health = 5;
    
    // firing params
    FiringPath* newFiring = [FiringPath firingPathWithName:@"TurretBullet"];
    givenEnemy.firingPath = newFiring;
    [newFiring release];
}

#pragma mark -
#pragma mark EnemyBehaviorProtocol
- (void) update:(NSTimeInterval)elapsed forEnemy:(Enemy *)givenEnemy
{
    BoarFighterContext* myContext = [givenEnemy behaviorContext];
    CGPoint newPos = CGPointMake(givenEnemy.pos.x + (givenEnemy.vel.x * elapsed),
                                 givenEnemy.pos.y + (givenEnemy.vel.y * elapsed));
    
    // process anim
    float diffX = newPos.x - givenEnemy.pos.x;
    if(diffX < -0.1f)
    {
        [[givenEnemy animController] targetRangeMax];
    }
    else if(0.1f < diffX)
    {
        [[givenEnemy animController] targetRangeMin];
    }
    else
    {
        [[givenEnemy animController] targetRangeMedian];
    }

    givenEnemy.pos = newPos;
    
    // update velocity
    if(([myContext lastY] - newPos.y) > [myContext distTillTurn])
    {
        CGPoint newVel = givenEnemy.vel;
        if([myContext finalSpeed].x >= fabsf([givenEnemy vel].x))
        {
            newVel.x = givenEnemy.vel.x + (myContext.accel.x * elapsed);
        }
        if([myContext finalSpeed].y >= fabsf([givenEnemy vel].y))
        {
            newVel.y = givenEnemy.vel.y + (myContext.accel.y * elapsed);
        }
        givenEnemy.vel = newVel;
    }
    
    // update firing
    myContext.timeTillFire -= elapsed;
    switch(myContext.firingSlot)
    {
        case 0:
            if(0.0f >= myContext.timeTillFire)
            {
                [givenEnemy fireWithVel:CGPointMake(20.0f, -50.0f)];
                myContext.firingSlot = 1;
                myContext.timeTillFire = 0.5f;
            }
            break;
            
        case 1:
            if(0.0f >= myContext.timeTillFire)
            {
                [givenEnemy fireWithVel:CGPointMake(0.0f, -50.0f)];
                myContext.firingSlot = 2;
                myContext.timeTillFire = 0.5f;
            }
            break;
            
        case 2:
            if(0.0f >= myContext.timeTillFire)
            {
                [givenEnemy fireWithVel:CGPointMake(-10.0f, -20.0f)];
                myContext.firingSlot = 3;
                myContext.timeTillFire = 0.5f;
            }
            break;
            
        case 3:
            if(0.0f >= myContext.timeTillFire)
            {
                myContext.firingSlot = 0;
                myContext.timeTillFire = 2.2f;
            }
            break;
            
        default:
            break;
    }
}

- (NSString*) getEnemyTypeName
{
    return @"BoarFighter";
}

- (void) enemyBehaviorKillAllBullets:(Enemy*)givenEnemy
{
    // do nothing
}


#pragma mark -
#pragma mark EnemyCollisionResponse
- (void) enemy:(Enemy*)enemy respondToCollisionWithAABB:(CGRect)givenAABB
{
    enemy.health--;
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
    return YES;
}


#pragma mark -
#pragma mark EnemyKilledDelegate
- (void) killEnemy:(Enemy *)givenEnemy
{
    // play explosion effect
    Effect* explosion = [[[LevelManager getInstance] effectFactory] createEffectNamed:@"Explosion" 
                                                                                atPos:CGPointMake(givenEnemy.pos.x + EXPLOSION_LOCAL_X,
                                                                                                  givenEnemy.pos.y + EXPLOSION_LOCAL_Y)
                                                                              withVel:CGPointMake(EXPLOSION_VEL_X, EXPLOSION_VEL_Y)];
    [explosion spawn];
    [explosion release];
    
    // play down effect
    Effect* downEffect = [[[LevelManager getInstance] effectFactory] createEffectNamed:@"BoarFighterDown" atPos:givenEnemy.pos];
    [downEffect spawn];
    [downEffect release];
}

- (BOOL) incapacitateEnemy:(Enemy *)givenEnemy showPoints:(BOOL)showPoints
{
    // play sound
    [[SoundManager getInstance] playClip:@"BoarFighterExplosion"];

    // show points gained
    if(showPoints)
    {
        [EffectFactory textEffectFor:[[givenEnemy initDelegate] getEnemyTypeName]
                               atPos:[givenEnemy pos]]; 
    }
    
    // returns true for enemy to be killed immediately
    return YES;
}


@end
