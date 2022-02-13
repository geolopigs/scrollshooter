//
//  FloatingLayer.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/15/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "FloatingLayer.h"
#import "LevelConfig.h"
#import "LevelAnimData.h"
#import "LevelManager.h"
#import "Level.h"
#import "Sprite.h"
#import "Texture.h"
#import "RenderBucketsManager.h"
#import "TopCam.h"
#import "TopCamRenderer.h"
#import "CamPath.h"
#import "GameManager.h"
#import "AnimClip.h"
#import "AnimSprite.h"
#import "AnimFrame.h"

@implementation FloatingLayer
@synthesize layerName;
@synthesize textureNames;
@synthesize textures;
@synthesize sprites;
@synthesize animSprites;
@synthesize layerDistance;
@synthesize isDynamics;
@synthesize scrollPath;
@synthesize drawCmd;
@synthesize drawData;


- (id) initFromLayerConfig:(NSDictionary*)layerConfig levelAnimData:(LevelAnimData *)levelAnimData
{
    self = [super init];
    if(self)
    {
        self.layerName = [layerConfig objectForKey:@"layerName"];
        self.textureNames = [layerConfig objectForKey:@"textures"];
        self.layerDistance = [[layerConfig objectForKey:@"layerDistance"] floatValue];
        self.isDynamics = [[layerConfig objectForKey:@"isDynamics"] boolValue];

        RenderBucketsManager* bucketsMgr = [RenderBucketsManager getInstance];
        NSString* insertionPointName;
        if(self.isDynamics)
        {
            // insert all new buckets right before the frontmost layer (so that they draw after game dynamic objects)
            insertionPointName = @"FrontLayer";
        }
        else
        {
            // insert all new buckets before ground dynamics
            insertionPointName = @"GrPreDynamics";
        }
        
        renderBucketShadows = [bucketsMgr newBucketBeforeBucketNamed:insertionPointName withName:[NSString stringWithFormat:@"%@_shadows", layerName]];
        renderBucket = [bucketsMgr newBucketBeforeBucketNamed:insertionPointName withName:layerName];
        renderBucketAddons = [bucketsMgr newBucketBeforeBucketNamed:insertionPointName withName:[NSString stringWithFormat:@"%@_addons", layerName]];
                 
        // load up texture library
        self.textures = [NSMutableArray arrayWithCapacity:10];
        for(NSString* name in textureNames)
        {
            NSString* animName = [name stringByDeletingPathExtension];
            if([levelAnimData getClipForName:animName])
            {
                // if name exists in the anim lib, don't load this texture, place a NULL placeholder 
                // in the texture lib array because the game will never use this
                [textures addObject:[NSNull null]];
            }
            else
            {
                Texture* newTex = [[Texture alloc] initFromFileName:name];
                [textures addObject:newTex];
                [newTex release];
            }
        }
        
        NSArray* spriteConfigs = [layerConfig objectForKey:@"sprites"];

        
        // instantiate sprites
        self.sprites = [NSMutableArray arrayWithCapacity:10];
        self.animSprites = [NSMutableArray array];
        for(NSDictionary* cur in spriteConfigs)
        {
            float posx = [[cur objectForKey:@"posX"] floatValue];
            float posy = [[cur objectForKey:@"posY"] floatValue];
            float scalex = [[cur objectForKey:@"scaleX"] floatValue];
            float scaley = [[cur objectForKey:@"scaleY"] floatValue];
            float width = [[cur objectForKey:@"width"] floatValue];
            float height = [[cur objectForKey:@"height"] floatValue];
            float rotate = [[cur objectForKey:@"rotate"] floatValue];
            Sprite* newSprite = [[Sprite alloc] initWithSize:CGSizeMake(width, height)];
            newSprite.pos = CGPointMake(posx, posy);
            newSprite.scale = CGPointMake(scalex, scaley);
            newSprite.rotate = rotate;

            // a sprite is animated if its texture name appears in the level anim data
            // otherwise, create a static sprite
            unsigned int textureID = [[cur objectForKey:@"textureID"] unsignedIntValue];
            NSString* textureName = [textureNames objectAtIndex:textureID];
            NSString* animName = [textureName stringByDeletingPathExtension];
            AnimClipData* clipData = [levelAnimData getClipForName:animName];
            if(clipData)
            {
                // has anim, create an AnimSprite and add it to the animSprites list
                AnimClip* newClip = [[AnimClip alloc] initWithClipData:clipData];
                AnimFrame* curFrame = [newClip currentFrame];
                Texture* curTexture = [curFrame texture];
                newSprite.texcoordScale = CGPointMake([curTexture getImageWidthTexcoord], [curTexture getImageHeightTexcoord]);
                
                AnimSprite* newAnimSprite = [[AnimSprite alloc] initWithSprite:newSprite animClip:newClip];
                [animSprites addObject:newAnimSprite];
                [newAnimSprite release];
                [newClip release];
            }
            else
            {
                // otherwise, create a static sprite
                Texture* curTexture = [textures objectAtIndex:[[cur objectForKey:@"textureID"] unsignedIntValue]];
                GLuint tex = [curTexture texName];                
                newSprite.texcoordScale = CGPointMake([curTexture getImageWidthTexcoord], [curTexture getImageHeightTexcoord]);
                newSprite.tex = tex;
                [sprites addObject:newSprite];
            }
            [newSprite release];
        }
        
        // spawn all the anim here
        [self spawnAllAnimSprites];

        // NOTE: guns and cargos are added in a separate function because they potentitally cache
        // off render-bucket indices; so, need to do them all at once after all the layers have
        // added their buckets and adjusted existing bucket indices accordingly

        self.scrollPath = nil;
        self.drawCmd = nil;
        self.drawData = nil;
    }
    return self;
}


