//
//  NSDictionary+Curry.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Curry)
- (float) getFloatForKey:(NSString*)varKey withDefault:(float)defaultValue;
- (int) getIntForKey:(NSString*)varKey withDefault:(int)defaultValue;
- (BOOL) getBoolForKey:(NSString*)varKey;
@end
