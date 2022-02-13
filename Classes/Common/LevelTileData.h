//
//  LevelTileData.h
//  Pogditor
//
//  Created by Shu Chiun Cheah on 8/30/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

enum LevelTileOrientation
{
    LEVELTILE_ORIENTATION_IDENTITY = 0,
    LEVELTILE_ORIENTATION_FLIPX,
    LEVELTILE_ORIENTATION_FLIPY,
    LEVELTILE_ORIENTATION_FLIPXY,
    
    LEVELTILE_ORIENTATION_NUM
};

@interface LevelTileData : NSObject
{
    NSString* textureName;
    int orientation;            // use LevelTileOrientation enum for values
}
@property (nonatomic,retain) NSString* textureName;
@property (nonatomic,assign) int orientation;

- (id)initWithTextureName:(NSString*)name orientation:(int)texOrientation;

@end
