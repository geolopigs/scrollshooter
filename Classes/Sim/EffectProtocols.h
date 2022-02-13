//
//  EffectProtocols.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/7/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AnimClipData;
@class Texture;

@protocol EffectTypeDelegate <NSObject>
@property (nonatomic,assign) CGSize effectSize;
@property (nonatomic,retain) AnimClipData* effectClipData;
@property (nonatomic,retain) Texture* effectTexture;
@end
