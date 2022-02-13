//
//  LootFactory.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LootFactory.h"
#import "Loot.h"
#import "LevelAnimData.h"
#import "RenderBucketsManager.h"
#import "LevelManager.h"
#import "PlayerInventoryIds.h"

#import "LootCash.h"
#import "HealthPack.h"
#import "CargoPack.h"
#import "UpgradePack.h"

@interface LootFactory (PrivateMethods)
- (void) populateLootLibWithLevelAnimData:(LevelAnimData*)data;
@end

@implementation LootFactory
@synthesize lootLib;

- (id)initWithLevelAnimData:(LevelAnimData*)data
{
    self = [super init];
    if (self) 
    {
        self.lootLib = [NSMutableDictionary dictionary];
        [self populateLootLibWithLevelAnimData:data];
        
        // cache off render bucket indices
        addonsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Addons"];
    }
    
    return self;
}

- (void) dealloc
{
    self.lootLib = nil;
    [super dealloc];
}

- (Loot*) createLootFromKey:(NSString*)key atPos:(CGPoint)pos isDynamics:(BOOL)isDynamics groundedBucketIndex:(unsigned int)groundedBucketIndex layerDistance:(float)layerDistance
{
    Loot* newLoot = nil;
    NSObject<LootInitDelegate>* cur = [lootLib objectForKey:key];
    if(cur)
    {
        newLoot = [[Loot alloc] initAtPos:pos isDynamics:isDynamics usingDelegate:cur];
        if(isDynamics)
        {
            newLoot.renderBucketIndex = addonsBucketIndex;
            newLoot.releasedAsDynamic = YES;
        }
        else
        {
            newLoot.renderBucketIndex = groundedBucketIndex;
            newLoot.layerDistance = layerDistance;
        }
    }    
    return newLoot;    
}

#pragma mark - convenience spawn functions
+ (void) spawnCargoPackAtPos:(CGPoint)pos initSwingVelFactor:(float)initSwingVelFactor introVel:(CGPoint)introVel
{
    Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:@"CargoPack" atPos:pos 
                                                                     isDynamics:YES 
                                                            groundedBucketIndex:0 
                                                                  layerDistance:100.0f];
    
    CargoPackContext* context = (CargoPackContext*) [newLoot lootContext];
    context.swingVel *= initSwingVelFactor;
    newLoot.vel = introVel;
    [newLoot spawn];
    [newLoot release];
}

+ (Loot*) spawnDynamicLootFromKey:(NSString *)key atPos:(CGPoint)pos
{
    Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:key atPos:pos 
                                                                     isDynamics:YES 
                                                            groundedBucketIndex:0 
                                                                  layerDistance:100.0f];
    [newLoot spawn];
    return [newLoot autorelease];
}

+ (void) spawnDynamicLootFromKey:(NSString *)key atPos:(CGPoint)pos introVel:(CGPoint)introVel
{
    Loot* newLoot = [[[LevelManager getInstance] lootFactory] createLootFromKey:key atPos:pos 
                                                                     isDynamics:YES 
                                                            groundedBucketIndex:0 
                                                                  layerDistance:100.0f];
    newLoot.vel = introVel;
    [newLoot spawn];
    [newLoot release];
}

#pragma mark -
#pragma mark Private Methods
- (void) populateLootLibWithLevelAnimData:(LevelAnimData*)data
{
    NSObject<LootInitDelegate,LootBehaviorDelegate>* newType = nil;
    
    // LootCash
    newType = [[LootCash alloc] init];
    [lootLib setObject:newType forKey:@"LootCash"];
    [newType release];
    
    // HealthPack
    newType = [[HealthPack alloc] init];
    [lootLib setObject:newType forKey:@"HealthPack"];
    [newType release];

    // CargoPack
    newType = [[CargoPack alloc] init];
    [lootLib setObject:newType forKey:@"CargoPack"];
    [newType release];

    // DoubleBulletPack
    newType = [[UpgradePack alloc] initWithTypeName:@"DoubleBulletUpgrade" sizeName:@"DoubleBulletUpgrade" clipName:@"DoubleBulletUpgrade"];
    [lootLib setObject:newType forKey:[newType getTypeName]];
    [newType release];

    // LaserPack
    newType = [[UpgradePack alloc] initWithTypeName:@"LaserUpgrade" sizeName:@"LaserUpgrade" clipName:@"LaserUpgrade"];
    [lootLib setObject:newType forKey:[newType getTypeName]];
    [newType release];
    
    // BoomerangPack
    newType = [[UpgradePack alloc] initWithTypeName:@"BoomerangUpgrade" sizeName:@"BoomerangUpgrade" clipName:@"BoomerangUpgrade"];
    [lootLib setObject:newType forKey:[newType getTypeName]];
    [newType release];
    
    // KillAllBulletPack
    newType = [[UpgradePack alloc] initWithTypeName:@"KillAllBulletUpgrade" sizeName:@"KillAllBulletUpgrade" clipName:@"KillAllBulletUpgrade"];
    [lootLib setObject:newType forKey:[newType getTypeName]];
    [newType release];

    // DarkCloudsPickup
    newType = [[UpgradePack alloc] initWithTypeName:(NSString*)MULTIPLAYERUTIL_ID_DARKCLOUDS sizeName:@"MultiplayerUtilPickup" clipName:@"DarkCloudsPickup"];
    [lootLib setObject:newType forKey:[newType getTypeName]];
    [newType release];

    // FireworksPickup
    newType = [[UpgradePack alloc] initWithTypeName:(NSString*)MULTIPLAYERUTIL_ID_FIREWORKS sizeName:@"MultiplayerUtilPickup" clipName:@"FireworksPickup"];
    [lootLib setObject:newType forKey:[newType getTypeName]];
    [newType release];

    // MutePickup
    newType = [[UpgradePack alloc] initWithTypeName:(NSString*)MULTIPLAYERUTIL_ID_MUTE sizeName:@"MultiplayerUtilPickup" clipName:@"MutePickup"];
    [lootLib setObject:newType forKey:[newType getTypeName]];
    [newType release];

    // random multiplayer pickup
    newType = [[UpgradePack alloc] initWithTypeName:MULTIPLAYERUTIL_ID_RANDOM sizeName:@"MultiplayerUtilPickup" clipName:MULTIPLAYERUTIL_ID_RANDOM];
    [lootLib setObject:newType forKey:[newType getTypeName]];
    [newType release];
}

@end
