//
//  EnemyRegistryData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EnemyRegistryData : NSObject
{
    // top-level of file
    NSDictionary* fileData;
    
    // internal cache
    NSDictionary* registry;
    NSMutableArray* names;
}
@property (nonatomic,retain) NSDictionary* fileData;
- (id)initFromFilename:(NSString *)filename;

// accessor methods - generic
@property (nonatomic,readonly) unsigned int numItems;
- (NSString*) getNameAtIndex:(int)index;

// accessor methods - specific
- (int) getPointsForEnemyNamed:(NSString*)name;

@end
