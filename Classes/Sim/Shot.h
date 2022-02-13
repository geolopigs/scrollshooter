//
//  Shot.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DynamicProtocols.h"
#import "CollisionProtocols.h"

@class FiringPath;
@class AnimClip;
@interface Shot : NSObject<CollisionDelegate>
{
    CGPoint pos;
    CGPoint vel;
    CGSize  renderSize;
    CGSize  colSize;
    CGPoint scale;
    float   rotate;
    float   timer;
    
    // configs
    BOOL    hasLifeSpan;
    BOOL    isFriendly;     // friendly shots (eg. player shots and player missile trail particles)
    
    // anim
    AnimClip* animClip;
    
    // callback
    FiringPath* mySpawner;
}
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGPoint vel;
@property (nonatomic,assign) CGSize renderSize;
@property (nonatomic,assign) CGSize colSize;
@property (nonatomic,assign) CGPoint scale;
@property (nonatomic,assign) float rotate;
@property (nonatomic,assign) float timer;
@property (nonatomic,assign) BOOL hasLifeSpan;
@property (nonatomic,assign) BOOL isFriendly;
@property (nonatomic,retain) AnimClip* animClip;
@property (nonatomic,retain) FiringPath* mySpawner;

+ (id) shotWithPosition:(CGPoint)position velocity:(CGPoint)velocity renderSize:(CGSize)size colSize:(CGSize)csize;
+ (id) shotWithPosition:(CGPoint)position velocity:(CGPoint)velocity renderSize:(CGSize)size colSize:(CGSize)csize rotate:(float)rotation;
- (id) initWithPosition:(CGPoint)position velocity:(CGPoint)velocity renderSize:(CGSize)size colSize:(CGSize)csize rotate:(float)rotation;


@end
