//
//  AnimSprite.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/17/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Sprite;
@class AnimClip;

@interface AnimSprite : NSObject
{
    AnimClip* anim;
    Sprite* sprite;
}
@property (nonatomic,retain) AnimClip* anim;
@property (nonatomic,retain) Sprite* sprite;

- (id) initWithSprite:(Sprite*)givenSprite animClip:(AnimClip*)givenAnim;
- (void) spawn;
- (void) kill;
@end
