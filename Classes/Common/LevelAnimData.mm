//
//  LevelAnimData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/31/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LevelAnimData.h"
#import "Texture.h"
#import "AnimFrame.h"
#import "AnimClipData.h"
#import "GameManager.h"
#import "PlayerInventoryIds.h"

@interface LevelAnimData (PrivateMethods)
+ (BOOL) array:(NSArray*)array containsString:(NSString*)queryString;
- (NSArray*) excludeListForFlyerType:(NSString*)flyerType;
- (void) loadAndInitClipLib:(NSMutableDictionary*)clipLib fromData:(NSDictionary*)givenData excludeClips:(NSArray*)excludeList;
- (void) initEffectsClipnamesFromData:(NSDictionary*)givenData;
@end

@implementation LevelAnimData
@synthesize fileData;
@synthesize animClipLib;
@synthesize effectsClipnames;
@synthesize levelSpecificFileData;
@synthesize levelSpecificAnimClipLib;

- (id) initFromFileCommon:(NSString*)commonName levelSpecific:(NSString*)levelSpecificName
{
    self = [super init];
    if (self) 
    {
        // effectsClipnames are combined from level-specific and common
        self.effectsClipnames = [NSMutableArray array];

        // load level specific clips first
        self.levelSpecificFileData = nil;
        self.levelSpecificAnimClipLib = nil;
        if(levelSpecificName)
        {
            NSString* specificPath = [[NSBundle mainBundle] pathForResource:levelSpecificName ofType:@"plist"];
            self.levelSpecificFileData = [NSDictionary dictionaryWithContentsOfFile:specificPath];
            self.levelSpecificAnimClipLib = [NSMutableDictionary dictionary];
            [self loadAndInitClipLib:levelSpecificAnimClipLib fromData:levelSpecificFileData excludeClips:nil];
            [self initEffectsClipnamesFromData:levelSpecificFileData];
        }

        // then load common clips
        NSString *path = [[NSBundle mainBundle] pathForResource:commonName ofType:@"plist"];
        self.fileData = [NSDictionary dictionaryWithContentsOfFile:path];
        self.animClipLib = [NSMutableDictionary dictionary];
        
        NSArray* excludeList = [self excludeListForFlyerType:[[GameManager getInstance] flyerType]];
        [self loadAndInitClipLib:animClipLib fromData:fileData excludeClips:excludeList];
        [self initEffectsClipnamesFromData:fileData];
    }
    return self;
}

- (void) dealloc
{
    self.levelSpecificAnimClipLib = nil;
    self.levelSpecificFileData = nil;
    self.effectsClipnames = nil;
    self.animClipLib = nil;
    self.fileData = nil;
    [super dealloc];
}

- (AnimClipData*) getClipForName:(NSString *)name
{
    AnimClipData* result = nil;
    
    // look in level-specific cliplib first before the common lib
    if(levelSpecificAnimClipLib)
    {
        result = [levelSpecificAnimClipLib objectForKey:name];
    }
    if(!result)
    {    
        result = [animClipLib objectForKey:name];
    }
    return result;
}

#pragma mark -
#pragma mark Private Methods

+ (BOOL) array:(NSArray*)array containsString:(NSString *)queryString
{
    BOOL result = NO;
    
    for(NSString* cur in array)
    {
        if([cur isEqualToString:queryString])
        {
            result = YES;
            break;
        }
    }
    
    return result;
}

- (NSArray*) excludeListForFlyerType:(NSString *)flyerType
{
    NSArray* result = nil;
    if([flyerType isEqualToString:(NSString*)FLYER_TYPE_POGWING])
    {
        result = [NSArray arrayWithObjects:@"AutoFireShot", @"Missile", @"MissileTrail", @"Boomerang", @"BoomerangTrail", @"FlyerShadow", @"PograngShadow", @"DoubleBulletUpgrade", @"BoomerangUpgrade", nil];
    }
    else if([flyerType isEqualToString:(NSString*)FLYER_TYPE_POGRANG])
    {
        result = [NSArray arrayWithObjects:@"AutoFireShot", @"Missile", @"MissileTrail", @"BlueLaser", @"BlueLaserInit", @"BlueLaserGone", @"BlueTrail", @"FlyerShadow", @"PogwingShadow", @"DoubleBulletUpgrade", @"LaserUpgrade", nil];
    }
    else
    {
        // Poglider
        result = [NSArray arrayWithObjects:@"Boomerang", @"BoomerangTrail", @"BlueLaser", @"BlueLaserInit", @"BlueLaserGone", @"BlueTrail", @"PograngShadow", @"PogwingShadow", @"BoomerangUpgrade", @"LaserUpgrade", nil];
    }
    return result;
}

