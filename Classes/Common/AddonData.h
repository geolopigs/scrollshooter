//
//  AddonData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AddonData : NSObject
{
    // top-level of file
    NSDictionary* fileData;
    
    // internal cache
    NSDictionary* registry;
    NSMutableArray* names;
    
    // params
    BOOL hasWeaponLayers;
    unsigned int numWeaponLayers;
}
@property (nonatomic,retain) NSDictionary* fileData;
- (id)initFromFilename:(NSString *)filename;

// accessor methods - generic
@property (nonatomic,readonly) unsigned int numGroups;
@property (nonatomic,readonly) unsigned int numWeaponLayers;
- (NSString*) getNameAtIndex:(int)index;

// accessor methods - specific
- (CGPoint) getOffsetAtIndex:(unsigned int)index forGroup:(NSString*)groupname;
- (unsigned int) getNumForGroup:(NSString*)groupname;
@end
