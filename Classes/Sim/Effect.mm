//
//  Effect.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "Effect.h"
#import "Sprite.h"
#import "AnimClip.h"
#import "DynamicManager.h"
#import "AnimProcessor.h"
#import "AnimFrame.h"
#import "Texture.h"
#import "DrawCommand.h"
#import "RenderBucketsManager.h"
#include "MathUtils.h"

@interface Effect (PrivateMethods)
- (void) setConfigurablesToDefault;
@end

@implementation Effect
@synthesize sprite;
@synthesize animClip;
@synthesize texture;
@synthesize pos;
@synthesize vel;
@synthesize rotate;
@synthesize duration;
@synthesize fadePoint;
@synthesize fadeDecr;
@synthesize colorR;
@synthesize colorG;
@synthesize colorB;
@synthesize colorA;
@synthesize scale;

#pragma mark - Private Methods
- (void) setConfigurablesToDefault
{
    colorR = 1.0;
    colorG = 1.0;
    colorB = 1.0;
    colorA = 1.0;
    scale = CGPointMake(1.0f, 1.0f);
}


#pragma mark - Public Methods

- (id) initWithClip:(AnimClip*)clip sprite:(Sprite*)initSprite atPos:(CGPoint)givenPos 
{
    self = [super init];
    if (self) 
    {
        self.sprite = initSprite;
        self.animClip = clip;
        self.texture = nil;
        self.pos = givenPos;
        self.vel = CGPointMake(0.0f, 0.0f);
        self.rotate = 0.0f;
        self.duration = 0.0f;
        self.fadePoint = 0.0f;
        self.fadeDecr = 0.0f;
        renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Addons"];

        [self setConfigurablesToDefault];
    }
    
    return self;
}

- (id) initWithClip:(AnimClip*)clip sprite:(Sprite*)initSprite atPos:(CGPoint)givenPos withVel:(CGPoint)givenVel
{
    self = [super init];
    if (self) 
    {
        self.sprite = initSprite;
        self.animClip = clip;
        self.texture = nil;
        self.pos = givenPos;
        self.vel = givenVel;
        self.duration = 0.0f;
        self.fadePoint = 0.0f;
        self.fadeDecr = 0.0f;
        renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Addons"];
        
        [self setConfigurablesToDefault];
    }
    
    return self;
}

- (id) initWithTexture:(Texture*)tex sprite:(Sprite*)initSprite atPos:(CGPoint)givenPos withVel:(CGPoint)givenVel
{
    self = [super init];
    if (self) 
    {
        self.sprite = initSprite;
        self.animClip = nil;
        self.texture = tex;
        self.pos = givenPos;
        self.vel = givenVel;
        
        // default fade
        [self setFade:1.0f fromColorRed:1 green:1 blue:1 alpha:1];
        
        // HACK
        // non-animated effects are assumed to be Text for now; so, add it to the PointsHud bucket
        renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"PointsHud"];
        // HACK

        [self setConfigurablesToDefault];
    }
    
    return self;    
}


- (void) dealloc
{
    self.texture = nil;
    self.animClip = nil;
    self.sprite = nil;
    [super dealloc];
}

- (void) spawnRotatedBy:(float)angle
{
    [self spawn];
    rotate = angle;
}

- (void) spawn
{
    [[DynamicManager getInstance] addObject:self];
    if([self animClip])
    {
        [[AnimProcessor getInstance] addClip:self.animClip];
        [self.animClip playClipForward:YES];
    }
}

- (void) kill
{
    if([self animClip])
    {
        [[AnimProcessor getInstance] removeClip:self.animClip];
    }
    [[DynamicManager getInstance] removeObject:self];
}

- (void) setFade:(float)fadeDuration fromColorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    self.duration = fadeDuration;
    self.fadePoint = 0.25f * fadeDuration;
    
    colorR = red;
    colorG = green;
    colorB = blue;
    colorA = alpha;
    
    if(0.0f < fadePoint)
    {
        self.fadeDecr = -1.0f / [self fadePoint];
    }
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
    if([self animClip])
    {
        AnimFrame* curFrame = [[self animClip] currentFrame];
        instanceData.texture = [[curFrame texture] texName];
        
        CGPoint newScale = CGPointMake([curFrame renderScale].x * scale.x,
                                       [curFrame renderScale].y * scale.y);
        instanceData.scale = newScale;
        instanceData.rotate = [curFrame renderRotate] + RadiansToDegrees(rotate);
        instanceData.texcoordScale = CGPointMake(([[curFrame texture] getImageWidthTexcoord] * [curFrame scale].x),
                                                 ([[curFrame texture] getImageHeightTexcoord] * [curFrame scale].y));
        instanceData.texcoordTranslate = [curFrame translate];
        instanceData.colorR = colorR * [curFrame colorR];
        instanceData.colorG = colorG * [curFrame colorG];
        instanceData.colorB = colorB * [curFrame colorB];
        instanceData.alpha = colorA * [curFrame colorA];
    }
    else
    {
        instanceData.scale = scale;
        instanceData.rotate = RadiansToDegrees(rotate);
        instanceData.texture = [[self texture] texName];
        instanceData.colorR = colorR;
        instanceData.colorG = colorG;
        instanceData.colorB = colorB;
        instanceData.alpha = colorA;
    }
    instanceData.pos = self.pos;
	DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:self.sprite DrawData:instanceData];
	[[RenderBucketsManager getInstance] addCommand:cmd toBucket:renderBucketIndex];
	[instanceData release];
    [cmd release];
}

- (void) updateBehavior:(NSTimeInterval)elapsed
{
    CGPoint newPos = CGPointMake(pos.x + (vel.x * elapsed), pos.y + (vel.y * elapsed));
    pos = newPos;
    
    if([self animClip])
    {
        if(ANIMCLIP_STATE_DONE == self.animClip.playbackState)
        {
            [self kill];
        }
    }
    else if([self texture])
    {
        self.duration -= elapsed;
        if([self duration] <= [self fadePoint])
        {
            self.colorA += (elapsed * [self fadeDecr]);
        }
        if([self duration] <= 0.0f)
        {
            [self kill];
        }
    }
}

@end
