//
//  AnimFrame.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Texture;
@interface AnimFrame : NSObject
{
    Texture*    texture;
    CGPoint     scale;          // this is texcoord
    CGPoint     translate;      // this is texcoord
    CGPoint     renderScale;
    CGPoint     renderTranslate; // not used right now
    float       renderRotate;
}
@property (nonatomic,retain) Texture* texture;
@property (nonatomic,assign) CGPoint scale;
@property (nonatomic,assign) CGPoint translate;
@property (nonatomic,assign) CGPoint renderScale;
@property (nonatomic,assign) CGPoint renderTranslate;
@property (nonatomic,assign) float   renderRotate;
@property (nonatomic,assign) float   colorR;
@property (nonatomic,assign) float   colorG;
@property (nonatomic,assign) float   colorB;
@property (nonatomic,assign) float   colorA;
- (id)initWithTexture:(Texture*)tex scale:(CGPoint)texScale translate:(CGPoint)texTranslate;
- (id)initWithTexture:(Texture*)tex scale:(CGPoint)texScale translate:(CGPoint)texTranslate renderScale:(CGPoint)spriteScale renderTranslate:(CGPoint)spriteTranslate renderRotate:(float)spriteRotate;
@end
