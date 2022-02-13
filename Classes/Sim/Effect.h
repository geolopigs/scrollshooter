//
//  Effect.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DynamicProtocols.h"

@class Sprite;
@class AnimClip;
@class Texture;
@interface Effect : NSObject<DynamicDelegate>
{
    Sprite*     sprite;
    AnimClip*   animClip;
    Texture*    texture;
    CGPoint     pos;
    CGPoint     vel;
    float       rotate;
    unsigned int renderBucketIndex;
    
    float       duration;
    float       fadePoint;
    float       fadeDecr;
    
    // configurables
    float       colorR;
    float       colorG;
    float       colorB;
    float       colorA;
    CGPoint      scale;
}
@property (nonatomic,retain) Sprite* sprite;
@property (nonatomic,retain) AnimClip* animClip;
@property (nonatomic,retain) Texture* texture;
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGPoint vel;
@property (nonatomic,assign) float rotate;
@property (nonatomic,assign) float duration;
@property (nonatomic,assign) float fadePoint;
@property (nonatomic,assign) float fadeDecr;

@property (nonatomic,assign) float colorR;
@property (nonatomic,assign) float colorG;
@property (nonatomic,assign) float colorB;
@property (nonatomic,assign) float colorA;
@property (nonatomic,assign) CGPoint scale;

- (id) initWithClip:(AnimClip*)clip sprite:(Sprite*)initSprite atPos:(CGPoint)givenPos;
- (id) initWithClip:(AnimClip*)clip sprite:(Sprite*)initSprite atPos:(CGPoint)givenPos withVel:(CGPoint)givenVel;
- (id) initWithTexture:(Texture*)tex sprite:(Sprite*)initSprite atPos:(CGPoint)givenPos withVel:(CGPoint)givenVel;
- (void) spawn;
- (void) spawnRotatedBy:(float)angle;
- (void) kill;

// configurables
- (void) setFade:(float)fadeDuration fromColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
@end