- (void) dealloc
{
    // kill all the anim here
    [self killAllAnimSprites];
    
    self.drawCmd = nil;
    self.drawData = nil;
    self.scrollPath = nil;
    [sprites release];
    self.animSprites = nil;
    [textures release];
    [textureNames release];
    [super dealloc];
}

- (void) spawnAllAnimSprites
{
    for(AnimSprite* cur in animSprites)
    {
        [cur spawn];
    } 
}

- (void) killAllAnimSprites
{
    for(AnimSprite* cur in animSprites)
    {
        [cur kill];
    }
}

- (void) addDraw
{
    for(AnimSprite* cur in animSprites)
    {
        SpriteInstance* instanceData = [[SpriteInstance alloc] init];
        AnimFrame* curFrame = [[cur anim] currentFrame];
        Sprite* curSprite = [cur sprite];
        instanceData.pos = curSprite.pos;
        instanceData.texture = [[curFrame texture] texName];
        instanceData.scale = [curSprite scale];
        instanceData.rotate = [curFrame renderRotate] + [curSprite rotate];
        instanceData.texcoordScale = CGPointMake(([[curFrame texture] getImageWidthTexcoord] * [curFrame scale].x),
                                                 ([[curFrame texture] getImageHeightTexcoord] * [curFrame scale].y));
        instanceData.texcoordTranslate = [curFrame translate];
        DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:cur.sprite DrawData:instanceData];
        [[RenderBucketsManager getInstance] addCommand:cmd toBucket:renderBucket];
        [instanceData release];
        [cmd release];
    }
    for(Sprite* cur in sprites)
    {
        SpriteInstance* curDrawData = [[SpriteInstance alloc] init];
        curDrawData.pos = cur.pos;
        curDrawData.texture = cur.tex;
        curDrawData.scale = cur.scale;
        curDrawData.rotate = cur.rotate;
        curDrawData.texcoordScale = cur.texcoordScale;
        DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:cur DrawData:curDrawData];
        [[RenderBucketsManager getInstance] addCommand:cmd toBucket:renderBucket];
        [cmd release];     
        [curDrawData release];
    }
}

