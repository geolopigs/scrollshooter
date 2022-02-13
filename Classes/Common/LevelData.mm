//
//  LevelData.mm
//  Pogditor
//
//  Created by Shu Chiun Cheah on 7/20/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LevelData.h"
#import "SpriteLayerData.h"
#import "LevelTileData.h"

@interface LevelData (PrivateMethods)
- (void) defaultBackgroundValues;
- (void) defaultGameCameraValues;
- (void) initBgTriggers;
- (void) backgroundLayerDataFromPlist;
- (void) cameraDataFromPlist;
- (void) floatingLayersDataFromPlist;
- (void) commitAddonsDataToPlist;
@end


@implementation LevelData
@synthesize numTiles;
@synthesize tileWidth;
@synthesize tileHeight;
@synthesize tileTexWidth;
@synthesize tileTexHeight;
@synthesize bgTiles;
@synthesize floatingLayerData;
@synthesize bgTriggers;
@synthesize cameraFrameWidth;
@synthesize cameraFrameHeight;

@synthesize floatingLayers;
@synthesize isAddonsData;
@synthesize delegates;
@synthesize plist;

- (id)init
{
    self = [super init];
    if (self) 
    {
        self.bgTiles = [NSMutableArray array];
        self.bgTriggers = [NSMutableArray array];
        self.floatingLayers = [NSMutableDictionary dictionary];
        self.floatingLayerData = [NSMutableArray array];
        self.isAddonsData = NO;
        self.delegates = [NSMutableArray array];
        self.plist = [NSMutableDictionary dictionary];
        [self defaultBackgroundValues];
        [self defaultGameCameraValues];
    }
    
    return self;
}

- (id) initFromPlist:(NSDictionary *)loadedPlist
{
    self = [super init];
    if(self)
    {
        self.plist = [NSMutableDictionary dictionaryWithDictionary:loadedPlist];
        
        self.bgTiles = [NSMutableArray array];
        [self backgroundLayerDataFromPlist];
        [self floatingLayersDataFromPlist];
        [self cameraDataFromPlist];
        self.floatingLayers = [NSMutableDictionary dictionary];
        self.delegates = [NSMutableArray array];
        if([self.plist objectForKey:@"addons"])
        {
            self.isAddonsData = YES;
        }
        else
        {
            self.isAddonsData = NO;
        }
    }
    return self;
}

- (void)dealloc
{
    [bgTriggers release];
    self.bgTiles = nil;
    [delegates release];
    [plist release];
    [floatingLayerData release];
    [floatingLayers release];
    [super dealloc];
}

