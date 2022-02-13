//
//  AnimProcessor.h
//

#import <Foundation/Foundation.h>
#import "AnimProcDelegate.h"


@interface AnimProcessor : NSObject 
{
	NSMutableArray* objectList;
	NSMutableArray* removeList;
	NSMutableArray* noPauseList;
	NSMutableArray* noPauseRemoveList;
    
    NSMutableSet* clipList;
    NSMutableSet* clipPurgeList;
}
@property (nonatomic,retain) NSMutableSet* clipList;
@property (nonatomic,retain) NSMutableSet* clipPurgeList;

+ (AnimProcessor*)getInstance;
+ (void) destroyInstance;

- (void) reset;
- (void) addObject:(id)animatedObject;
- (void) removeObject:(id)animatedObject;
- (void) update:(NSTimeInterval)elapsed IsPaused:(BOOL)paused;

- (void) addClip:(NSObject<AnimProcDelegate>*)clip;
- (void) removeClip:(NSObject<AnimProcDelegate>*)clip;
- (void) advanceClips:(NSTimeInterval)elapsed;

- (void) addController:(NSObject<AnimProcDelegate>*)controller;
- (void) removeController:(NSObject<AnimProcDelegate>*)controller;
@end

@protocol AnimDelegate
- (void) updateAnim:(NSTimeInterval)elapsed;
@optional
- (BOOL) isNoPause;
@end
