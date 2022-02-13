//
//  LevelTriggersData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LevelTriggersData : NSObject
{
    // plist data
    NSDictionary* fileData;
    
    // loaded and initialized data
    NSMutableArray* triggers;
}
@property (nonatomic,retain) NSDictionary* fileData;
@property (nonatomic,retain) NSMutableArray* triggers;
- (id) initFromFilename:(NSString*)filename;

@end
