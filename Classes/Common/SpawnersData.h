//
//  SpawnersData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpawnersData : NSObject
{
    // internal cache
    NSDictionary* registry;
    NSMutableArray* names;
}
// pointer to the raw data
@property (nonatomic,retain) NSDictionary* fileData;
- (id)initFromFilename:(NSString *)filename;

// accessor methods - generic
@property (nonatomic,readonly) unsigned int numGroups;
- (NSString*) getNameAtIndex:(int)index;

// accessor methods - per group
- (CGPoint) getOffsetAtIndex:(unsigned int)index forGroup:(NSString*)groupname;
- (unsigned int) getNumForGroup:(NSString*)groupname;
- (NSDictionary*) getSpawnAnimInfoForGroup:(NSString*)groupname;
- (unsigned int) getNumComponentsForGroup:(NSString*)groupname;
- (NSDictionary*) getComponentInfoForGroup:(NSString*)groupname atIndex:(unsigned int)index;
@end
