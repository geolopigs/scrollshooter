//
//  PogAnalytics.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define USE_LOCALYTICS
//#define USE_FLURRY

@interface PogAnalytics : NSObject

// app
- (void) appBegin;
- (void) appEnd;
- (void) appEnterBackground;
- (void) appEnterForeground;

// event
- (void) logEvent:(NSString*)name;
- (void) logEvent:(NSString *)name withInfo:(NSDictionary*)info;
- (void) logTimedEvent:(NSString*)name;
- (void) logTimedEvent:(NSString *)name withInfo:(NSDictionary *)info;
- (void) logTimedEventEnd:(NSString*)name withInfo:(NSDictionary*)info;

// error
- (void) logError:(NSString*)error message:(NSString*)message exception:(NSException*)exception;

// singleton
+(PogAnalytics*) getInstance;
+(void) destroyInstance;

@end
