//
//  Level.mm
//  Curry
//
//  Sectors are tiles in the vertical direction of the level
//

#import "Level.h"
#import "LevelConfig.h"
#import "Texture.h"
#import "ScrollLayer.h"
#import "TextureSubImage.h"
#import "RenderBucketsManager.h"
#import "TopCam.h"
#import "CamPath.h"
#import "AppRendererConfig.h"
#import "FloatingLayer.h"
#import "LevelAnimData.h"
#import "LevelPathData.h"
#import "LevelTriggersData.h"

@interface Level (LevelPrivate)
- (NSMutableArray*) floatingLayersFromLevelConfig:(LevelConfig *)givenConfig levelAnimData:(LevelAnimData*)levelAnimData;
@end

@implementation Level
@synthesize config;
@synthesize animData;
@synthesize pathsData;
@synthesize triggersData;
@synthesize backgroundTextures;
@synthesize bgScroll;
@synthesize gameCamera;
@synthesize floatingLayers;
@synthesize layerCameraDelegates;

- (id) initWithConfig:(LevelConfig*)givenConfig
{
	if((self = [super init]))
	{
		self.config = givenConfig;
        animData = [[LevelAnimData alloc] initFromFileCommon:[givenConfig commonAnimFilename] levelSpecific:[givenConfig levelAnimFilename]];
        pathsData = [[LevelPathData alloc] initFromFilename:[givenConfig pathsFilename]];
        triggersData = [[LevelTriggersData alloc] initFromFilename:[givenConfig triggersFilename]];
        bgScroll = [[ScrollLayer alloc] initWithLevelConfig:givenConfig];
        gameCamera = [[TopCam alloc] initFromLevelConfig:givenConfig forRendererViewFrame:[[AppRendererConfig getInstance] getViewportFrame]];
        self.floatingLayers = [self floatingLayersFromLevelConfig:givenConfig levelAnimData:animData];
        self.layerCameraDelegates = [NSMutableArray arrayWithCapacity:5];
              
        // link floating layers to their scroll paths if available
        // and also add them to gameCamera to get updated every frame
        for(FloatingLayer* curLayer in floatingLayers)
        {
            CamPath* scrollPath = [pathsData getPathForLayername:[curLayer layerName]];
            if(scrollPath)
            {
                [curLayer setScrollPath:scrollPath];
                [gameCamera addScrollPath:scrollPath withName:[curLayer layerName]];
            }
        }
        
        // link main camera path to the game camera
        CamPath* mainPath = [pathsData getPathForLayername:@"Main"];
        assert(mainPath);
        [gameCamera setCamPath:mainPath];
        [gameCamera.camPath resetFollow];
        CamPath* triggerPath = [pathsData getPathForLayername:@"Trigger"];
        if(triggerPath)
        {
            gameCamera.triggerPath = triggerPath;
        }
        else
        {
            [pathsData duplicatePathNamed:@"Main" toName:@"Trigger"];
            gameCamera.triggerPath = [pathsData getPathForLayername:@"Trigger"];
        }
        [gameCamera.triggerPath resetFollow];
        
        // register triggers with game camera
        [gameCamera setTriggersArray:[triggersData triggers]];
        
        // add layer delegates
        [self.layerCameraDelegates addObject:self.bgScroll];
        for(FloatingLayer* curLayer in self.floatingLayers)
        {
            [self.layerCameraDelegates addObject:curLayer];
        }
        
        // cache bucket indices internally
        RenderBucketsManager* bucketsMgr = [RenderBucketsManager getInstance];
        grPreDynamicsIndex = [bucketsMgr getIndexFromName:@"GrPreDynamics"];
        grDynamicsIndex = [bucketsMgr getIndexFromName:@"GrDynamics"];
        grPostDynamicsIndex = [bucketsMgr getIndexFromName:@"GrPostDynamics"];
        shadowsIndex = [bucketsMgr getIndexFromName:@"Shadows"];
        bigDynamicsIndex = [bucketsMgr getIndexFromName:@"BigDynamics"];
        bigAddonsIndex = [bucketsMgr getIndexFromName:@"BigAddons"];
        bigAddons2Index = [bucketsMgr getIndexFromName:@"BigAddons2"];
        dynamicsIndex = [bucketsMgr getIndexFromName:@"Dynamics"];
        addonsIndex = [bucketsMgr getIndexFromName:@"Addons"];
        playerIndex = [bucketsMgr getIndexFromName:@"Player"];
        playerAddonsIndex = [bucketsMgr getIndexFromName:@"PlayerAddons"];
        bulletsIndex = [bucketsMgr getIndexFromName:@"Bullets"];
        pointsHudIndex = [bucketsMgr getIndexFromName:@"PointsHud"];
	}
	return self;
}

