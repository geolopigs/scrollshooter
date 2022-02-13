//
//  LevelPathData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CamPath;
@interface LevelPathData : NSObject
{
    // plist data
    NSDictionary* fileData;
    
    // loaded and initialized data
    NSMutableDictionary* pathsDictionary;
}
@property (nonatomic,retain) NSDictionary* fileData;
@property (nonatomic,retain) NSMutableDictionary* pathsDictionary;
- (id) initFromFilename:(NSString*)filename;
- (CamPath*) getPathForLayername:(NSString*)layerName;
- (void) duplicatePathNamed:(NSString*)srcName toName:(NSString*)tgtName;
@end
