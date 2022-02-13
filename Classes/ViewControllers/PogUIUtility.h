//
//  PogUIUtility.h
//  PeterPog
//
//  Utility functions for UI
//
//  Created by Shu Chiun Cheah on 2/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PogUIUtility : NSObject

+ (NSString*) stringFromTimeInterval:(NSTimeInterval)timeInterval;
+ (NSString*) commaSeparatedStringFromUnsignedInt:(unsigned int)number;
+ (void) followUsOnTwitter;
@end
