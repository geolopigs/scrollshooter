//
//  EffectFactory.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "EffectFactory.h"
#import "Effect.h"
#import "LevelAnimData.h"
#import "EffectArchetype.h"
#import "TextEffectType.h"
#import "AnimClip.h"
#import "Sprite.h"
#import "GameObjectSizes.h"
#import "LevelManager.h"
#import "StatsManager.h"
#import "EnemyRegistryData.h"

@interface EffectFactory (PrivateMethods)
- (void) populateArchetypeLibFromLevelAnimData:(LevelAnimData*)data;
- (void) createTextEffectTypes;
@end

@implementation EffectFactory
@synthesize archetypeLib;

#pragma mark -
#pragma mark Public Methods

+ (void) effectNamed:(NSString *)name atPos:(CGPoint)initPos rotated:(float)angle
{
    Effect* hitEffect = [[[LevelManager getInstance] effectFactory] createEffectNamed:name atPos:initPos];
    hitEffect.rotate = angle;
    [hitEffect spawn];
    [hitEffect release];
}

+ (void) effectNamed:(NSString *)name atPos:(CGPoint)initPos
{
    [self effectNamed:name atPos:initPos rotated:0.0f];
}

+ (void) textEffectFor:(NSString*)enemyTypeName 
                 atPos:(CGPoint)initPos 
{
    [EffectFactory textEffectFor:enemyTypeName 
                           atPos:initPos
                         withVel:CGPointMake(0.0f, 15.0f)
                           scale:CGPointMake(0.5f, 0.5f)
                        duration:1.0f
                       colorRed:1 green:1 blue:1 alpha:1];
}


+ (void) textEffectFor:(NSString*)enemyTypeName 
                    atPos:(CGPoint)initPos 
                  withVel:(CGPoint)initVel 
                 scale:(CGPoint)initScale
                 duration:(float)effectDuration
                colorRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    NSString* textEffectName = [NSString stringWithFormat:@"%@Pts", enemyTypeName];
    Effect* textEffect = [[[LevelManager getInstance] effectFactory] createEffectNamed:textEffectName atPos:initPos withVel:initVel];
    [textEffect setFade:effectDuration fromColorRed:red green:green blue:blue alpha:alpha];
    [textEffect setScale:initScale];
    [textEffect spawn];
    [textEffect release];    
}

+ (void) textEffectForMultiplier:(unsigned int)multiplier atPos:(CGPoint)initPos
{
    static const float velY = 3.0f;
    static const float posYOffset = 3.0f;
    static const float fadeDur = 1.0f;
    static const float digitPosX = 10.7f;
    static const float digitSpacing = 3.3f;
    float multiplierTextOffsetX = 8.0f;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        multiplierTextOffsetX = 10.5f;
    }
    NSString* multText = [NSString stringWithFormat:@"%d",multiplier];
    unsigned int digit = 0;
    CGPoint pos = CGPointMake(initPos.x, initPos.y + posYOffset);
    pos.x += digitPosX;
    while(digit < [multText length])
    {
        unichar digitChar = [multText characterAtIndex:digit];
        NSString* effectName = [NSString stringWithFormat:@"%c", digitChar];
        Effect* effect = [[[LevelManager getInstance] effectFactory] createEffectNamed:effectName 
                                                                                 atPos:pos 
                                                                               withVel:CGPointMake(0.0f, velY)];
        [effect setFade:fadeDur fromColorRed:1.0f green:0.38f blue:0.28f alpha:1.0f];
        [effect setScale:CGPointMake(0.5f, 0.5f)];
        [effect spawn];
        [effect release];
        
        pos.x += digitSpacing;
        ++digit;
    }
    
    // spawn the text Multiplier
    pos.x = initPos.x - multiplierTextOffsetX;
    Effect* multiplierEffect = [[[LevelManager getInstance] effectFactory] createEffectNamed:@"multiplier"
                                                                                       atPos:pos 
                                                                                     withVel:CGPointMake(0.0f, velY)];
    [multiplierEffect setFade:fadeDur fromColorRed:1.0f green:0.38f blue:0.28f alpha:1.0f];
    [multiplierEffect setScale:CGPointMake(0.5f, 0.5f)];
    [multiplierEffect spawn];
    [multiplierEffect release];
   
}

- (id) initWithLevelAnimData:(LevelAnimData*)data 
{
    self = [super init];
    if (self) 
    {
        self.archetypeLib = [NSMutableDictionary dictionary];
        [self populateArchetypeLibFromLevelAnimData:data];
        [self createTextEffectTypes];
    }
    
    return self;
}

