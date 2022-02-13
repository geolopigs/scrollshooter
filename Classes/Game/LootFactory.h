//
//  LootFactory.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LevelAnimData;
@class Loot;
@interface LootFactory : NSObject
{
    NSMutableDictionary* lootLib;
    
    // internal cache of render bucket indices
    unsigned int addonsBucketIndex;
}
@property (nonatomic,retain) NSMutableDictionary* lootLib;

- (id) initWithLevelAnimData:(LevelAnimData*)data;
- (Loot*) createLootFromKey:(NSString*)key atPos:(CGPoint)pos isDynamics:(BOOL)isDynamics groundedBucketIndex:(unsigned int)groundedBucketIndex layerDistance:(float)layerDistance;

+ (void) spawnCargoPackAtPos:(CGPoint)pos initSwingVelFactor:(float)initSwingVelFactor introVel:(CGPoint)introVel;
+ (Loot*) spawnDynamicLootFromKey:(NSString*)key atPos:(CGPoint)pos;
+ (void) spawnDynamicLootFromKey:(NSString *)key atPos:(CGPoint)pos introVel:(CGPoint)introVel;

@end
