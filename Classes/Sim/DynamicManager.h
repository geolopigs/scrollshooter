//
//  DynamicManager.h
//	Manages all dynamic objects in the scene
//	including player and enemies
//

#import <Foundation/Foundation.h>

@protocol DynamicDelegate;
@protocol CollisionDelegate;
@interface DynamicManager : NSObject 
{
	NSMutableSet* activeSet;
	NSMutableSet* purgeSet;
	NSMutableSet* spawnSet;
    
    CGRect viewConstraint;
    NSMutableSet* viewConstraintSet;   
}
+ (DynamicManager*)getInstance;
+ (void) destroyInstance;

- (void) reset;

- (void) setViewConstraintFromGame:(CGRect)gameViewportRect;
- (void) addObject:(NSObject<DynamicDelegate>*)dynamicObject;
- (void) removeObject:(NSObject<DynamicDelegate>*)dynamicObject;

- (void) update:(NSTimeInterval)elapsed isPaused:(BOOL)paused;
- (void) addDraw;

@end