- (void) dealloc
{
    self.archetypeLib = nil;
    [super dealloc];
}

- (Effect*) createEffectNamed:(NSString*)name atPos:(CGPoint)initPos
{
    Effect* newEffect = [self createEffectNamed:name atPos:initPos withVel:CGPointMake(0.0f, 0.0f)];    
    return newEffect;
}

- (Effect*) createEffectNamed:(NSString*)name atPos:(CGPoint)initPos withVel:(CGPoint)initVel
{
    Effect* newEffect = nil;
    NSObject<EffectTypeDelegate>* archetype = [archetypeLib objectForKey:name];
    assert(archetype);
    Sprite* newSprite = [[Sprite alloc] initWithSize:[archetype effectSize] colSize:[archetype effectSize]];
    if([archetype effectClipData])
    {
        // effect has animation data, create one with an AnimClip;
        AnimClip* newClip = [[AnimClip alloc] initWithClipData:[archetype effectClipData]];
        newEffect = [[Effect alloc] initWithClip:newClip sprite:newSprite atPos:initPos withVel:initVel];
        [newClip release];
    }
    else
    {
        // no clip, just a textured effect
        newEffect = [[Effect alloc] initWithTexture:[archetype effectTexture] sprite:newSprite atPos:initPos withVel:initVel];        
    }
    [newSprite release];
    
    return newEffect;
}


#pragma mark -
#pragma mark Private Methods
- (void) populateArchetypeLibFromLevelAnimData:(LevelAnimData*)data
{    
    NSArray* effectNames = [data effectsClipnames];
    for(NSString* curName in effectNames)
    {
        CGSize curSize = CGSizeMake(30.0f, 30.0f);
        curSize = [[GameObjectSizes getInstance] renderSizeFor:curName];
        NSObject<EffectTypeDelegate>* newType = [[EffectArchetype alloc] initWithClipData:[data getClipForName:curName] 
                                                                     andSize:curSize];
        [archetypeLib setObject:newType forKey:curName];
        [newType release];
    }  
}

- (void) createTextEffectTypes
{
    EnemyRegistryData* enemyReg = [[StatsManager getInstance] enemyReg];
    unsigned int numEnemies = [enemyReg numItems];
    unsigned int cur = 0;
    static const float TEXTSIZE_SCREENWIDTH_FACTOR = 32.0f / 320.0f;
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    float textSizeForScreen = screenWidth * TEXTSIZE_SCREENWIDTH_FACTOR;
    while(cur < numEnemies)
    {
        NSString* name = [enemyReg getNameAtIndex:cur];
        int points = [enemyReg getPointsForEnemyNamed:name];
        NSString* text = [NSString stringWithFormat:@"+%d",points];
        NSString* effectName = [NSString stringWithFormat:@"%@Pts", name];
        NSObject<EffectTypeDelegate>* effectType = [archetypeLib objectForKey:text];
        if(nil == effectType)
        {
            // if no effect exists for this point number yet, create it
            int textSize = static_cast<int>(textSizeForScreen);
            if(points >= 100)
            {
                textSize *= 2;
            }
            effectType = [[TextEffectType alloc] initWithString:text withFontNamed:@"Helvetica-Bold" atRes:textSize];
            
            // add it to archetypeLib to be reused by enemies with the same points
            [archetypeLib setObject:effectType forKey:text];
            [effectType release];
        }
        [archetypeLib setObject:effectType forKey:effectName];
        
        ++cur;
    }
    
    // create number digits
    int digitSize = static_cast<int>(textSizeForScreen * 1.3f);
    for(unsigned int i = 0; i < 10; ++i)
    {
        NSString* text = [NSString stringWithFormat:@"%d", i];
        NSObject<EffectTypeDelegate>* effectType = [[TextEffectType alloc] initWithString:text withFontNamed:@"Helvetica-Bold" atRes:digitSize];
        [archetypeLib setObject:effectType forKey:text];
        [effectType release];
    }
    
    // create multiplier text
    NSObject<EffectTypeDelegate>* multiplierEffect = [[TextEffectType alloc] initWithString:@"Multiplier x"
                                                                              withFontNamed:@"Helvetica-Bold"
                                                                                      atRes:digitSize];
    [archetypeLib setObject:multiplierEffect forKey:@"multiplier"];
    [multiplierEffect release];
}

@end