// this function takes data from memory and commits them to the filedata to be writte out
- (void) commitData
{
    [self.floatingLayerData removeAllObjects];
    for(NSObject<LevelDataDelegate>*cur in delegates)
    {
        [cur commitToLevelData:self];
    }
    
    // background layer
    [self initBgTriggers];
    [self.plist setObject:[NSNumber numberWithUnsignedInteger:numTiles] forKey:@"numTiles"];
    [self.plist setObject:[NSNumber numberWithFloat:tileWidth] forKey:@"tileWidth"];
    [self.plist setObject:[NSNumber numberWithFloat:tileHeight] forKey:@"tileHeight"];
    [self.plist setObject:[NSNumber numberWithFloat:tileTexWidth] forKey:@"tileTexWidth"];
    [self.plist setObject:[NSNumber numberWithFloat:tileTexHeight] forKey:@"tileTexHeight"];    
    [self.plist setObject:self.bgTriggers forKey:@"bgTexTriggers"];
    
    NSMutableArray* tilesArrayPlist = [NSMutableArray array];
    for(LevelTileData* curTile in bgTiles)
    {
        NSMutableDictionary* newTileInPlist = [NSMutableDictionary dictionary];
        [newTileInPlist setObject:[curTile textureName] forKey:@"textureName"];
        [newTileInPlist setObject:[NSNumber numberWithInt:[curTile orientation]] forKey:@"orientation"];
        [tilesArrayPlist addObject:newTileInPlist];
    }
        
    [self.plist setObject:tilesArrayPlist forKey:@"bgTiles"];
    
    // floating layers
    if(0 < [self.floatingLayerData count])
    {
        /*
        // sort floatingLayerData in descending layerDistance
        NSMutableArray* sortedArray = [NSMutableArray array];
        for(SpriteLayerData* layer in self.floatingLayerData)
        {
            NSInteger index = [sortedArray count] - 1;
            while(0 <= index)
            {
                SpriteLayerData* compareLayer = [sortedArray objectAtIndex:index];
                if(compareLayer.layerDistance > layer.layerDistance)
                {
                    break;
                }
                --index;
            }
            if((index+1) >= [sortedArray count])
            {
                [sortedArray addObject:layer];
            }
            else
            {
                [sortedArray insertObject:layer atIndex:(index+1)];
            }            
        }
        */
        // clear existing floating layers data
        [self.plist removeObjectForKey:@"floatingLayers"];
        [self.plist removeObjectForKey:@"floatingLayersEditor"];
        NSMutableArray* floatingLayerPlist = [NSMutableArray array];
        NSMutableArray* floatingLayerPlistEditor = [NSMutableArray array];
        for(SpriteLayerData* layer in floatingLayerData)
        {
            NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
            NSMutableDictionary* newDictEditor = [NSMutableDictionary dictionary];
            [newDict setObject:layer.layerName forKey:@"layerName"];
            [newDict setObject:[NSNumber numberWithFloat:layer.layerDistance] forKey:@"layerDistance"];
            [newDict setObject:[NSNumber numberWithBool:layer.isDynamics] forKey:@"isDynamics"];
            NSMutableArray* texArray = [NSMutableArray array];
            for(NSString* curTexName in layer.textureNames)
            {
                [texArray addObject:curTexName];
            }
            [newDict setObject:texArray forKey:@"textures"];
            
            // sprites
            NSMutableArray* spriteArray = [NSMutableArray array];
            NSMutableArray* spriteArrayEditor = [NSMutableArray array];
            for(SpriteObject* curSprite in layer.spriteObjects)
            {
                NSMutableDictionary* spriteDict = [NSMutableDictionary dictionary];
                NSMutableDictionary* spriteDictEditor = [NSMutableDictionary dictionary];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.size.width] forKey:@"width"];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.size.height] forKey:@"height"];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.pos.x] forKey:@"posX"];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.pos.y] forKey:@"posY"];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.scale.x] forKey:@"scaleX"];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.scale.y] forKey:@"scaleY"];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.rotate] forKey:@"rotate"];
                [spriteDict setObject:[NSNumber numberWithUnsignedInteger:curSprite.textureId] forKey:@"textureID"];
                [spriteArray addObject:spriteDict];
                
                // editor portion
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.screenPos.x] forKey:@"screenPosX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.screenPos.y]forKey:@"screenPosY"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraPos.x] forKey:@"cameraPosX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraPos.y] forKey:@"cameraPosY"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraScale.x] forKey:@"cameraScaleX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraScale.y] forKey:@"cameraScaleY"];
                [spriteArrayEditor addObject:spriteDictEditor];
            }
            [newDict setObject:spriteArray forKey:@"sprites"];
            [newDictEditor setObject:spriteArrayEditor forKey:@"spritesEditor"];
            
            // guns
            NSMutableArray* gunArray = [NSMutableArray array];
            NSMutableArray* gunArrayEditor = [NSMutableArray array];
            for(GroundObject* curSprite in layer.gunObjects)
            {
                NSMutableDictionary* spriteDict = [NSMutableDictionary dictionary];
                NSMutableDictionary* spriteDictEditor = [NSMutableDictionary dictionary];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.pos.x] forKey:@"posX"];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.pos.y] forKey:@"posY"];
                [spriteDict setObject:[curSprite spawnerName] forKey:@"spawnerType"];
                [spriteDict setObject:[curSprite objectName] forKey:@"objectType"];
                [spriteDict setObject:[NSString stringWithFormat:@"%@_%@_%@", [curSprite objectName], [curSprite spawnerName], [layer layerName]] forKey:@"triggerName"];
                [gunArray addObject:spriteDict];
                
                // editor portion
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.size.width] forKey:@"width"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.size.height] forKey:@"height"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.screenPos.x] forKey:@"screenPosX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.screenPos.y]forKey:@"screenPosY"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraPos.x] forKey:@"cameraPosX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraPos.y] forKey:@"cameraPosY"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraScale.x] forKey:@"cameraScaleX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraScale.y] forKey:@"cameraScaleY"];

                [gunArrayEditor addObject:spriteDictEditor];
            }
            [newDict setObject:gunArray forKey:@"guns"];
            [newDictEditor setObject:gunArrayEditor forKey:@"gunsEditor"];
            
            // cargos
            NSMutableArray* cargoArray = [NSMutableArray array];
            NSMutableArray* cargoArrayEditor = [NSMutableArray array];
            for(GroundObject* curSprite in layer.cargoObjects)
            {
                NSMutableDictionary* spriteDict = [NSMutableDictionary dictionary];
                NSMutableDictionary* spriteDictEditor = [NSMutableDictionary dictionary];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.pos.x] forKey:@"posX"];
                [spriteDict setObject:[NSNumber numberWithFloat:curSprite.pos.y] forKey:@"posY"];
                [spriteDict setObject:[curSprite spawnerName] forKey:@"spawnerType"];
                [spriteDict setObject:[curSprite objectName] forKey:@"objectType"];
                [spriteDict setObject:[NSString stringWithFormat:@"%@_%@_%@", [curSprite objectName], [curSprite spawnerName], [layer layerName]] forKey:@"triggerName"];
                [cargoArray addObject:spriteDict];
                
                // editor portion
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.size.width] forKey:@"width"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.size.height] forKey:@"height"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.screenPos.x] forKey:@"screenPosX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.screenPos.y]forKey:@"screenPosY"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraPos.x] forKey:@"cameraPosX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraPos.y] forKey:@"cameraPosY"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraScale.x] forKey:@"cameraScaleX"];
                [spriteDictEditor setObject:[NSNumber numberWithFloat:curSprite.cameraScale.y] forKey:@"cameraScaleY"];
                [cargoArrayEditor addObject:spriteDictEditor];
            }
            [newDict setObject:cargoArray forKey:@"cargos"];
            [newDictEditor setObject:cargoArrayEditor forKey:@"cargosEditor"];            
            
            [floatingLayerPlist addObject:newDict];
            [floatingLayerPlistEditor addObject:newDictEditor];

        }
        [self.plist setObject:floatingLayerPlist forKey:@"floatingLayers"];
        [self.plist setObject:floatingLayerPlistEditor forKey:@"floatingLayersEditor"];
    }
    
    // game camera
    NSMutableDictionary* gameCameraDict = [NSMutableDictionary dictionary];
    [gameCameraDict setObject:[NSNumber numberWithFloat:cameraFrameWidth] forKey:@"frameWidth"];
    [gameCameraDict setObject:[NSNumber numberWithFloat:cameraFrameHeight] forKey:@"frameHeight"];
    [gameCameraDict setObject:[NSNumber numberWithFloat:cameraFrameX] forKey:@"frameX"];
    [gameCameraDict setObject:[NSNumber numberWithFloat:cameraFrameY] forKey:@"frameY"];     
    [gameCameraDict setObject:[NSNumber numberWithFloat:gameplayLayerDistance] forKey:@"gameplayLayerDistance"];
    [gameCameraDict setObject:[NSNumber numberWithFloat:maxLayerDistance] forKey:@"maxLayerDistance"];
    [self.plist setObject:gameCameraDict forKey:@"gameCamera"];
    
    [self commitAddonsDataToPlist];
}

