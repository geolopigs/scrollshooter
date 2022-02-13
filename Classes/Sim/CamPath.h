//
//  CamPath.h
//  Curry
//
//  Created by Shu Chiun Cheah on 7/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CamPath : NSObject 
{
    NSMutableArray* pathSegments;
    
    float           curTimeParam;
    unsigned int    curPathSegment;
    
    BOOL            loopable;   // setting this to TRUE will cause updateFollow to follow segment-chains that form a loop 
                                // (following nextSegment that jusmps backward)
                                // FALSE will cause updateFollow to stop at any nextSegment that jumps backward
                                // default is TRUE
    BOOL            shouldBreakLoop;
    BOOL            isInLoop;
    BOOL            paused;
}
@property (nonatomic,retain) NSMutableArray*    pathSegments;
@property (nonatomic,assign) float              curTimeParam;
@property (nonatomic,assign) unsigned int       curPathSegment;
@property (nonatomic,readonly) BOOL             isInLoop;
@property (nonatomic,assign) BOOL               paused;

- (id) initFromPointsArray:(NSArray*)pointsArray;

- (void) resetFollow;
- (CGPoint) updateFollow:(NSTimeInterval)elapsed;
- (CGPoint) getCurFollow;
- (BOOL) isAtEndOfPath;
- (void) stopLoop;
- (void) breakCurrentLoop;

@end
