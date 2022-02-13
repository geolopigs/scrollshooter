//
//  AnimProcessor.mm
//

#import "AnimProcessor.h"

@implementation AnimProcessor
@synthesize clipList;
@synthesize clipPurgeList;

#pragma mark -
#pragma mark singleton
static AnimProcessor* singleton = nil;

+ (AnimProcessor*)getInstance
{
    @synchronized(self)
    {
        if (singleton == nil)
		{
			singleton = [[AnimProcessor alloc] init];
		}
    }
    return singleton;
}

+ (void) destroyInstance
{
    @synchronized(self)
    {
		[singleton release];
		singleton = nil;
	}	
}


#pragma mark -
#pragma mark AnimProcessor methods
- (id) init
{
	if(self = [super init])
	{
		objectList = [[NSMutableArray arrayWithCapacity:10] retain];
		removeList = [[NSMutableArray arrayWithCapacity:10] retain];
		noPauseList = [[NSMutableArray arrayWithCapacity:10] retain];
		noPauseRemoveList = [[NSMutableArray arrayWithCapacity:10] retain];
        
        self.clipList = [NSMutableSet set];
        self.clipPurgeList = [NSMutableSet set];
	}
	return self;
}

- (void) dealloc
{
    self.clipPurgeList = nil;
    self.clipList = nil;
    
	[noPauseRemoveList release];
	[noPauseList release];
	[removeList release];
	[objectList release];
	[super dealloc];
}

- (void) reset
{
    self.clipPurgeList = nil;
    self.clipList = nil;
    
	[noPauseRemoveList release];
	[noPauseList release];
	[removeList release];
	[objectList release];
    
    objectList = [[NSMutableArray arrayWithCapacity:10] retain];
    removeList = [[NSMutableArray arrayWithCapacity:10] retain];
    noPauseList = [[NSMutableArray arrayWithCapacity:10] retain];
    noPauseRemoveList = [[NSMutableArray arrayWithCapacity:10] retain];
    
    self.clipList = [NSMutableSet set];
    self.clipPurgeList = [NSMutableSet set];
}

- (void) addObject:(id)animatedObject
{
	NSObject<AnimDelegate>* cur = animatedObject;
	if([cur isNoPause])
	{
		[noPauseList addObject:animatedObject];
	}
	else
	{
		[objectList addObject:animatedObject];
	}
}

- (void) removeObject:(id)animatedObject
{
	NSObject<AnimDelegate>* cur = animatedObject;
	if([cur isNoPause])
	{
		[noPauseRemoveList addObject:animatedObject];
	}
	else
	{
		[removeList addObject:animatedObject];
	}
}

- (void) update:(NSTimeInterval)elapsed IsPaused:(BOOL)paused
{
	if(!paused)
	{
		// process removal first
		for(id cur in removeList)
		{
			[objectList removeObject:cur];
		}
		[removeList removeAllObjects];
	
		// process update
		for(id cur in objectList)
		{
			[cur updateAnim:elapsed];
		}
	}	
	
	// no-pause list gets processed regardless of whether the caller is paused
	for(id cur in noPauseRemoveList)
	{
		[noPauseList removeObject:cur];
	}
	[noPauseRemoveList removeAllObjects];
	
	for(id cur in noPauseList)
	{
		[cur updateAnim:elapsed];
	}
}

- (void) addClip:(NSObject<AnimProcDelegate> *)clip
{
    [clipList addObject:clip];
}

- (void) removeClip:(NSObject<AnimProcDelegate> *)clip
{
    [clipPurgeList addObject:clip];
}

- (void) advanceClips:(NSTimeInterval)elapsed
{
    for(NSObject<AnimProcDelegate>* cur in clipPurgeList)
    {
        [clipList removeObject:cur];
    }
    [clipPurgeList removeAllObjects];
    
    for(NSObject<AnimProcDelegate>* cur in clipList)
    {
        [cur advanceAnim:elapsed];
    }
}

- (void) addController:(NSObject<AnimProcDelegate> *)controller
{
    [clipList addObject:controller];
}

- (void) removeController:(NSObject<AnimProcDelegate> *)controller
{
    [clipPurgeList addObject:controller];
}
@end