- (void) loadAndInitClipLib:(NSMutableDictionary*)clipLib fromData:(NSDictionary*)givenData excludeClips:(NSArray *)excludeList
{
    NSArray* animClipsArray = [givenData objectForKey:@"animClips"];
    NSArray* effectsClipsArray = [givenData objectForKey:@"effectsClips"];
    NSArray* clipArraysInFile = [NSArray arrayWithObjects:animClipsArray, effectsClipsArray, nil];
    NSMutableDictionary* texLib = [NSMutableDictionary dictionary];

    for(NSArray* clipArray in clipArraysInFile)
    {
        for(NSDictionary* curClipData in clipArray)
        {
            NSString* clipName = [curClipData objectForKey:@"name"];
            
            if(excludeList && ([LevelAnimData array:excludeList containsString:clipName]))
            {
                // skip this clip listed in the exclude-list
            }
            else
            {
                // only load this anim if one with redundant name (from level-specific load) does not exist
                if(![self getClipForName:clipName])
                {
                    NSArray* framesInData = [curClipData objectForKey:@"animFrames"];
                    
                    // collect all the unique texture filenames
                    NSMutableSet* texLibNames = [NSMutableSet set];
                    for(NSDictionary* curDict in framesInData)
                    {
                        [texLibNames addObject:[curDict objectForKey:@"texture"]];
                    }
                    
                    // load unique textures
                    //                NSMutableDictionary* texLib = [NSMutableDictionary dictionaryWithCapacity:[texLibNames count]];
                    for(NSString* curName in texLibNames)
                    {
                        if(![texLib objectForKey:curName])
                        {
                            Texture* newTex = [[Texture alloc] initFromFileName:curName];
                            [texLib setObject:newTex forKey:curName];
                            [newTex release];
                        }
                    }
                    
                    // create anim frames
                    NSMutableArray* frames = [NSMutableArray arrayWithCapacity:[framesInData count]];
                    for(NSDictionary* curDict in framesInData)
                    {
                        NSString* curTextureName = [curDict objectForKey:@"texture"];
                        CGPoint curTextureScale = CGPointMake([[curDict objectForKey:@"texScaleX"] floatValue], [[curDict objectForKey:@"texScaleY"] floatValue]);
                        CGPoint curTextureTranslate = CGPointMake([[curDict objectForKey:@"texTranslateX"] floatValue], [[curDict objectForKey:@"texTranslateY"] floatValue]);
                        AnimFrame* newFrame = [AnimFrame alloc];
                        CGPoint curScale = CGPointMake(1.0f, 1.0f);
                        float curRotate = 0.0f;
                        if(([curDict objectForKey:@"scaleX"]) && ([curDict objectForKey:@"scaleY"]))
                        {
                            curScale = CGPointMake([[curDict objectForKey:@"scaleX"] floatValue], [[curDict objectForKey:@"scaleY"] floatValue]);
                        }
                        
                        if([curDict objectForKey:@"rotateZ"])
                        {
                            curRotate = [[curDict objectForKey:@"rotateZ"] floatValue];
                        }
                        
                        // HACK - there is no translate from the data file yet; so, renderTranslate is always (0,0) here
                        [newFrame initWithTexture:[texLib objectForKey:curTextureName] scale:curTextureScale translate:curTextureTranslate renderScale:curScale renderTranslate:CGPointMake(0.0f,0.0f) renderRotate:curRotate];
                        
                        // color
                        NSNumber* colorR = [curDict objectForKey:@"colorR"];
                        NSNumber* colorG = [curDict objectForKey:@"colorG"];
                        NSNumber* colorB = [curDict objectForKey:@"colorB"];
                        NSNumber* colorA = [curDict objectForKey:@"colorA"];
                        if(colorR && colorG && colorB && colorA)
                        {
                            // override the color of this frame
                            newFrame.colorR = [colorR floatValue];
                            newFrame.colorG = [colorG floatValue];
                            newFrame.colorB = [colorB floatValue];
                            newFrame.colorA = [colorA floatValue];
                        }
                        
                        [frames addObject:newFrame];
                        [newFrame release];
                    }
                    
                    // create animClipData
                    float fps = [[curClipData objectForKey:@"framesPerSec"] floatValue];
                    BOOL isLooping = [[curClipData objectForKey:@"isLooping"] boolValue];
                    AnimClipData* newClipData = [[AnimClipData alloc] initWithFrameRate:fps isLooping:isLooping];
                    for(AnimFrame* frame in frames)
                    {
                        [newClipData addFrame:frame];
                    }
                    [clipLib setObject:newClipData forKey:clipName];
                    [newClipData release];
                }
            }
        }
    }
    /*
    NSLog(@"total tex %d",[texLib count]);
    for(NSString* texName in texLib)
    {
        NSLog(@"%@",texName);
    }*/
}

- (void) initEffectsClipnamesFromData:(NSDictionary *)givenData
{
    NSArray* effectsClipsArray = [givenData objectForKey:@"effectsClips"];
    // collect the names of effects clips for use in initializing the EffectFactory
    for(NSDictionary* curClipData in effectsClipsArray)
    {
        NSString* name = [curClipData objectForKey:@"name"];
        if(![effectsClipnames containsObject:name])
        {
            [effectsClipnames addObject:name];
        }
    }    
}

@end
