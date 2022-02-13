//
//  CollisionManager.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "CollisionManager.h"
#import "CollisionPair.h"

#if defined(DEBUG)
#import "Enemy.h"
#endif

@interface DetectionPair : NSObject
{
    NSMutableSet* thisSet;
    NSMutableSet* theOtherSet;
}
@property (nonatomic,retain) NSMutableSet* thisSet;
@property (nonatomic,retain) NSMutableSet* theOtherSet;
- (id) initWithThisSet:(NSMutableSet*)set1 theOtherSet:(NSMutableSet*)set2;
@end


@implementation DetectionPair
@synthesize thisSet;
@synthesize theOtherSet;
- (id) initWithThisSet:(NSMutableSet *)set1 theOtherSet:(NSMutableSet *)set2
{
    self = [super init];
    if(self)
    {
        self.thisSet = set1;
        self.theOtherSet = set2;
    }
    return self;
}

- (void) dealloc
{
    self.theOtherSet = nil;
    self.thisSet = nil;
    [super dealloc];
}
@end


@implementation CollisionManager
@synthesize  collisionSets;
@synthesize purgeSet;
@synthesize detectionArray;
@synthesize responseSet;

#pragma mark -
#pragma mark Singleton
static CollisionManager* singletonInstance = nil;
+ (CollisionManager*) getInstance
{
	@synchronized(self)
	{
		if (!singletonInstance)
		{
			singletonInstance = [[[CollisionManager alloc] init] retain];
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
#pragma mark Public Methods

- (id)init
{
    self = [super init];
    if (self) 
    {
        self.collisionSets = [NSMutableDictionary dictionaryWithCapacity:3];
        self.purgeSet = [NSMutableSet set];
        self.detectionArray = [NSMutableArray arrayWithCapacity:3];
        self.responseSet = [NSMutableArray array];
    }
    
    return self;
}

- (void) dealloc
{
    self.responseSet = nil;
    self.detectionArray = nil;
    self.purgeSet = nil;
    self.collisionSets = nil;
    [super dealloc];
}

- (void) reset
{
    // collect garbage
    [self collectGarbage];
    
    // clear out all responses
    [responseSet removeAllObjects];
    
    // empty out all collision controllers and clips
    for(NSString* curSetName in collisionSets)
    {
        NSMutableSet* curSet = [collisionSets objectForKey:curSetName];
        [curSet removeAllObjects];
    }
}

- (void) newCollisionSetWithName:(NSString*)setName
{
    NSMutableSet* newSet = [collisionSets objectForKey:setName];
    assert(nil == newSet);
    newSet = [NSMutableSet set];
    [collisionSets setObject:newSet forKey:setName];
}

- (void) addCollisionDelegate:(NSObject<CollisionDelegate>*)delegate toSetNamed:(NSString*)setName
{
    NSMutableSet* curSet = [collisionSets objectForKey:setName];
    assert(curSet);
    [curSet addObject:delegate];
}

- (void) removeCollisionDelegate:(NSObject<CollisionDelegate> *)delegate
{
    [purgeSet addObject:delegate];
}

- (void) addDetectionPairForSet:(NSString*)thisSet against:(NSString*)theOtherSet
{
    NSMutableSet* set1 = [collisionSets objectForKey:thisSet];
    NSMutableSet* set2 = [collisionSets objectForKey:theOtherSet];
    assert(set1);
    assert(set2);
    DetectionPair* newPair = [[DetectionPair alloc] initWithThisSet:set1 theOtherSet:set2];
    [detectionArray addObject:newPair];
    [newPair release];
}

- (void) processDetection:(NSTimeInterval)elapsed
{    
    // brute force
    for(DetectionPair* cur in detectionArray)
    {
        for(NSObject<CollisionDelegate>* thisObject in [cur thisSet])
        {
            if([thisObject isCollisionOn])
            {
                CGRect thisAABB = [thisObject getAABB];
                for(NSObject<CollisionDelegate>* theOther in [cur theOtherSet])
                {
                    if([theOther isCollisionOn])
                    {
                        CGRect theOtherAABB = [theOther getAABB];
                        if(((theOtherAABB.origin.y + theOtherAABB.size.height) >= thisAABB.origin.y) &&
                           (theOtherAABB.origin.y <= (thisAABB.origin.y + thisAABB.size.height)) &&
                           ((theOtherAABB.origin.x + theOtherAABB.size.width) >= thisAABB.origin.x) &&
                           (theOtherAABB.origin.x <= (thisAABB.origin.x + thisAABB.size.width)))
                        {
                            // collided
                            CollisionPair* collidedPair = [[CollisionPair alloc] initWithObject1:thisObject object2:theOther];
                            [responseSet addObject:collidedPair];
                            [collidedPair release];
                            break;
                        }
                    }
                }
            }
        }
    }
}

- (void) processResponse:(NSTimeInterval)elapsed
{
    if(0 < [responseSet count])
    {
        for(CollisionPair* curPair in responseSet)
        {
            [[curPair thisObject] respondToCollisionFrom:[curPair theOtherObject]];
            [[curPair theOtherObject] respondToCollisionFrom:[curPair thisObject]];
        }
        [responseSet removeAllObjects];
    }
}

- (void) collectGarbage
{
    for(NSObject<CollisionDelegate>* cur in purgeSet)
    {
        BOOL purged = NO;
        for(NSString* curSetName in collisionSets)
        {
            NSMutableSet* curSet = [collisionSets objectForKey:curSetName];
            if([curSet containsObject:cur])
            {
                [curSet removeObject:cur];
                purged = YES;
                break;
            }
        }
        /*
#if defined(DEBUG)
        if(!purged)
        {
            if([cur isMemberOfClass:[Enemy class]])
            {
                Enemy* debugEnemy = (Enemy*) cur;
                NSLog(@"collision garbage not found:%@",debugEnemy.behaviorContext);
            }
            else
            {
                NSLog(@"collision garbage not found: %@",cur);
            }
        }
#endif
         */
    }
    [purgeSet removeAllObjects];
}


@end