- (void) addDelegate:(NSObject<LevelDataDelegate> *)delegate
{
    [self.delegates addObject:delegate];
}
- (void) removeDelegate:(NSObject<LevelDataDelegate> *)delegate
{
    [self.delegates removeObject:delegate];
}


#pragma mark -
#pragma mark Private Methods
- (void) defaultBackgroundValues
{
    numTiles = 20;
    tileWidth = 125.0f;
    tileHeight = 80.0f;
    tileTexWidth = 800.0f;
    tileTexHeight = 512.0f;
}

- (void) defaultGameCameraValues
{
    cameraFrameWidth = 100.0f;
    cameraFrameHeight = 150.0f;
    cameraFrameX = 0.0f;
    cameraFrameY = 0.0f;
    gameplayLayerDistance = 80.0f;
    maxLayerDistance = 100.0f;
}

- (void) initBgTriggers
{
    // background triggers are initialized based on the following assumption:
    // - number of preload sectors is 2; the third texture is streamed in almost immediately after in-game finishes loading
    // this way the same texture data buffer can be shared with other textures during loading
    NSUInteger numSectors = 3;

    [self.bgTriggers removeAllObjects];
    for(NSUInteger sectorId=0; sectorId < numSectors; ++sectorId)
    {
        float trigger = 0.0f;
        if(sectorId == (numSectors - 1))
        {
            // the first streamed tile, make it soon after loading finishes
            trigger = 1.0f;
        }
        [self.bgTriggers addObject:[NSNumber numberWithFloat:trigger]];
    }
    NSUInteger index = [bgTiles count];
    float nextTrigger = tileHeight;
    while(numSectors < index)
    {
        [self.bgTriggers addObject:[NSNumber numberWithFloat:nextTrigger]];
        nextTrigger += tileHeight;
        --index;
    }
}

