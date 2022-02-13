//
//  CargoManager.h
//  PeterPog
//
//  This manages the supply and demand of the Cargo market
//
//  Created by Shu Chiun Cheah on 9/7/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CargoManager : NSObject
{
    unsigned int curLevel;  // current cargo level
    unsigned int curRate;
}

// cargo queries
- (unsigned int) cashFromCargo:(unsigned int)num;

// singleton
+(CargoManager*) getInstance;
+(void) destroyInstance;


@end
