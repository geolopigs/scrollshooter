//
//  ScrollLayer.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/7/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "ScrollLayer.h"
#import "ScrollRenderer.h"
#import "ScrollLoader.h"
#import "LevelConfig.h"
#import "TextureSubImage.h"
#import "Texture.h"
#import "RenderBucketsManager.h"
#import "TopCam.h"
#import "TopCamRenderer.h"
#import "LevelTileData.h"
#import "AppRendererConfig.h"

@interface ScrollLayer (ScrollLayerPrivate)
- (BOOL) loadTexture:(unsigned int)texIndex;
- (void) duplicateTile:(ScrollRendererTile*)srcTile atIndex:(unsigned int)tileIndex;
- (void) preloadTextures;
@end

@implementation ScrollLayer
@synthesize tiles;
@synthesize loadTriggers;
@synthesize renderer;
@synthesize activeTiles;
@synthesize requestTiles;
@synthesize loader;
@synthesize distanceFromCamera;
@synthesize drawCmd;
@synthesize drawData;

- (id) initWithLevelConfig:(LevelConfig *)config
{
    self = [super init];
    if(self)
    {
        // init tiles from bgTiles data
        tileHeight = [config tileHeight];
        self.tiles = [NSMutableArray array];
        for(NSDictionary* curTileData in [config bgTiles])
        {
            LevelTileData* newTile = [[LevelTileData alloc] initWithTextureName:[curTileData objectForKey:@"textureName"]
                                                                    orientation:[[curTileData objectForKey:@"orientation"] intValue]];
            [tiles addObject:newTile];
            [newTile release];
        }

        self.loadTriggers = config.bgTexTriggers;
        
        renderer = [[ScrollRenderer alloc] initWithTileSize:CGSizeMake(config.tileWidth,config.tileHeight)
                                                   numberOfTiles:config.numTiles 
                                                    texSize:CGSizeMake(config.tileTexWidth,config.tileTexHeight)];
        self.activeTiles = [NSMutableArray arrayWithCapacity:[config numTiles]];
        self.requestTiles = [NSMutableArray array];
        nextTrigger = 0;
        doUpload = NO;
        
        ScrollLoader* newLoader = [[ScrollLoader alloc] init];
        self.loader = newLoader;
        [newLoader release];
        
        self.distanceFromCamera = config.bgLayerDistance;
        self.drawCmd = nil;
        self.drawData = nil;
        
        // pre-load the initial set of textures here to avoid delayed pop-in of background textures
        [self preloadTextures];
    }
    return self;
}

- (void) dealloc
{
    [loader abortLoading];
    while([loader isLoading])
    {
        [NSThread sleepForTimeInterval:0.5f];
    }
    self.drawData = nil;
    self.drawCmd = nil;
    self.loader = nil;
    self.requestTiles = nil;
    self.activeTiles = nil;
    [renderer release];
    [loadTriggers release];
    self.tiles = nil;
    [super dealloc];
}

- (void) restart
{
    doUpload = NO;
    nextTrigger = 0;
    [self.activeTiles removeAllObjects];
    [self.requestTiles removeAllObjects];
    
    [self.loader abortLoading];
    [self preloadTextures];
}

- (void) addDraw
{
    unsigned int bucketId = [[RenderBucketsManager getInstance] getIndexFromName:@"Background"];
    
    if([loader hasNewImages])
    {
        // add newly loaded images to activeTiles
        unsigned int i = 0;
        while(i < [[loader textures] count])
        {
            // retrieve texture from loader
            Texture* texture = [[loader textures] objectAtIndex:i];
            [texture submitBufferToGL];
            
            // retrieve the tile request
            ScrollRendererTile* loadedTile = [requestTiles objectAtIndex:i];
            loadedTile.tex = texture;
            
            // add it to active list and remove from request list
            [activeTiles addObject:loadedTile];
            [requestTiles removeObject:loadedTile];

            ++i;
        }
        // inform loader we're doing pulling from it
        [loader consumedLoading];
        
        // throw out old tiles, only keep 3 in memory at one time
        while([activeTiles count] > 3)
        {
            [activeTiles removeObjectAtIndex:0];
        }
    }
    
    ScrollRendererInstance* instance = [[ScrollRendererInstance alloc] initWithTiles:activeTiles];
    DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:renderer DrawData:instance];
    [[RenderBucketsManager getInstance] addCommand:cmd toBucket:bucketId];
    [cmd release];
    [instance release];
}

