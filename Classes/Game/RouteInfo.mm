//
//  RouteInfo.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/15/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "RouteInfo.h"

@implementation RouteInfo
@synthesize routeName;
@synthesize serviceName;
@synthesize envName;
@synthesize envIndex;
@synthesize levelIndex;
@synthesize selectable;
@synthesize devCost;

- (id) init
{
    self = [super init];
    if(self)
    {
        routeType = ROUTETYPE_LAND;
        self.routeName = nil;
        self.serviceName = nil;
        self.envName = nil;
        envIndex = 0;
        levelIndex = 0;
        selectable = NO;
        devCost = 500;
    }
    return self;
}

- (void) dealloc
{
    self.envName = nil;
    self.serviceName = nil;
    self.routeName = nil;
    [super dealloc];
}

- (void) setRouteTypeFromName:(NSString *)name
{
    if([name isEqualToString:@"Sea"])
    {
        routeType = ROUTETYPE_SEA;
    }
    else if([name isEqualToString:@"Air"])
    {
        routeType = ROUTETYPE_AIR;
    }
    else
    {
        routeType = ROUTETYPE_LAND;
    }
}

- (unsigned int) routeType
{
    return routeType;
}
@end