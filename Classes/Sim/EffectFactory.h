//
//  EffectFactory.h
//  PeterPog
//  
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Effect;
@class LevelAnimData;
@interface EffectFactory : NSObject
{
    NSMutableDictionary* archetypeLib;
}
@property (nonatomic,retain) NSMutableDictionary* archetypeLib;

+ (void) effectNamed:(NSString*)name atPos:(CGPoint)initPos;
+ (void) effectNamed:(NSString*)name atPos:(CGPoint)initPos rotated:(float)angle;
+ (void) textEffectFor:(NSString*)enemyTypeName 
                 atPos:(CGPoint)initPos; 
+ (void) textEffectFor:(NSString*)enemyTypeName 
                    atPos:(CGPoint)initPos 
                  withVel:(CGPoint)initVel 
                 scale:(CGPoint)initScale
                 duration:(float)effectDuration
                colorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
+ (void) textEffectForMultiplier:(unsigned int)multiplier atPos:(CGPoint)initPos;

- (id) initWithLevelAnimData:(LevelAnimData*)data;
- (Effect*) createEffectNamed:(NSString*)name atPos:(CGPoint)initPos;
- (Effect*) createEffectNamed:(NSString*)name atPos:(CGPoint)initPos withVel:(CGPoint)initVel;
- (Effect*) createEffectNamed:(NSString*)name atPos:(CGPoint)initPos withVel:(CGPoint)initVel;
@end