- (void) updateAtPos:(CGPoint)camPos
{
    while(nextTrigger < [loadTriggers count])
    {
        if([[loadTriggers objectAtIndex:nextTrigger] floatValue] <= camPos.y)
        {
            // load the corresponding texture and apply it
            BOOL added = NO;
            added = [self loadTexture:nextTrigger];
            if(added)
            {
                ++nextTrigger;
            }
            else
            {
                // if queue is full, stop; will try again next tick;
                break;
            }
        }
        else
        {
            break;
        }
    }
    
    [loader mainUpdate];
}

- (void) jumpToPos:(CGPoint)camPos
{
    // set nextTrigger to the index immediately prior to the given pos
    unsigned int index = 0;
    for(NSNumber* cur in loadTriggers)
    {
        if([cur floatValue] < camPos.y)
        {
            ++index;
        }
        else
        {
            break;
        }
    }
    nextTrigger = index;
    
    if([activeTiles count] > 2)
    {
        // duplicate the two tiles that we are currently on to fill the two tiles at the new location we're jumping to
        unsigned int tileCount = [activeTiles count];
        unsigned int index0 = static_cast<unsigned int>(floorf(camPos.y / tileHeight));
        [self duplicateTile:[activeTiles objectAtIndex:tileCount-2] atIndex:index0];
        [self duplicateTile:[activeTiles objectAtIndex:tileCount-1] atIndex:index0+1];
    }
}

#pragma mark -
#pragma mark Private methods

// returns true if successfully added to queue; false if queue is full;
- (BOOL) loadTexture:(unsigned int)texIndex
{
    BOOL result = YES;    
    LevelTileData* curTile = [tiles objectAtIndex:texIndex];
    
    // put in a request to loader
    result = [loader queueTexFilename:[curTile textureName] orientation:[curTile orientation]];
    if(result)
    {
        // save up info to be handled when loaded
        ScrollRendererTile* renderTile = [[ScrollRendererTile alloc] initWithTexture:nil tileIndex:nextTrigger];
        [requestTiles addObject:renderTile];
        [renderTile release];
    }
    return result;
}

- (void) duplicateTile:(ScrollRendererTile*)srcTile atIndex:(unsigned int)tileIndex
{
    // save up info to be handled when loaded
    ScrollRendererTile* renderTile = [[ScrollRendererTile alloc] initWithTexture:[srcTile tex] tileIndex:tileIndex];
    [activeTiles addObject:renderTile];
    [renderTile release];
}

- (void) preloadTextures
{
    LevelTileData* curTile = [tiles objectAtIndex:nextTrigger];
    
    GLubyte* intermedateBuffer = [[AppRendererConfig getInstance] getScrollSubimageBuffer];
    GLubyte* buffer = [[AppRendererConfig getInstance] getImageBuffer2];
    Texture* loadedTex = [[Texture alloc] initFromFileName:[curTile textureName] 
                                                 orientation:[curTile orientation]
                                                    toBuffer:buffer 
                                            withIntermediate:intermedateBuffer];
    [loadedTex submitBufferToGL];
    ScrollRendererTile* renderTile = [[ScrollRendererTile alloc] initWithTexture:loadedTex tileIndex:nextTrigger];
    [activeTiles addObject:renderTile];
    [renderTile release];
    [loadedTex release];
    ++nextTrigger;
    
    curTile = [tiles objectAtIndex:nextTrigger];
    loadedTex = [[Texture alloc] initFromFileName:[curTile textureName] 
                                               orientation:[curTile orientation]
                                                  toBuffer:buffer 
                                          withIntermediate:intermedateBuffer];
    [loadedTex submitBufferToGL];
    renderTile = [[ScrollRendererTile alloc] initWithTexture:loadedTex tileIndex:nextTrigger];
    [activeTiles addObject:renderTile];
    [renderTile release];
    [loadedTex release];
    ++nextTrigger;
}

#pragma mark -
#pragma mark LayerCameraDelegate
- (void) addDrawCommandForCamera:(TopCam*)camera
{
    CGPoint camOrigin = [camera camOriginAtLayerDistance:[camera distanceMaxLayer]];
    
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
    unsigned int bucketId = [[RenderBucketsManager getInstance] getIndexFromName:@"Background"];
    [[RenderBucketsManager getInstance] addCommand:self.drawCmd toBucket:bucketId];
}



@end
