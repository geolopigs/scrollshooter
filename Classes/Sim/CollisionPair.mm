//
//  CollisionPair.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "CollisionPair.h"

@implementation CollisionPair
@synthesize thisObject;
@synthesize theOtherObject;

- (id) initWithObject1:(NSObject<CollisionDelegate> *)object1 object2:(NSObject<CollisionDelegate> *)object2
{
    self = [super init];
    if (self) 
    {
        self.thisObject = object1;
        self.theOtherObject = object2;
    }
    
    return self;
}

- (void) dealloc
{
    self.theOtherObject = nil;
    self.thisObject = nil;
    [super dealloc];
}

@end
