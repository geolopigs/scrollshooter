//
//  TextEffectType.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/7/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//
#import "EffectProtocols.h"

@class Texture;
@interface TextEffectType : NSObject<EffectTypeDelegate>
{
    CGSize          effectSize;
    Texture*        effectTexture;
}
- (id)initWithString:(NSString*)text withFontNamed:(NSString*)fontName atRes:(unsigned int)numTexelLines;
@end