- (void) commitAddonsDataToPlist
{
    // clear existing addons data in file
    [self.plist removeObjectForKey:@"addons"];
    [self.plist removeObjectForKey:@"spawners"];
    
    if(isAddonsData)
    {
        // commit addons data to file

        // version 1
        {
            // first sprite in layer0 is the parent object
            SpriteLayerData* layer0 = [floatingLayerData objectAtIndex:0];
            SpriteObject* parentObject = [[layer0 spriteObjects] objectAtIndex:0];
            CGSize parentSize = [parentObject size];
            CGPoint parentPos = [parentObject pos];
            
            // guns in subsequent layers are addons
            unsigned int index = 1;
            NSMutableDictionary* addonLayers = [NSMutableDictionary dictionary];
            while(index < [floatingLayerData count])
            {
                NSMutableArray* addonsArray = [NSMutableArray array];
                SpriteLayerData* curLayer = [floatingLayerData objectAtIndex:index];
                
                for(GroundObject* curObject in [curLayer gunObjects])
                {
                    CGPoint curPos = [curObject pos];
                    CGPoint offset = CGPointMake(curPos.x - parentPos.x, curPos.y - parentPos.y);
                    
                    // normalize offset by size of parent
                    offset.x /= parentSize.width;
                    offset.y /= parentSize.height;
                    
                    NSMutableDictionary* newGroundAddon = [NSMutableDictionary dictionary];
                    [newGroundAddon setObject:[NSNumber numberWithFloat:offset.x] forKey:@"offsetX"];
                    [newGroundAddon setObject:[NSNumber numberWithFloat:offset.y] forKey:@"offsetY"];
                    [addonsArray addObject:newGroundAddon];
                }
                [addonLayers setObject:addonsArray forKey:[curLayer layerName]];
                ++index;
            }
            [self.plist setObject:addonLayers forKey:@"addons"];
        }

        {
            // version 2
            // first sprite in layer0 is the parent object
            SpriteLayerData* layer0 = [floatingLayerData objectAtIndex:0];
            SpriteObject* parentObject = [[layer0 spriteObjects] objectAtIndex:0];
            CGSize parentSize = [parentObject size];
            CGPoint parentPos = [parentObject pos];
            
            // guns in subsequent layers are addons
            unsigned int index = 1;
            NSMutableDictionary* spawners = [NSMutableDictionary dictionary];
            while(index < [floatingLayerData count])
            {
                NSMutableDictionary* newEntry = [NSMutableDictionary dictionary];
                NSMutableArray* pointsArray = [NSMutableArray array];
                SpriteLayerData* curLayer = [floatingLayerData objectAtIndex:index];
                NSMutableArray* texNames = [NSMutableArray array];
                for(NSString* cur in curLayer.textureNames)
                {
                    [texNames addObject:cur];
                }
                
                for(GroundObject* curObject in [curLayer gunObjects])
                {
                    CGPoint curPos = [curObject pos];
                    CGPoint offset = CGPointMake(curPos.x - parentPos.x, curPos.y - parentPos.y);
                    
                    // normalize offset by size of parent
                    offset.x /= (parentSize.width * parentObject.scale.x);
                    offset.y /= (parentSize.height * parentObject.scale.y);
                    
                    NSMutableDictionary* newGroundAddon = [NSMutableDictionary dictionary];
                    [newGroundAddon setObject:[NSNumber numberWithFloat:offset.x] forKey:@"offsetX"];
                    [newGroundAddon setObject:[NSNumber numberWithFloat:offset.y] forKey:@"offsetY"];
                    [pointsArray addObject:newGroundAddon];
                }
                [newEntry setObject:pointsArray forKey:@"points"];
                NSMutableArray* animArray = [NSMutableArray array];
                for(SpriteObject* curSprite in curLayer.spriteObjects)
                {
                    NSMutableDictionary* newSpriteAddon = [NSMutableDictionary dictionary];
                    float spriteNormalizedWidth = (curSprite.size.width * curSprite.scale.x) / (parentSize.width * parentObject.scale.x);
                    float spriteNormalizedHeight = (curSprite.size.height * curSprite.scale.y) / (parentSize.height * parentObject.scale.y);
                    [newSpriteAddon setObject:[NSNumber numberWithFloat:spriteNormalizedWidth] forKey:@"width"];
                    [newSpriteAddon setObject:[NSNumber numberWithFloat:spriteNormalizedHeight] forKey:@"height"];
                    
                    CGPoint curPos = [curSprite pos];
                    CGPoint offset = CGPointMake(curPos.x - parentPos.x, curPos.y - parentPos.y);
                    
                    // normalize offset by size of parent
                    offset.x /= (parentSize.width * parentObject.scale.x);
                    offset.y /= (parentSize.height * parentObject.scale.y);

                    [newSpriteAddon setObject:[NSNumber numberWithFloat:offset.x] forKey:@"offsetX"];
                    [newSpriteAddon setObject:[NSNumber numberWithFloat:offset.y] forKey:@"offsetY"];
                    [newSpriteAddon setObject:[NSNumber numberWithFloat:curSprite.rotate] forKey:@"rotate"];
                    NSString* name = [texNames objectAtIndex:curSprite.textureId];
                    [newSpriteAddon setObject:[name stringByDeletingPathExtension] forKey:@"name"];
                    [animArray addObject:newSpriteAddon];
                }
                [newEntry setObject:animArray forKey:@"anim"];
                [spawners setObject:newEntry forKey:[curLayer layerName]];
                ++index;
            }
            [self.plist setObject:spawners forKey:@"spawners"];
        }
    }
}
 
