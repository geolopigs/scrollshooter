//
//  RenderBucketsManager.mm
//

#import "RenderBucketsManager.h"
#import "DrawCommand.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


@implementation RenderBucketsConfig
@synthesize bucketNames;

- (id) init
{
	if((self = [super init]))
	{
		bucketNames = [[NSMutableArray arrayWithCapacity:1] retain];
	}
	return self;
}

- (void) dealloc
{
	[bucketNames release];
	[super dealloc];
}

- (void) addBucketByName:(NSString*)name
{
	[bucketNames addObject:name];
}

@end

@interface RenderBucketsManager (PrivateMethods)
- (void) setupFromConfig:(RenderBucketsConfig*)givenConfig;
@end

@implementation RenderBucketsManager

#pragma mark - private methods
- (void) setupFromConfig:(RenderBucketsConfig*)givenConfig
{
    assert(nil == renderBucketsNew);
	assert(nil == renderBucketIndexNew);

    renderBucketsNew = [[NSMutableArray array] retain];
    renderBucketIndexNew = [[NSMutableDictionary dictionary] retain];
    unsigned int index = 0;
    for(NSString* name in config.bucketNames)
    {
        NSMutableArray* newBucket = [NSMutableArray array];
        [renderBucketsNew addObject:newBucket];
        [renderBucketIndexNew setObject:[NSNumber numberWithUnsignedInt:index] forKey:name];
        ++index;
    }
}


#pragma mark -
#pragma mark Instance Methods
- (id) init
{
	if((self = [super init]))
	{
        config = nil;
		renderBucketsNew = nil;
		renderBucketIndexNew = nil;
	}
	return self;
}

- (void) initWithConfig:(RenderBucketsConfig *)appConfig
{
    config = [appConfig retain];
    [self setupFromConfig:config];
}


- (void) dealloc
{
    [renderBucketIndexNew release];
    [renderBucketsNew release];
    [config release];
	[super dealloc];
}

// call this when starting a new level to clear out any buckets from previous levels
- (void) resetFromConfig
{
    [renderBucketIndexNew release];
    renderBucketIndexNew = nil;
    
    /*
    unsigned int index = 0;
    while(index < [renderBucketsNew count])
    {
        NSMutableArray* curBucket = [renderBucketsNew objectAtIndex:index];
        for(DrawCommand* cur in curBucket)
        {
            if(1 < [cur retainCount])
            {
                NSLog(@"draw command retain %d", [cur retainCount]);
            }
        }
        ++index;
    }
    */

    
    [renderBucketsNew release];
    renderBucketsNew = nil;
    
    [self setupFromConfig:config];
}

- (void) clearAllCommands
{
    {
        unsigned int index = 0;
        while(index < [renderBucketsNew count])
        {
            NSMutableArray* curBucket = [renderBucketsNew objectAtIndex:index];
            [curBucket removeAllObjects];
            ++index;
        }
    }
}

- (void) execCommands
{
    {
        unsigned int index = 0;
        while(index < [renderBucketsNew count])
        {
            NSArray* curBucket = [renderBucketsNew objectAtIndex:index];
            glPushMatrix();
            for(DrawCommand* curCommand in curBucket)
            {
                [curCommand.drawDelegate draw:curCommand.drawData];
            }
            glPopMatrix();
            ++index;
        }
    }    

}

- (void) addCommand:(DrawCommand*)command toBucket:(unsigned int)index
{
	assert(index < [renderBucketsNew count]);
	NSMutableArray* cur = [renderBucketsNew objectAtIndex:index];
	[cur addObject:command];
}

- (unsigned int) getIndexFromName:(NSString*)name
{
	NSNumber* index = [renderBucketIndexNew objectForKey:name];
	assert(index);
	return [index unsignedIntValue];
}

- (unsigned int) newBucketBeforeBucketNamed:(NSString *)refName withName:(NSString *)name
{
    NSNumber* refIndex = [renderBucketIndexNew objectForKey:refName];
    assert(refIndex);
    unsigned int insertionIndex = [refIndex unsignedIntValue];
    
    // insert new bucket
    NSMutableArray* newBucket = [NSMutableArray array];
    [renderBucketsNew insertObject:newBucket atIndex:insertionIndex];
    
    // shift indices after it down by one
    NSMutableArray* keysArray = [NSMutableArray array];
    for(NSString* key in renderBucketIndexNew)
    {
        unsigned int keyIndex = [[renderBucketIndexNew objectForKey:key] unsignedIntValue];
        if(keyIndex >= insertionIndex)
        {
            [keysArray addObject:key];
        }
    }
    for(NSString* key in keysArray)
    {
        unsigned int keyIndex = [[renderBucketIndexNew objectForKey:key] unsignedIntValue];
        [renderBucketIndexNew setObject:[NSNumber numberWithUnsignedInt:(keyIndex+1)] forKey:key];
    }
    
    // add index for new bucket
    [renderBucketIndexNew setObject:[NSNumber numberWithUnsignedInt:insertionIndex] forKey:name];
    return insertionIndex;
}


#pragma mark -
#pragma mark Singleton
static RenderBucketsManager* singletonInstance = nil;
+ (RenderBucketsManager*) getInstance
{
	@synchronized(self)
	{
		if (!singletonInstance)
		{
			singletonInstance = [[[RenderBucketsManager alloc] init] retain];
		}
	}
	return singletonInstance;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singletonInstance release];
		singletonInstance = nil;
	}
}


@end
