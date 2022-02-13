//
//  PogUIUtility.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogUIUtility.h"

@implementation PogUIUtility

#pragma mark - utility functions

static const float kSecondsPerHour = 3600.0;
static const float kSecondsPerMinute = 60.0;
+ (NSString*) stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSString* result = nil;    
    NSTimeInterval hoursValue = floor(timeInterval / kSecondsPerHour);
    NSTimeInterval minutesValue = floor((timeInterval - (hoursValue * kSecondsPerHour)) / kSecondsPerMinute);
    NSTimeInterval secondsValue = floor(timeInterval - (hoursValue * kSecondsPerHour) - (minutesValue * kSecondsPerMinute));
    
    unsigned int hoursInt = (unsigned int)(hoursValue);
    unsigned int minutesInt = (unsigned int)(minutesValue);
    unsigned int secondsInt = (unsigned int)(secondsValue);
    
    NSString* minutesString = [NSString stringWithFormat:@"%d", minutesInt];
    if(10 > minutesInt)
    {
        minutesString = [NSString stringWithFormat:@"0%d", minutesInt];
    }
    NSString* secondsString = [NSString stringWithFormat:@"%d", secondsInt];
    if(10 > secondsInt)
    {
        secondsString = [NSString stringWithFormat:@"0%d", secondsInt];
    }
    if(0 < hoursInt)
    {
        result = [NSString stringWithFormat:@"%d:%@:%@", hoursInt, minutesString, secondsString];
    }
    else
    {
        result = [NSString stringWithFormat:@"%@:%@", minutesString, secondsString];        
    }
    return result;
}

+ (NSString*) commaSeparatedStringFromUnsignedInt:(unsigned int)number
{
    NSNumberFormatter *priceStyle = [[NSNumberFormatter alloc] init];
    
    // set options.
    [priceStyle setFormatterBehavior:[NSNumberFormatter defaultFormatterBehavior]];
    [priceStyle setNumberStyle:NSNumberFormatterCurrencyStyle];
    [priceStyle setMaximumFractionDigits:0];
    [priceStyle setCurrencySymbol:@""];
    
    // get formatted string
    NSString* formatted = [priceStyle stringFromNumber:[NSNumber numberWithUnsignedInt:number]]; 
    return formatted;
}

+ (void) followUsOnTwitter
{
    // open the twitter app first, if twitter app not found, open it in safari
    NSString *peterpogTwitterLink = @"twitter://user?screen_name=geolopigs";  
    BOOL twitterAppOpened = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:peterpogTwitterLink]];  
    if(!twitterAppOpened)
    {
        NSString* peterpogTwitterHttpLink = @"http://twitter.com/#!/geolopigs";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:peterpogTwitterHttpLink]];
    }    
}

@end