- (void) backgroundLayerDataFromPlist
{
    self.numTiles = [[plist objectForKey:@"numTiles"] unsignedIntValue];
    self.tileWidth = [[plist objectForKey:@"tileWidth"] floatValue];
    self.tileHeight = [[plist objectForKey:@"tileHeight"] floatValue];
    self.tileTexWidth = [[plist objectForKey:@"tileTexWidth"] floatValue];
    self.tileTexHeight = [[plist objectForKey:@"tileTexHeight"] floatValue];

    NSArray* tilesArray = [plist objectForKey:@"bgTiles"];
    for(NSDictionary* curTile in tilesArray)
    {
        int orientation = [[curTile objectForKey:@"orientation"] intValue];
        if((0 > orientation) || (LEVELTILE_ORIENTATION_NUM <= orientation))
        {
            orientation = LEVELTILE_ORIENTATION_IDENTITY;
        }
        LevelTileData* newTile = [[LevelTileData alloc] initWithTextureName:[curTile objectForKey:@"textureName"]
                                                                orientation:orientation];
        [bgTiles addObject:newTile];
        [newTile release];
    }
    
    self.bgTriggers = [plist objectForKey:@"bgTexTriggers"];
}

- (void) floatingLayersDataFromPlist
{
    NSArray* plistFloatingLayers = [plist objectForKey:@"floatingLayers"];
    NSArray* plistFloatingLayersEditor = [plist objectForKey:@"floatingLayersEditor"];
    self.floatingLayerData = [NSMutableArray arrayWithCapacity:[plistFloatingLayers count]];
    unsigned int layerIndex = 0;
    for(NSDictionary* cur in plistFloatingLayers)
    {
        NSDictionary* curLayerEditor = [plistFloatingLayersEditor objectAtIndex:layerIndex];
        NSArray* curSpritesEditor = [curLayerEditor objectForKey:@"spritesEditor"];
        NSArray* curGunsEditor = [curLayerEditor objectForKey:@"gunsEditor"];
        NSArray* curCargosEditor = [curLayerEditor objectForKey:@"cargosEditor"];
        
        NSString* curName = [cur objectForKey:@"layerName"];
        float curDistance = [[cur objectForKey:@"layerDistance"] floatValue];
        BOOL isDynamics = [[cur objectForKey:@"isDynamics"] boolValue];
        NSArray* curTextures = [cur objectForKey:@"textures"];
        NSArray* curSprites = [cur objectForKey:@"sprites"];
        NSArray* curGuns = [cur objectForKey:@"guns"];
        NSArray* curCargos = [cur objectForKey:@"cargos"];
        SpriteLayerData* newLayer = [[SpriteLayerData alloc] initLayerNamed:curName AtDistance:curDistance isDynamics:isDynamics];
        newLayer.textureNames = [NSMutableSet setWithCapacity:[curTextures count]];
        newLayer.spriteObjects = [NSMutableArray arrayWithCapacity:[curSprites count]];
        
        // texture names array
        for(NSString* curName in curTextures)
        {
            [newLayer.textureNames addObject:curName];
        }
        
        // sprites
        unsigned int spriteIndex = 0;
        for(NSDictionary* curSprite in curSprites)
        {
            NSDictionary* curSpriteEditor = [curSpritesEditor objectAtIndex:spriteIndex];
            CGPoint screenPos = CGPointMake([[curSpriteEditor objectForKey:@"screenPosX"] floatValue],
                                            [[curSpriteEditor objectForKey:@"screenPosY"] floatValue]);
            CGPoint cameraPos = CGPointMake([[curSpriteEditor objectForKey:@"cameraPosX"] floatValue],
                                            [[curSpriteEditor objectForKey:@"cameraPosY"] floatValue]);
            CGPoint cameraScale = CGPointMake([[curSpriteEditor objectForKey:@"cameraScaleX"] floatValue],
                                              [[curSpriteEditor objectForKey:@"cameraScaleY"] floatValue]);
            
            CGPoint curPos = CGPointMake([[curSprite objectForKey:@"posX"] floatValue],
                                         [[curSprite objectForKey:@"posY"] floatValue]);
            CGSize curSize = CGSizeMake([[curSprite objectForKey:@"width"] floatValue],
                                        [[curSprite objectForKey:@"height"] floatValue]);
            CGPoint curScale = CGPointMake([[curSprite objectForKey:@"scaleX"] floatValue],
                                           [[curSprite objectForKey:@"scaleY"] floatValue]);
            float curRotate = [[curSprite objectForKey:@"rotate"] floatValue];
            NSUInteger curTexId = [[curSprite objectForKey:@"textureID"] unsignedIntegerValue];
            NSString* curTexname = [curTextures objectAtIndex:curTexId];
            SpriteObject* newSprite = [[SpriteObject alloc] initSpriteObjectAtPos:curPos size:curSize scale:curScale rotate:curRotate texture:curTexId textureName:curTexname screenPos:screenPos cameraPos:cameraPos cameraScale:cameraScale];
            [newLayer.spriteObjects addObject:newSprite];
            ++spriteIndex;
        }
        
        // guns
        {
            unsigned int gunIndex = 0;
            for(NSDictionary* curGun in curGuns)
            {
                NSDictionary* curGunEditor = [curGunsEditor objectAtIndex:gunIndex];
                CGPoint screenPos = CGPointMake([[curGunEditor objectForKey:@"screenPosX"] floatValue],
                                                [[curGunEditor objectForKey:@"screenPosY"] floatValue]);
                CGPoint cameraPos = CGPointMake([[curGunEditor objectForKey:@"cameraPosX"] floatValue],
                                                [[curGunEditor objectForKey:@"cameraPosY"] floatValue]);
                CGPoint cameraScale = CGPointMake([[curGunEditor objectForKey:@"cameraScaleX"] floatValue],
                                                  [[curGunEditor objectForKey:@"cameraScaleY"] floatValue]);
                CGSize curSize = CGSizeMake([[curGunEditor objectForKey:@"width"] floatValue],
                                            [[curGunEditor objectForKey:@"height"] floatValue]);

                CGPoint curPos = CGPointMake([[curGun objectForKey:@"posX"] floatValue],
                                             [[curGun objectForKey:@"posY"] floatValue]);
                NSString* spawnerTypeName = [curGun objectForKey:@"spawnerType"];
                NSString* objectTypeName = [curGun objectForKey:@"objectType"];
                GroundObject* newGun = [[GroundObject alloc] initGroundObjectAtPos:curPos
                                                                       spawnerName:spawnerTypeName
                                                                        objectName:objectTypeName
                                                                              size:curSize 
                                                                         screenPos:screenPos 
                                                                         cameraPos:cameraPos
                                                                       cameraScale:cameraScale 
                                        ];
                [newLayer.gunObjects addObject:newGun];
                ++gunIndex;
            }
        }

        // cargos
        {
            unsigned int cargoIndex = 0;
            for(NSDictionary* curCargo in curCargos)
            {
                NSDictionary* curCargoEditor = [curCargosEditor objectAtIndex:cargoIndex];
                CGPoint screenPos = CGPointMake([[curCargoEditor objectForKey:@"screenPosX"] floatValue],
                                                [[curCargoEditor objectForKey:@"screenPosY"] floatValue]);
                CGPoint cameraPos = CGPointMake([[curCargoEditor objectForKey:@"cameraPosX"] floatValue],
                                                [[curCargoEditor objectForKey:@"cameraPosY"] floatValue]);
                CGPoint cameraScale = CGPointMake([[curCargoEditor objectForKey:@"cameraScaleX"] floatValue],
                                                  [[curCargoEditor objectForKey:@"cameraScaleY"] floatValue]);
                CGSize curSize = CGSizeMake([[curCargoEditor objectForKey:@"width"] floatValue],
                                            [[curCargoEditor objectForKey:@"height"] floatValue]);
                
                CGPoint curPos = CGPointMake([[curCargo objectForKey:@"posX"] floatValue],
                                             [[curCargo objectForKey:@"posY"] floatValue]);
                NSString* spawnerTypeName = [curCargo objectForKey:@"spawnerType"];
                NSString* objectTypeName = [curCargo objectForKey:@"objectType"];
                GroundObject* newCargo = [[GroundObject alloc] initGroundObjectAtPos:curPos
                                                                         spawnerName:spawnerTypeName
                                                                          objectName:objectTypeName
                                                                                size:curSize 
                                                                           screenPos:screenPos 
                                                                           cameraPos:cameraPos
                                                                         cameraScale:cameraScale 
                                          ];
                [newLayer.cargoObjects addObject:newCargo];
                ++cargoIndex;
            }
        }

        [self.floatingLayerData addObject:newLayer];
        ++layerIndex;
    }
}

- (void) cameraDataFromPlist
{
    NSDictionary* gameCamera = [plist objectForKey:@"gameCamera"];
    cameraFrameWidth = [[gameCamera objectForKey:@"frameWidth"] floatValue];
    cameraFrameHeight = [[gameCamera objectForKey:@"frameHeight"] floatValue];
    cameraFrameX = [[gameCamera objectForKey:@"frameX"] floatValue];
    cameraFrameY = [[gameCamera objectForKey:@"frameY"] floatValue];
    gameplayLayerDistance = [[gameCamera objectForKey:@"gameplayLayerDistance"] floatValue];
    maxLayerDistance = [[gameCamera objectForKey:@"maxLayerDistance"] floatValue];
}

@end
