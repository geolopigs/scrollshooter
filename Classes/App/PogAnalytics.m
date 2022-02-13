//
//  PogAnalytics.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogAnalytics.h"
#if defined(USE_LOCALYTICS)
#import "LocalyticsSession.h"
#endif
#if defined(USE_FLURRY)
#import "FlurryAnalytics.h"
#endif
@implementation PogAnalytics

- (id) init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

#pragma mark - app operations

- (void) appBegin
{
#if defined(USE_LOCALYTICS)
    [[LocalyticsSession sharedLocalyticsSession] startSession:@"bede1b757222654d68d5ba2-c607d438-6b1d-11e1-1ebe-00a68a4c01fc"];
#endif
    
#if defined(USE_FLURRY)
    [FlurryAnalytics startSession:@"1KQXE1EAN2RMGM9KBVSH"];
    //[FlurryAnalytics setDebugLogEnabled:YES];
#endif

}

- (void) appEnd
{
#if defined(USE_LOCALYTICS)
    // Close Localytics Session
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
#endif    
}

- (void) appEnterBackground
{
#if defined(USE_LOCALYTICS)
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
#endif
}

- (void) appEnterForeground
{
#if defined(USE_LOCALYTICS)
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
#endif
}

#pragma mark - event operations
- (void) logEvent:(NSString *)name
{
#if defined(USE_LOCALYTICS)
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:name];
#endif
    
#if defined(USE_FLURRY)
    [FlurryAnalytics logEvent:name];
#endif
}

- (void) logEvent:(NSString *)name withInfo:(NSDictionary *)info
{
#if defined(USE_LOCALYTICS)
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:name attributes:info];
#endif   
    
#if defined(USE_FLURRY)
    [FlurryAnalytics logEvent:name withParameters:info];
#endif
}

- (void) logTimedEvent:(NSString *)name
{
#if defined(USE_LOCALYTICS)
    // localytics doesn't have timed event; so, just do regular event
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:name];
#endif    
    
#if defined(USE_FLURRY)
    [FlurryAnalytics logEvent:name timed:YES];
#endif
}

- (void) logTimedEvent:(NSString *)name withInfo:(NSDictionary *)info
{
#if defined(USE_LOCALYTICS)
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:name attributes:info];
#endif   
    
#if defined(USE_FLURRY)
    [FlurryAnalytics logEvent:name withParameters:info timed:YES];
#endif
}

- (void) logTimedEventEnd:(NSString *)name withInfo:(NSDictionary *)info
{
#if defined(USE_LOCALYTICS)
    // localytics doesn't have timed event; so, do nothing;
#endif   
    
#if defined(USE_FLURRY)
    [FlurryAnalytics endTimedEvent:name withParameters:info];
#endif
}

- (void) logError:(NSString *)error message:(NSString *)message exception:(NSException *)exception
{
#if defined(USE_FLURRY)
    [FlurryAnalytics logError:error message:message exception:exception];
#endif
}

#pragma mark - Singleton
static PogAnalytics* singleton = nil;
+ (PogAnalytics*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[PogAnalytics alloc] init] retain];
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


@end
