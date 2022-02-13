//
//  PickupSpec.h
//  PeterPog
//
//  Specification of game rationed pick-ups
//
//  Created by Shu Chiun Cheah on 9/8/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PickupSpec : NSObject
{
    NSString* typeName;
    unsigned int number;
}
@property (nonatomic,retain) NSString* typeName;
@property (nonatomic,assign) unsigned int number;

- (id) initWithType:(NSString*)name number:(unsigned int)amount;

@end
