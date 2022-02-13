//
//  CamPath.mm
//  Curry
//
//  Created by Shu Chiun Cheah on 7/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "CamPath.h"
#include "MathUtils.h"

#pragma mark - CamPathSegment
@interface CamPathSegment : NSObject
{
    CGPoint pointA;
    CGPoint pointB;
    float   beginParam;
    float   duration;
    float   funcM;
    float   funcC;
    unsigned int nextSegment;
    BOOL isPartOfLoop;
}
@property (nonatomic,assign) CGPoint pointA;
@property (nonatomic,assign) CGPoint pointB;
@property (nonatomic,assign) unsigned int nextSegment;
@property (nonatomic,assign) float beginParam;
@property (nonatomic,assign) float duration;
@property (nonatomic,assign) BOOL isPartOfLoop;
- (id) initWithPtA:(CGPoint)ptA ptB:(CGPoint)ptB beginParam:(float)begin duration:(float)segmentDuration nextSegment:(unsigned int)next;
- (float) pointYFromParam:(float)param;
@end

@implementation CamPathSegment
@synthesize pointA;
@synthesize pointB;
@synthesize nextSegment;
@synthesize beginParam;
@synthesize duration;
@synthesize isPartOfLoop;
- (id) initWithPtA:(CGPoint)ptA ptB:(CGPoint)ptB beginParam:(float)begin duration:(float)segmentDuration nextSegment:(unsigned int)next
{
    self = [super init];
    if(self)
    {
        pointA = ptA;
        pointB = ptB;
        beginParam = begin;
        duration = segmentDuration;
        nextSegment = next;
        
        funcM = (pointB.y - pointA.y) / duration;
        funcC = pointA.y - (funcM * beginParam);
        
        isPartOfLoop = NO;
    }
    return self;
}

- (float) pointYFromParam:(float)param
{
    float result = (funcM * param) + funcC;
    return result;
}
@end


#pragma mark -
#pragma mark CamPath

@interface CamPath (PrivateMethods)
- (void) initLoops;
@end

@implementation CamPath
@synthesize pathSegments;
@synthesize curTimeParam;
@synthesize curPathSegment;
@synthesize isInLoop;
@synthesize paused;

static const float SEGMENT_DURATION = 5.0f;

#pragma mark - private methods
- (void) initLoops
{
#if defined(DEBUG)
    {
        // assert that there is no overlapping loops
        unsigned int index = 0;
        unsigned int lastLoopIndex = 0;
        for(CamPathSegment* cur in pathSegments)
        {
            if([cur nextSegment] < index)
            {
                assert([cur nextSegment] >= lastLoopIndex);
                lastLoopIndex = index;
            }
            ++index;
        }
    }
#endif
    unsigned int curIndex = 0;
    for(CamPathSegment* cur in pathSegments)
    {
        if([cur nextSegment] < curIndex)
        {
            // mark all segments in the loop
            unsigned int loopIndex = [cur nextSegment];
            while(loopIndex <= curIndex)
            {
                CamPathSegment* loopSegment = [pathSegments objectAtIndex:loopIndex];
                loopSegment.isPartOfLoop = YES;
                ++loopIndex;
            }
        }
        ++curIndex;
    }
}

#pragma mark - public methods
- (id) initFromPointsArray:(NSArray*)pointsArray
{
    self = [super init];
    if(self)
    {
        // must have at least 2 control points
        assert(2 <= [pointsArray count]);        
        self.pathSegments = [NSMutableArray arrayWithCapacity:[pointsArray count]-1];
        unsigned int segIndex = 0;
        unsigned int segNext = 0;
        float durationAcc = 0.0f;
        
        // compute duration from speed only if the speed param is provided on all points (except the last)
        unsigned int speedCount = 0;
        NSMutableArray* durationArray = nil;
        for(NSDictionary* cur in pointsArray)
        {
            if([cur objectForKey:@"speed"])
            {
                ++speedCount;
            }
        }
        if(speedCount >= ([pointsArray count]-1))
        {
            durationArray = [NSMutableArray array];
            NSMutableArray* posYArray = [NSMutableArray array];
            for(NSDictionary* cur in pointsArray)
            {
                [posYArray addObject:[cur objectForKey:@"posY"]];                
            }            
            NSMutableArray* speedArray = [NSMutableArray array];
            unsigned int pointsIndex = 0;
            while(pointsIndex < ([pointsArray count]-1))
            {
                NSDictionary* cur = [pointsArray objectAtIndex:pointsIndex];
                [speedArray addObject:[cur objectForKey:@"speed"]];
                ++pointsIndex;
            }
            unsigned int speedIndex = 0;
            while(speedIndex < [speedArray count])
            {
                float curSpeed = [[speedArray objectAtIndex:speedIndex] floatValue];
                float curPosY = [[posYArray objectAtIndex:speedIndex] floatValue];
                float nextPosY = [[posYArray objectAtIndex:(speedIndex+1)] floatValue];
                float duration = (nextPosY - curPosY) / curSpeed;
                [durationArray addObject:[NSNumber numberWithFloat:duration]];
                ++speedIndex;
            }
        }
        
        unsigned int durationIndex = 0;
        for(NSDictionary* cur in pointsArray)
        {
            CGPoint pointA = CGPointMake([[cur objectForKey:@"posX"] floatValue],
                                           [[cur objectForKey:@"posY"] floatValue]);
            float duration = 1.0f;
            if((durationArray) && (durationIndex < [durationArray count]))
            {
                duration = [[durationArray objectAtIndex:durationIndex] floatValue];
            }
            else
            {
                duration = [[cur objectForKey:@"duration"] floatValue];
            }
            
            segNext = segIndex + 1;
            /*
            if([cur objectForKey:@"nextSegment"])
            {
                segNext = [[cur objectForKey:@"nextSegment"] unsignedIntValue];
            }
            */
            if(segNext < [pointsArray count])
            {
                NSDictionary* next = [pointsArray objectAtIndex:segNext];
                CGPoint pointB = CGPointMake([[next objectForKey:@"posX"] floatValue],
                                             [[next objectForKey:@"posY"] floatValue]);
                if([next objectForKey:@"nextSegment"])
                {   
                    // override with value from data if one is specified
                    segNext = [[next objectForKey:@"nextSegment"] unsignedIntValue];
                }
                CamPathSegment* newSeg = [[CamPathSegment alloc] initWithPtA:pointA ptB:pointB beginParam:durationAcc duration:duration nextSegment:segNext];
                [pathSegments addObject:newSeg];
                [newSeg release];
                ++segIndex;
                durationAcc = durationAcc + duration;
            }
            else
            {
                // done with all the segments
                break;
            }
               
            ++durationIndex;
        }
        [self initLoops];
        loopable = YES;
        isInLoop = NO;
        shouldBreakLoop = NO;
        paused = NO;
        [self resetFollow];
    }
    return self;
}


