//
//  LevelAnimData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/31/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnimClipData;
@interface LevelAnimData : NSObject
{
    // plist data
    NSDictionary* fileData;
    NSDictionary* levelSpecificFileData;
    
    // loaded and initialized data
    NSMutableDictionary* animClipLib;
    NSMutableArray* effectsClipnames;
    NSMutableDictionary* levelAnimClipLib;  // level specific clips
}
@property (nonatomic,retain) NSDictionary* fileData;
@property (nonatomic,retain) NSMutableDictionary* animClipLib;
@property (nonatomic,retain) NSMutableArray* effectsClipnames;
@property (nonatomic,retain) NSDictionary* levelSpecificFileData;
@property (nonatomic,retain) NSMutableDictionary* levelSpecificAnimClipLib;

- (id) initFromFileCommon:(NSString*)commonName levelSpecific:(NSString*)levelSpecificName;
- (AnimClipData*) getClipForName:(NSString*)name;
@end
