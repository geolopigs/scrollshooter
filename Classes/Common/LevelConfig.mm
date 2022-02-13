//
//  LevelConfig.mm
//  Curry
//
//

#import "LevelConfig.h"
#import "EnvData.h"

@implementation LevelConfig
@synthesize config;
@synthesize commonAnimFilename;
@synthesize levelAnimFilename;
@synthesize pathsFilename;
@synthesize triggersFilename;

NSString* const BACKGROUNDNAMES_KEY = @"backgroundNames";
NSString* const TILEWIDTH_KEY = @"tileWidth";
NSString* const TILEHEIGHT_KEY = @"tileHeight";
NSString* const NUMTILES_KEY = @"numTiles";
NSString* const SCROLLREFTEX_KEY = @"refTexture";
NSString* const BGTEXTRIGGERS_KEY = @"bgTexTriggers";
NSString* const TILETEXWIDTH_KEY = @"tileTexWidth";
NSString* const TILETEXHEIGHT_KEY = @"tileTexHeight";
NSString* const GAMECAMERA_KEY = @"gameCamera";
NSString* const BGLAYERDISTANCE = @"bgLayerDistance";


- (id) initFromEnvLevelData:(EnvLevelData*)data
{
    self = [super init];
    if(self)
    {
        NSString* path = [[NSBundle mainBundle] pathForResource:[data fileName] ofType:@"plist"];
        self.config = [NSDictionary dictionaryWithContentsOfFile:path];
        self.commonAnimFilename = [data commonAnimName];
        self.levelAnimFilename = [data animName];
        self.pathsFilename = [data pathsName];
        self.triggersFilename = [data triggersName];
    }
    return self;
}


- (void) dealloc
{
    self.triggersFilename = nil;
    self.pathsFilename = nil;
    self.levelAnimFilename = nil;
    self.commonAnimFilename = nil;
    self.config = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
- (NSArray*) bgTiles
{
    return [config objectForKey:@"bgTiles"];
}

- (NSArray*) backgroundNames
{
    return [config objectForKey:BACKGROUNDNAMES_KEY];
}

- (float) tileWidth
{
    return [[config objectForKey:TILEWIDTH_KEY] floatValue];
}

- (float) tileHeight
{
    return [[config objectForKey:TILEHEIGHT_KEY] floatValue];
}

- (size_t) tileTexWidth
{
//    return [[config objectForKey:TILETEXWIDTH_KEY] intValue];

    // for memory reasons, tile texture needs to be 512x512;
    // so, hardcode to be 512 here
    return 512;
}

- (size_t) tileTexHeight
{
//    return [[config objectForKey:TILETEXHEIGHT_KEY] intValue];

    // for memory reasons, tile texture needs to be 512x512;
    // so, hardcode to be 512 here
    return 512;
}

- (unsigned int) numTiles
{
    return [[config objectForKey:NUMTILES_KEY] intValue];
}

- (NSString*) scrollRefTexName
{
    return [config objectForKey:SCROLLREFTEX_KEY];
}

- (NSArray*) bgTexTriggers
{
    return [config objectForKey:BGTEXTRIGGERS_KEY];
}

- (float) bgLayerDistance
{
    return [[[config objectForKey:GAMECAMERA_KEY] objectForKey:@"maxLayerDistance"] floatValue];
//    return [[config objectForKey:BGLAYERDISTANCE] floatValue];
}

- (NSDictionary*) gameCameraConfig
{
    return [config objectForKey:GAMECAMERA_KEY];
}

- (NSArray*) floatingLayers
{
    return [config objectForKey:@"floatingLayers"];
}

@end
