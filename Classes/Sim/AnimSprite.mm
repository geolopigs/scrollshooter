//
//  AnimSprite.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/17/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "AnimSprite.h"
#import "Sprite.h"
#import "AnimClip.h"
#import "AnimProcessor.h"

@implementation AnimSprite
@synthesize sprite;
@synthesize anim;

- (id) initWithSprite:(Sprite *)givenSprite animClip:(AnimClip *)givenAnim
{
    self = [super init];
    if(self)
    {
        self.sprite = givenSprite;
        self.anim = givenAnim;
    }
    return self;
}

- (void) dealloc
{
    self.anim = nil;
    self.sprite = nil;
    [super dealloc];
}

- (void) spawn
{
    [[AnimProcessor getInstance] addClip:self.anim];
    [self.anim playClipRandomForward:YES];
}

- (void) kill
{
    [[AnimProcessor getInstance] removeClip:self.anim];
}

@end
