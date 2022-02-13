//
//  LevelConfig.h
//  Curry
//
//	A LevelConfig is the blueprint for Level initialization
//

#import <Foundation/Foundation.h>

@class EnvLevelData;
@interface LevelConfig : NSObject 
{
	NSDictionary*   config;
    
    NSString*       commonAnimFilename;
    NSString*       levelAnimFilename;
    NSString*       pathsFilename;
    NSString*       triggersFilename;
}
@property (nonatomic,retain) NSDictionary* config;
@property (nonatomic,retain) NSString* commonAnimFilename;
@property (nonatomic,retain) NSString* levelAnimFilename;
@property (nonatomic,retain) NSString* pathsFilename;
@property (nonatomic,retain) NSString* triggersFilename;
@property (nonatomic,readonly) NSArray* bgTiles;
@property (nonatomic,readonly) NSArray* backgroundNames;
@property (nonatomic,readonly) float tileWidth;
@property (nonatomic,readonly) float tileHeight;
@property (nonatomic,readonly) size_t tileTexWidth;
@property (nonatomic,readonly) size_t tileTexHeight;
@property (nonatomic,readonly) unsigned int numTiles;
@property (nonatomic,readonly) NSString* scrollRefTexName;
@property (nonatomic,readonly) NSArray* bgTexTriggers;
@property (nonatomic,readonly) float bgLayerDistance;
@property (nonatomic,readonly) NSDictionary* gameCameraConfig;
@property (nonatomic,readonly) NSArray*      floatingLayers;

- (id) initFromEnvLevelData:(EnvLevelData*)data;
@end
