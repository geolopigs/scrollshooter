//
//  LevelTileData.mm
//  Pogditor
//
//  Created by Shu Chiun Cheah on 8/30/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LevelTileData.h"

@implementation LevelTileData
@synthesize textureName;
@synthesize orientation;
- (id)initWithTextureName:(NSString*)name orientation:(int)texOrientation
{
    self = [super init];
    if (self) 
    {
        self.textureName = [name stringByDeletingPathExtension];
        if((0 <= texOrientation) && (LEVELTILE_ORIENTATION_NUM > texOrientation))
        {
            self.orientation = texOrientation;
        }
        else
        {
            self.orientation = LEVELTILE_ORIENTATION_IDENTITY;
        }
    }
    
    return self;
}

- (void) dealloc
{
    self.textureName = nil;
    [super dealloc];
}

@end
