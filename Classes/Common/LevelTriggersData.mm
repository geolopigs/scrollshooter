//
//  LevelTriggersData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LevelTriggersData.h"
#import "Trigger.h"

@interface LevelTriggersData (PrivateMethods)
- (void) initTriggersArray;
@end

@implementation LevelTriggersData
@synthesize fileData;
@synthesize triggers;

- (id) initFromFilename:(NSString*)filename;
{
    self = [super init];
    if (self) 
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"];
        self.fileData = [NSDictionary dictionaryWithContentsOfFile:path];
        self.triggers = [NSMutableArray array];
        [self initTriggersArray];
    }
    
    return self;
}

- (void) dealloc
{
    self.triggers = nil;
    self.fileData = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Private Methods
- (void) initTriggersArray
{
    NSArray* triggersArray = [self.fileData objectForKey:@"triggers"];
    for(NSDictionary* curTrigger in triggersArray)
    {
        float triggerPoint = [[curTrigger objectForKey:@"point"] floatValue];
        NSString* triggerEvent = [NSString stringWithString:[curTrigger objectForKey:@"event"]];
        NSString* triggerEventName = [NSString stringWithString:[curTrigger objectForKey:@"label"]];
        NSNumber* triggerNumber = [curTrigger objectForKey:@"number"];
        NSDictionary* triggerContext = [curTrigger objectForKey:@"context"];
        Trigger* newTrigger = [[Trigger alloc] initWithPoint:triggerPoint 
                                                       event:triggerEvent 
                                                       label:triggerEventName 
                                                      number:triggerNumber
                                                     context:triggerContext];
        
        // insert new trigger into the triggers array in ascending triggerPoint values
        int index = [triggers count] - 1;
        while(0 <= index)
        {
            Trigger* compare = [triggers objectAtIndex:index];
            if(compare.triggerPoint <= newTrigger.triggerPoint)
            {
                break;
            }
            --index;
        }
        if((index+1) >= [triggers count])
        {
            [triggers addObject:newTrigger];
        }
        else
        {
            [triggers insertObject:newTrigger atIndex:(index+1)];
        }
        [newTrigger release];
    }
}

@end
