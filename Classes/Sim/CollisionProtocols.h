//
//  CollisionProtocols.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol CollisionDelegate<NSObject>
- (CGRect) getAABB;
- (void) respondToCollisionFrom:(NSObject<CollisionDelegate>*)theOtherObject;
- (BOOL) isCollisionOn;         // for use by objects to turn on/off collision at runtime
- (BOOL) isBullet;              // used to distinguish regular enemies from Laser, Missiles, etc.
- (BOOL) isFriendlyToPlayer;
@end