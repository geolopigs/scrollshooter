//
//  AnimFrame.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "AnimFrame.h"
#import "Texture.h"

@implementation AnimFrame
@synthesize texture;
@synthesize scale;
@synthesize translate;
@synthesize renderScale;
@synthesize renderTranslate;
@synthesize renderRotate;
@synthesize colorR;
@synthesize colorG;
@synthesize colorB;
@synthesize colorA;

- (id)initWithTexture:(Texture*)tex scale:(CGPoint)texScale translate:(CGPoint)texTranslate
{
    self = [super init];
    if (self) 
    {
        self.texture = tex;
        self.scale = texScale;
        self.translate = texTranslate;
        self.renderScale = CGPointMake(1.0f, 1.0f);
        self.renderTranslate = CGPointMake(0.0f, 0.0f);
        self.colorR = 1.0f;
        self.colorG = 1.0f;
        self.colorB = 1.0f;
        self.colorA = 1.0f;
    }
    return self;
}

- (id)initWithTexture:(Texture*)tex scale:(CGPoint)texScale translate:(CGPoint)texTranslate renderScale:(CGPoint)spriteScale renderTranslate:(CGPoint)spriteTranslate renderRotate:(float)spriteRotate
{
    self = [super init];
    if (self) 
    {
        self.texture = tex;
        self.scale = texScale;
        self.translate = texTranslate;
        self.renderScale = spriteScale;
        self.renderTranslate = spriteTranslate;
        self.renderRotate = spriteRotate;
        self.colorR = 1.0f;
        self.colorG = 1.0f;
        self.colorB = 1.0f;
        self.colorA = 1.0f;
    }
    return self;
}

- (void) dealloc
{
    self.texture = nil;
    [super dealloc];
}



@end
