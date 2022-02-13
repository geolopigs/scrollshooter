//
//  FiringPath.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FiringPathRenderer;
@class Texture;
@class Shot;
@class AnimClipData;
@class Player;
@interface FiringPath : NSObject 
{
    // configs
    CGPoint         vel;
    CGSize          shotRenderSize;
    CGSize          shotColSize;
    float           shotRenderRotation;
    float           shotRenderRotationDegrees;
    float           shotLifeSpan;
    BOOL            shotHasLifeSpan;
    CGRect          effectiveArea;
    float           _timeBetweenShots;  // config only (used by caller; no internal state to manage this yet)
    CGPoint         _shotPos;           // config only
    
    NSMutableArray* purgeList;
    NSMutableArray* shots;
    Texture*        texture;
    FiringPathRenderer* renderer;
    unsigned int    renderBucketIndex;
    AnimClipData*   animClipData;
    NSString*       destructionEffectName;
    float           _timeTillFire;
}
@property (nonatomic,assign) BOOL isTrailAnim;
@property (nonatomic,assign) CGPoint vel;
@property (nonatomic,assign) CGSize shotRenderSize;
@property (nonatomic,assign) CGSize shotColSize;
@property (nonatomic,assign) float shotRenderRotation;
@property (nonatomic,assign) float shotRenderRotationDegrees;
@property (nonatomic,assign) float shotLifeSpan;
@property (nonatomic,assign) BOOL shotHasLifeSpan;
@property (nonatomic,assign) CGRect effectiveArea;
@property (nonatomic,assign) BOOL isFriendly;
@property (nonatomic,assign) float timeBetweenShots;
@property (nonatomic,assign) CGPoint shotPos;

@property (nonatomic,retain) NSMutableArray* purgeList;
@property (nonatomic,retain) NSMutableArray* shots;
@property (nonatomic,retain) Texture* texture;
@property (nonatomic,retain) FiringPathRenderer* renderer;
@property (nonatomic,retain) AnimClipData* animClipData;
@property (nonatomic,retain) NSString* destructionEffectName;
@property (nonatomic,assign) float timeTillFire;

+ (FiringPath*) firingPathWithName:(NSString*)name;
+ (FiringPath*) playerFiringPathWithName:(NSString*)name dir:(float)dir speed:(float)speed;
+ (id) firingPathWithName:(NSString *)name dir:(float)dir speed:(float)speed;
+ (id) firingPathWithName:(NSString *)name dir:(float)dir speed:(float)speed hasDestructionEffect:(BOOL)hasDestructionEffect;
+ (id) firingPathWithName:(NSString *)name 
                      dir:(float)dir 
                    speed:(float)speed 
     hasDestructionEffect:(BOOL)hasDestructionEffect 
              isTrailAnim:(BOOL)isTrail;
+ (id) firingPathWithName:(NSString *)name 
                      dir:(float)dir 
                    speed:(float)speed
                 lifeSpan:(float)lifeSpan
     hasDestructionEffect:(BOOL)hasDestructionEffect 
              isTrailAnim:(BOOL)isTrail;

- (id) initWithVelocity:(CGPoint)velocity 
         shotRenderSize:(CGSize)rsize 
            shotColSize:(CGSize)csize 
               capacity:(unsigned int)capacity 
           animClipData:(AnimClipData*)clipData
  destructionEffectName:(NSString*)effectName;

- (Shot*) addShot:(CGPoint)newShot;
- (Shot*) addShot:(CGPoint)newShot withVelocity:(CGPoint)velocity;
- (Shot*) addShot:(CGPoint)pos dir:(float)dir speed:(float)speed;
- (void) removeShot:(Shot*)shot;
- (void) removeAllShots;
- (void) update:(NSTimeInterval)elapsed;
- (BOOL) player:(Player*)player fire:(NSTimeInterval)elapsed;
- (void) addDraw;
- (unsigned int) numOutstandingShots;

- (void) collideWithEnemies:(NSSet*)enemyArray;

@end
