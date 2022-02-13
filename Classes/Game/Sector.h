//
//  Sector.h
//! \brief Sectors are non-overlapping rectangular areas in a Level
//  
//
//  Created by Shu Chiun Cheah on 6/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Texture;
@class BgLayer;
@interface Sector : NSObject
{
    CGRect      rect;           // position and dimension of Sector in meters
    Texture*    bgTex;  // the background texture for this Sector
    
    BgLayer*    renderer;
    unsigned int bucketId;
}
@property (nonatomic,assign) CGRect rect;
@property (nonatomic,retain) Texture* bgTex;
@property (nonatomic,retain) BgLayer* renderer;

- (id) initFromBgTex:(Texture*)tex atPosition:(CGPoint)pos withWidth:(float)width;
- (void) addDraw;
@end
