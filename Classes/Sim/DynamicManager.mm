//
//  DynamicManager.mm
//

#import "DynamicManager.h"
#import "DynamicProtocols.h"
#import "FiringPath.h"

@implementation DynamicManager

static const float DYNAMICMANAGER_DEFAULT_VIEWWIDTH = 8.0f;
static const float DYNAMICMANAGER_DEFAULT_VIEWHEIGHT = 12.0f;

#pragma mark -
#pragma mark Singleton
static DynamicManager* singletonInstance = nil;
+ (DynamicManager*) getInstance
{
	@synchronized(self)
	{
		if (!singletonInstance)
		{
			singletonInstance = [[[DynamicManager alloc] init] retain];
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


#pragma mark -
#pragma mark Instance Methods
- (id) init
{
	if((self = [super init]))
	{
		activeSet = [[NSMutableSet setWithCapacity:10] retain];
		purgeSet = [[NSMutableSet setWithCapacity:10] retain];
		spawnSet = [[NSMutableSet setWithCapacity:10] retain];
        viewConstraintSet = [[NSMutableSet setWithCapacity:10] retain];
        viewConstraint = CGRectMake(0.0f, 0.0f,
                                    DYNAMICMANAGER_DEFAULT_VIEWWIDTH, DYNAMICMANAGER_DEFAULT_VIEWHEIGHT);
	}
	return self;
}

- (void) dealloc
{
    [viewConstraintSet release];
	[spawnSet release];
	[purgeSet release];
	[activeSet release];
	[super dealloc];
}

- (void) reset
{
    [viewConstraintSet release];
	[spawnSet release];
	[purgeSet release];
	[activeSet release];

    activeSet = [[NSMutableSet setWithCapacity:10] retain];
    purgeSet = [[NSMutableSet setWithCapacity:10] retain];
    spawnSet = [[NSMutableSet setWithCapacity:10] retain];
    viewConstraintSet = [[NSMutableSet setWithCapacity:10] retain];
    viewConstraint = CGRectMake(0.0f, 0.0f,
                                DYNAMICMANAGER_DEFAULT_VIEWWIDTH, DYNAMICMANAGER_DEFAULT_VIEWHEIGHT);    
}

- (void) setViewConstraintFromGame:(CGRect)gameViewportRect
{
    viewConstraint = gameViewportRect;    
}

- (void) addObject:(NSObject<DynamicDelegate>*)dynamicObject
{
	[spawnSet addObject:dynamicObject];
}

- (void) removeObject:(NSObject<DynamicDelegate>*)dynamicObject
{
	[purgeSet addObject:dynamicObject];
}

- (void) update:(NSTimeInterval)elapsed isPaused:(BOOL)paused
{	
	// update
	for(NSObject<DynamicDelegate>* cur in activeSet)
	{
		[cur updateBehavior:elapsed];
	}
    
    // physics
    for(NSObject<DynamicDelegate>* cur in activeSet)
    {
        if([cur respondsToSelector:@selector(updatePhysics:)])
        {
            [cur updatePhysics:elapsed];
        }
    }
    
  	// purge
	for(id cur in purgeSet)
	{
        if([cur isViewConstrained])
        {
            [viewConstraintSet removeObject:cur];
        }
 		[activeSet removeObject:cur];
	}
	[purgeSet removeAllObjects];
    
    // spawn
	for(id cur in spawnSet)
	{
		[activeSet addObject:cur];
        if([cur isViewConstrained])
        {
            [viewConstraintSet addObject:cur];
        }
	}
	[spawnSet removeAllObjects];

    // constrain to view
    for(NSObject<ConstraintDelegate>* cur in viewConstraintSet)
    {
        BOOL atEdge = NO;
        CGPoint curPos = [cur getPos];
        CGPoint newPos = curPos;
        if(curPos.x < viewConstraint.origin.x)
        {
            newPos.x = viewConstraint.origin.x;
            atEdge = YES;
        }
        else if(curPos.x > (viewConstraint.origin.x + viewConstraint.size.width))
        {
            newPos.x = (viewConstraint.origin.x + viewConstraint.size.width);
            atEdge = YES;
        }
        if(curPos.y < viewConstraint.origin.y)
        {
            newPos.y = viewConstraint.origin.y;
            atEdge = YES;
        }
        else if(curPos.y > (viewConstraint.origin.y + viewConstraint.size.height))
        {
            newPos.y = (viewConstraint.origin.y + viewConstraint.size.height);
            atEdge = YES;
        }
        if(atEdge)
        {
            [cur setPos:newPos];
            [cur setVel:CGPointMake(0.0f, 0.0f)];
        }
    }
    
}

- (void) addDraw
{
    for(NSObject<DynamicDelegate>* cur in activeSet)
	{
		[cur addDraw];
	}
}

@end
