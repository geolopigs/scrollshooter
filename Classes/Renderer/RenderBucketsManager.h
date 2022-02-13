//
//  RenderBucketsManager.h
//  Curry
//

#import <Foundation/Foundation.h>

@class DrawCommand;

@interface RenderBucketsConfig : NSObject
{
	NSMutableArray* bucketNames;
}
@property (nonatomic,readonly) NSMutableArray* bucketNames;
- (void) addBucketByName:(NSString*)name;
@end


@interface RenderBucketsManager : NSObject 
{
    // config params
    RenderBucketsConfig* config;        // used for resetting buckets when going from level to level
    
    // runtime params
	NSMutableArray* renderBucketsNew;
	NSMutableDictionary* renderBucketIndexNew;
}
+ (RenderBucketsManager*) getInstance;
+ (void) destroyInstance;

- (void) initWithConfig:(RenderBucketsConfig*)appConfig;
- (void) resetFromConfig;

- (void) clearAllCommands;
- (void) execCommands;
- (void) addCommand:(DrawCommand*)command toBucket:(unsigned int)index;
- (unsigned int) getIndexFromName:(NSString*)name;
- (unsigned int) newBucketBeforeBucketNamed:(NSString*)refName withName:(NSString*)name;
@end

