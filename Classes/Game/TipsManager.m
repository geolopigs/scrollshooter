//
//  TipsManager.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TipsManager.h"

@interface TipsManager ()
{
    NSDictionary* _tipsRegistry;
}
@end

@implementation TipsManager

- (id) init
{
    self = [super init];
    if(self)
    {
        //NSString *path = [[NSBundle mainBundle] pathForResource:@"Tips" ofType:@"plist"];
        //_tipsRegistry = [[NSDictionary dictionaryWithContentsOfFile:path] retain];

    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}


#pragma mark - Singleton
static TipsManager* singleton = nil;
+ (TipsManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[TipsManager alloc] init] retain];
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
