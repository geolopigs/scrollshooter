//
//  UIColor+Utils.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/15/14.
//  Copyright (c) 2014 GeoloPigs. All rights reserved.
//

#import "UIColor+Utils.h"

@implementation UIColor (Utils)
+ (UIColor*) colorWithHex:(NSInteger)hex {
    CGFloat red = (CGFloat)((hex & 0xFF000000) >> 0x18) / 255.0;
    CGFloat green = (CGFloat)((hex & 0x00FF0000) >> 0x10) / 255.0;
    CGFloat blue = (CGFloat)((hex & 0x0000FF00) >> 0x8) / 255.0;
    CGFloat alpha = (CGFloat)(hex & 0x000000FF) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