- (void) createSpawnersInLayer:(NSDictionary*)layerConfig
{
    // guns and cargos in this layer
    NSArray* placementNames = [NSArray arrayWithObjects:@"guns", @"cargos", nil];
    for(NSString* curName in placementNames)
    {
        NSArray* curConfigs = [layerConfig objectForKey:curName];
        if([curConfigs count])
        {
            // HACK - assumes that all guns in a given layer is of the same type and same spawner
            // so, just use the first gun's name and trigger name
            NSString* spawnerName = [NSString stringWithFormat:@"%@_Spawner", [[curConfigs objectAtIndex:0] objectForKey:@"spawnerType"]];
            NSString* objectName = [[curConfigs objectAtIndex:0] objectForKey:@"objectType"];
            NSString* triggerName = [[curConfigs objectAtIndex:0] objectForKey:@"triggerName"];  
            // HACK
            
            NSMutableArray* positions = [NSMutableArray arrayWithCapacity:[curConfigs count]];
            for(NSDictionary* cur in curConfigs)
            {
                float posx = [[cur objectForKey:@"posX"] floatValue];
                float posy = [[cur objectForKey:@"posY"] floatValue];
                [positions addObject:[NSValue valueWithCGPoint:CGPointMake(posx,posy)]];
            }
            [[GameManager getInstance] addNewGroundSpawnerWithName:spawnerName 
                                                    positionsArray:positions 
                                                     layerDistance:layerDistance
                                               renderBucketShadows:renderBucketShadows
                                                      renderBucket:renderBucket
                                                renderBucketAddons:renderBucketAddons
                                                     forObjectType:objectName
                                                            asName:triggerName];
        }                    
    }
}

#pragma mark -
#pragma mark LayerCameraDelegate
- (void) addDrawCommandForCamera:(TopCam*)camera
{
    // only scale origin in the forward/backward direction; scaling it sideways
    // is disorienting for the user
    // also, if a scrollPath exists for this layer, use its position for y
    CGPoint camOrigin = [camera camOriginAtLayerDistance:[camera distanceMaxLayer]];
    if(self.scrollPath)
    {
        CGPoint curPoint = [self.scrollPath getCurFollow];
        CGPoint camPoint = [camera camWorldPointAtLayerDistance:[self layerDistance] fromWorldPoint:curPoint];
        camOrigin.y = camPoint.y;
    }
    else
    {
        CGPoint camOriginInLayer = [camera camOriginAtLayerDistance:[self layerDistance]];
        camOrigin.y = camOriginInLayer.y;
    }
    
    // IMPORTANT: the x-pos of the camera is not adjusted because in gameplay space, the camera x-axis is the same as the world x-axis;
    // the camera position gets adjusted for the view transform to throw the view left and right, this adjustment is in dynamicPos
    // see offsetPosByPlayer in TopCam
    camOrigin.x = camera.dynamicPos.x;
    
    if(nil == self.drawCmd)
    {
        assert(!self.drawData);
        
        TopCamInstance* newData = [[TopCamInstance alloc] initWithCamOrigin:camOrigin];
        self.drawData = newData;
        [newData release];
        DrawCommand* newCmd = [[DrawCommand alloc] initWithDrawDelegate:camera.renderer DrawData:self.drawData];
        self.drawCmd = newCmd;
        [newCmd release];
    }
    else
    {
        self.drawData.origin = camOrigin;
    }
    
    RenderBucketsManager* bucketMgr = [RenderBucketsManager getInstance];
    [bucketMgr addCommand:self.drawCmd toBucket:renderBucketShadows];
    [bucketMgr addCommand:self.drawCmd toBucket:renderBucket];
    [bucketMgr addCommand:self.drawCmd toBucket:renderBucketAddons];
    
}

@end
