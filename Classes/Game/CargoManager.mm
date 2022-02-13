//
//  CargoManager.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/7/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "CargoManager.h"

static const unsigned int CARGO_BASELINE = 0;
static const unsigned int CARGO_RATE_BASIC = 6;

@implementation CargoManager

- (id) init
{
    self = [super init];
    if(self)
    {
        curLevel = CARGO_BASELINE;
        curRate = CARGO_RATE_BASIC;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

#pragma mark - cargo queries
- (unsigned int) getCurrentCargoNum
{
    return curLevel;
}

- (unsigned int) getCurrentRate
{
    return curRate;
}

- (unsigned int) cashFromCargo:(unsigned int)num
{
    unsigned int result = curRate * num;
    return result;
}

#pragma mark -
#pragma mark Singleton
static CargoManager* singleton = nil;
+ (CargoManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[CargoManager alloc] init] retain];
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