- (void) dealloc
{
    [pathSegments release];
    [super dealloc];
}


#pragma mark -
#pragma mark Path Following methods
- (void) resetFollow
{
    self.curTimeParam = 0.0f;
    self.curPathSegment = 0;
    loopable = YES;
}


- (CGPoint) updateFollow:(NSTimeInterval)elapsed
{
    if([pathSegments count] > curPathSegment)
    {
        CamPathSegment* curTimeSegment = [pathSegments objectAtIndex:curPathSegment];
        curTimeParam += elapsed;
        float curPointY = [curTimeSegment pointYFromParam:curTimeParam];
        if(curPointY >= curTimeSegment.pointB.y)
        {
            // cross over to the next segment
            if(curPathSegment < curTimeSegment.nextSegment)
            {
                curPathSegment = curTimeSegment.nextSegment;
            }
            else
            {
                if(shouldBreakLoop)
                {
                    isInLoop = NO;
                    shouldBreakLoop = NO;
                    
                    // break it by going to the next segment
                    unsigned int nextSeg = curPathSegment + 1;
                    if(nextSeg < [pathSegments count])
                    {
                        // there is a next segment, go to it
                        curPathSegment = nextSeg;
                    }
                    else
                    {
                        // end of path
                        curPathSegment = [pathSegments count];
                    }
                }
                else if(loopable)
                {
                    // this is a loop-back to an earlier segment
                    curPathSegment = curTimeSegment.nextSegment;
                    
                    // set time-param to the beginning of this segment by adding up the duration of all previous segments
                    unsigned int segmentIndex = 0;
                    float newTime = 0.0f;
                    while(segmentIndex < curPathSegment)
                    {
                        CamPathSegment* thisSegment = [pathSegments objectAtIndex:segmentIndex];
                        newTime += [thisSegment duration];
                        ++segmentIndex;
                    }
                    curTimeParam = newTime;
                }
                else
                {
                    // not loopable and encountered a loop back
                    // just set it to end of path
                    curPathSegment = [pathSegments count];
                }                
            }
            
            if(curPathSegment < [pathSegments count])
            {
                isInLoop = [[pathSegments objectAtIndex:curPathSegment] isPartOfLoop];
            }
        }
    }
    CGPoint result = [self getCurFollow];
    
    return result;
}

- (CGPoint) getCurFollow
{
    CGPoint result = CGPointMake(0.0f, 0.0f);
    if([pathSegments count] > curPathSegment)
    {
        CamPathSegment* curTimeSegment = [pathSegments objectAtIndex:curPathSegment];
        result = CGPointMake(curTimeSegment.pointA.x,
                                       [curTimeSegment pointYFromParam:curTimeParam]);
    }
    else
    {
        // end of path
        CamPathSegment* curTimeSegment = [pathSegments objectAtIndex:[pathSegments count]-1];
        result = CGPointMake(curTimeSegment.pointA.x,
                                       [curTimeSegment pointYFromParam:(curTimeSegment.beginParam + curTimeSegment.duration)]);
    }
    return result;    
}

- (BOOL) isAtEndOfPath
{
    BOOL result = NO;
    if([pathSegments count] <= curPathSegment)
    {
        result = YES;
    }
    return result;
}

- (void) stopLoop
{
    loopable = NO;
    isInLoop = NO;
}

- (void) breakCurrentLoop
{
    if(isInLoop)
    {
        shouldBreakLoop = YES;
    }
}

@end
