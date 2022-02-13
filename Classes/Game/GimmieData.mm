//
//  GimmieData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/27/11.
//  Copyright 2012 GeoloPigs. All rights reserved.
//

#import "GimmieData.h"

static NSString* const COMPLETEDEVENTS_KEY = @"CompletedEvents";    // this is not used anymore, kept here for backwards compatibility
static NSString* const GIMMIEACTIVATED_KEY = @"GimmieActivated";
static NSString* const REPORTEDEVENTS_KEY = @"Reported";
static NSString* const GIMMIEVERSION_KEY = @"Version";
static NSString* const REPEATEDEVENTS_KEY = @"RepeatedEvents";
static const NSInteger GIMMIEDATAVERSION = 1;

@implementation GimmieData
@synthesize completedEvents = _completedEvents;
@synthesize gimmieActivated = _gimmieActivated;
@synthesize repeatedEvents = _repeatedEvents;

- (id)init
{
    self = [super init];
    if (self) 
    {
        _completedEvents = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
        _gimmieActivated = NO;
        _repeatedEvents = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
    }
    return self;
}

- (void) dealloc
{
    [_repeatedEvents release];
    [_completedEvents release];
    [super dealloc];
}


#pragma mark -
#pragma mark NSCoding methods

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:_completedEvents forKey:REPORTEDEVENTS_KEY];
    [coder encodeBool:_gimmieActivated forKey:GIMMIEACTIVATED_KEY];
    [coder encodeInteger:GIMMIEDATAVERSION forKey:GIMMIEVERSION_KEY];
    [coder encodeObject:_repeatedEvents forKey:REPEATEDEVENTS_KEY];
}

- (id) initWithCoder:(NSCoder *) decoder
{
    self.completedEvents = [decoder decodeObjectForKey:REPORTEDEVENTS_KEY];    
    if(![self completedEvents])
    {
        // for backwards compatibility, handle when reported-events array is nil
        _completedEvents = [[NSMutableDictionary dictionaryWithCapacity:1] retain];   
    }
    self.gimmieActivated = [decoder decodeBoolForKey:GIMMIEACTIVATED_KEY];
    
    self.repeatedEvents = [decoder decodeObjectForKey:REPEATEDEVENTS_KEY];
    if(![self repeatedEvents])
    {
        _repeatedEvents = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
    }
	return self;
}

@end
