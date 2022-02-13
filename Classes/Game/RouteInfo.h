//
//  RouteInfo.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/15/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
enum RouteTypes
{
    ROUTETYPE_LAND = 0,
    ROUTETYPE_SEA,
    ROUTETYPE_AIR,
    
    ROUTETYPE_NUM
};

@interface RouteInfo : NSObject
{
    unsigned int routeType;
    NSString* routeName;
    NSString* serviceName;
    NSString* envName;
    unsigned int envIndex;
    unsigned int levelIndex;
    BOOL selectable;
    unsigned int devCost;
}
@property (nonatomic,retain) NSString* routeName;
@property (nonatomic,retain) NSString* serviceName;
@property (nonatomic,retain) NSString* envName;
@property (nonatomic,assign) unsigned int envIndex;
@property (nonatomic,assign) unsigned int levelIndex;
@property (nonatomic,assign) BOOL selectable;
@property (nonatomic,assign) unsigned int devCost;

- (void) setRouteTypeFromName:(NSString*)name;
- (unsigned int) routeType;

@end
