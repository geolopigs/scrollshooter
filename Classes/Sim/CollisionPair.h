//
//  CollisionPair.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CollisionProtocols.h"

@interface CollisionPair : NSObject
{
    NSObject<CollisionDelegate>* thisObject;
    NSObject<CollisionDelegate>* theOtherObject;
}
@property (nonatomic,retain) NSObject<CollisionDelegate>* thisObject;
@property (nonatomic,retain) NSObject<CollisionDelegate>* theOtherObject;
- (id) initWithObject1:(NSObject<CollisionDelegate>*)object1 object2:(NSObject<CollisionDelegate>*)object2;
@end
