//
//  PickupSpec.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/8/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "PickupSpec.h"

@implementation PickupSpec
@synthesize typeName;
@synthesize number;

- (id) initWithType:(NSString*)name number:(unsigned int)amount
{
    self = [super init];
    if(self)
    {
        self.typeName = name;
        self.number = amount;
    }
    return self;
}

- (void) dealloc
{
    self.typeName = nil;
    [super dealloc];
}

@end
