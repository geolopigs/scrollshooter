//
//  AddonFactory.h
//  PeterPog
//  
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddonProtocols.h"

@class Addon;
@class LevelAnimData;

@interface AddonFactory : NSObject
{
    NSMutableDictionary* archetypeLib;
}
@property (nonatomic,retain) NSMutableDictionary* archetypeLib;

- (id) initWithLevelAnimData:(LevelAnimData*)data;
- (Addon*) createAddonNamed:(NSString*)name atPos:(CGPoint)initPos;

@end
