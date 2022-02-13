//
//  LootProtocols.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Loot;

@protocol LootInitDelegate <NSObject>
- (void) initLoot:(Loot*)loot isDynamics:(BOOL)isDynamics;
@end

@protocol LootBehaviorDelegate<NSObject>
- (void) update:(NSTimeInterval)elapsed forLoot:(Loot*)givenLoot;
- (NSString*) getTypeName;
- (void) releasePickup:(Loot*)givenPickup;
@end

@protocol LootCollisionResponse <NSObject>
- (void) loot:(Loot*)loot respondToCollisionWithAABB:(CGRect)givenAABB;
- (BOOL) isCollisionOn:(Loot*)loot;
@end

@protocol lootAABBDelegate <NSObject>
- (CGRect) getAABB:(Loot*)givenLoot;
@end

@protocol LootCollectedDelegate <NSObject>
- (void) collectLoot:(Loot*)givenLoot; 
@end

@protocol LootContextDelegate <NSObject>

@end