- (void) dealloc
{
    self.layerCameraDelegates = nil;
    [floatingLayers release];
    [gameCamera release];
    [bgScroll release];
    [triggersData release];
    [pathsData release];
    [animData release];
    [config release];
	[super dealloc];
}

- (void) restartLevel
{
    [self.gameCamera restartLevel];
    [self.bgScroll restart];
}


- (void) addDraw
{
    for(NSObject<LayerCameraDelegate>* cur in layerCameraDelegates)
    {
        [cur addDrawCommandForCamera:gameCamera];
    }
    [gameCamera addDrawToBucketIndex:grPreDynamicsIndex];
    [gameCamera addDrawToBucketIndex:grDynamicsIndex];
    [gameCamera addDrawToBucketIndex:grPostDynamicsIndex];
    [gameCamera addDrawToBucketIndex:shadowsIndex];
    [gameCamera addDrawToBucketIndex:bigDynamicsIndex];
    [gameCamera addDrawToBucketIndex:bigAddonsIndex];
    [gameCamera addDrawToBucketIndex:bigAddons2Index];
    [gameCamera addDrawToBucketIndex:dynamicsIndex];
    [gameCamera addDrawToBucketIndex:addonsIndex];
    [gameCamera addDrawToBucketIndex:playerIndex];
    [gameCamera addDrawToBucketIndex:playerAddonsIndex];
    [gameCamera addDrawToBucketIndex:bulletsIndex];
    [gameCamera addDrawToBucketIndex:pointsHudIndex];
    [bgScroll addDraw];
    for(FloatingLayer* layer in floatingLayers)
    {
        [layer addDraw];
    }
}

- (void) update:(NSTimeInterval)elapsed
{
    [gameCamera update:elapsed];

    CGPoint camOrigin = [gameCamera camOriginAtLayerDistance:bgScroll.distanceFromCamera];
    [bgScroll updateAtPos:camOrigin];
}

- (CGSize) getCameraFrameSize
{
    CGSize result = gameCamera.frame.size;
    return result;
}

- (void) spawnAllAnimSprites
{
    for(FloatingLayer* cur in floatingLayers)
    {
        [cur spawnAllAnimSprites];
    }
}

- (void) killAllAnimSprites
{
    for(FloatingLayer* cur in floatingLayers)
    {
        [cur killAllAnimSprites];
    }
}

#pragma mark -
#pragma mark Private methods
- (NSMutableArray*) floatingLayersFromLevelConfig:(LevelConfig *)givenConfig levelAnimData:(LevelAnimData*)levelAnimData
{
    NSMutableArray* newArray = nil;
    NSArray* layerConfigs = [givenConfig floatingLayers];
    NSMutableArray* reorderedConfigs = [NSMutableArray array];  // temp array to reorder configs to match the layers in newArray
    if((layerConfigs) && ([layerConfigs count] > 0))
    {
        newArray = [NSMutableArray arrayWithCapacity:[layerConfigs count]];
        
        // init all the static layers first, then the dynamics layers;
        // this is because static layers may shift render bucket indices of dynamics layers if they get created after
        for(NSDictionary* curLayer in layerConfigs)
        {
            BOOL isDynamics = [[curLayer objectForKey:@"isDynamics"] boolValue];
            if(!isDynamics)
            {
                FloatingLayer* newLayer = [[FloatingLayer alloc] initFromLayerConfig:curLayer levelAnimData:levelAnimData];
                [newArray addObject:newLayer];
                [newLayer release];
                [reorderedConfigs addObject:curLayer];
            }
        }
        for(NSDictionary* curLayer in layerConfigs)
        {
            BOOL isDynamics = [[curLayer objectForKey:@"isDynamics"] boolValue];
            if(isDynamics)
            {
                FloatingLayer* newLayer = [[FloatingLayer alloc] initFromLayerConfig:curLayer levelAnimData:levelAnimData];
                [newArray addObject:newLayer];
                [newLayer release];
                [reorderedConfigs addObject:curLayer];
            }
        }
        
        
        // now create all the spawners (guns, cargos, etc.) because render-bucket indices get
        // shifted around in the loop above when layers are created
        // some spawners may cache off bucket indices; so, need to wait till all bucket-index adjustments are done
        // also note that this loop uses the reordered layer Configs array because the layers in newArray are ordered static-first-the-dynamics,
        // which is not the same order as the order in [givenConfig floatingLayers] array from the plist file
        unsigned int index = 0;
        while(index < [layerConfigs count])
        {
            NSDictionary* curLayerConfig = [reorderedConfigs objectAtIndex:index];
            FloatingLayer* curLayer = [newArray objectAtIndex:index];
            assert(curLayer);
            [curLayer createSpawnersInLayer:curLayerConfig];
            ++index;
        }
        [reorderedConfigs removeAllObjects];
    }
    
    return newArray;
}

@end
