//
//  UpgradePack.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/26/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LootProtocols.h"
#import "CollisionProtocols.h"

@interface UpgradePackContext : NSObject
{
    CGPoint initPos;
    float lifeSpanRemaining;
    float swingParam;
    float swingVel;
    BOOL willRelease;
}
@property (nonatomic,assign) CGPoint initPos;
@property (nonatomic,assign) float lifeSpanRemaining;
@property (nonatomic,assign) float swingParam;
@property (nonatomic,assign) float swingVel;
@property (nonatomic,assign) BOOL willRelease;
@end

@interface UpgradePack : NSObject<LootInitDelegate,LootBehaviorDelegate,LootCollectedDelegate,LootCollisionResponse,lootAABBDelegate>
{
    NSString* typeName;
    NSString* sizeName;
    NSString* clipName;    
}
@property (nonatomic,retain) NSString* typeName;
@property (nonatomic,retain) NSString* sizeName;
@property (nonatomic,retain) NSString* clipName;
- (id) initWithTypeName:(NSString*)givenName 
               sizeName:(NSString*)givenSizeName 
               clipName:(NSString*)givenClipName;

@end
