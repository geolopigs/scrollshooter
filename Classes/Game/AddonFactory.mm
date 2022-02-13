//
//  AddonFactory.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "AddonFactory.h"
#import "Addon.h"
#import "LevelAnimData.h"
#import "AnimClipData.h"
#import "AnimClip.h"
#import "Sprite.h"
#import "GameObjectSizes.h"

// types
#import "CargoAddon.h"


static NSString* const FLYERSHADOW_TEXT = @"FlyerShadow";
static NSString* const WAKESPEEDO_TEXT = @"WakeSpeedo";
static NSString* const WAKESPEEDO2_TEXT = @"WakeSpeedo2";
static NSString* const WAKESPEEDO3_TEXT = @"WakeSpeedo3";
static NSString* const CARGOPACKADDON_TEXT = @"CargoPackAddon";
static NSString* const CARGOPICKEDUP_TEXT = @"CargoPickedup";
static NSString* const BLIMPBURNING_TEXT = @"BoarBlimpBurning";
static NSString* const TURRETOPEN_TEXT = @"TurretOpen";
static NSString* const TURRETOPENYELLOW_TEXT = @"TurretOpenYellow";
static NSString* const TURRETLASERIDLE_TEXT = @"TurretLaserIdle";
static NSString* const TURRETLASERACTIVE_TEXT = @"TurretLaserActive";
static NSString* const BOARSUBWAKES_TEXT = @"BoarSubmarineWakes";
static NSString* const PROPELLER_TEXT = @"Propeller";
static NSString* const SUBEXPLOSION_TEXT = @"SubExplosion";
static NSString* const SUB2EXPLOSION_TEXT = @"Sub2Explosion";
static NSString* const SKYISLEL7BURN_TEXT = @"SkyIsleL7Burn";
static NSString* const SKYISLEL7DESTROYED_TEXT = @"SkyIsleL7Destroyed";
static NSString* const SKYISLEL10BURN_TEXT = @"SkyIsleL10Burn";
static NSString* const SKYISLEL10DESTROYED_TEXT = @"SkyIsleL10Destroyed";
static NSString* const BOARSUBBURN_TEXT = @"BoarSubBurn";
static NSString* const BOARSUB2BURN_TEXT = @"BoarSub2Burn";

@interface AddonFactory (PrivateMethods)
- (void) populateArchetypeLibFromLevelAnimData:(LevelAnimData*)data;
- (void) addTypeNamed:(NSString*)curName animData:(LevelAnimData*)data;
@end

@implementation AddonFactory
@synthesize archetypeLib;

#pragma mark -
#pragma mark Public Methods

- (id) initWithLevelAnimData:(LevelAnimData*)data 
{
    self = [super init];
    if (self) 
    {
        self.archetypeLib = [NSMutableDictionary dictionary];
        [self populateArchetypeLibFromLevelAnimData:data];
    }
    
    return self;
}

- (void) dealloc
{
    self.archetypeLib = nil;
    [super dealloc];
}

- (Addon*) createAddonNamed:(NSString*)name atPos:(CGPoint)initPos
{
    NSObject<AddonTypeDelegate>* archetype = [archetypeLib objectForKey:name];
    assert(archetype);
    
    Addon* newAddon = [[Addon alloc] initAtPos:initPos withDelegate:archetype];
    [archetype initAddon:newAddon];
    return newAddon;
}

#pragma mark -
#pragma mark Private Methods
- (void) populateArchetypeLibFromLevelAnimData:(LevelAnimData*)data
{
    [self addTypeNamed:FLYERSHADOW_TEXT animData:data];
    [self addTypeNamed:@"PograngShadow" animData:data];
    [self addTypeNamed:@"PogwingShadow" animData:data];
    [self addTypeNamed:WAKESPEEDO_TEXT animData:data];
    [self addTypeNamed:WAKESPEEDO2_TEXT animData:data];
    [self addTypeNamed:WAKESPEEDO3_TEXT animData:data];
    [self addTypeNamed:CARGOPACKADDON_TEXT animData:data];
    [self addTypeNamed:CARGOPICKEDUP_TEXT animData:data];
    [self addTypeNamed:BLIMPBURNING_TEXT animData:data];
    [self addTypeNamed:TURRETOPEN_TEXT animData:data];
    [self addTypeNamed:TURRETOPENYELLOW_TEXT animData:data];
    [self addTypeNamed:TURRETLASERIDLE_TEXT animData:data];
    [self addTypeNamed:TURRETLASERACTIVE_TEXT animData:data];
    [self addTypeNamed:BOARSUBWAKES_TEXT animData:data];
    [self addTypeNamed:PROPELLER_TEXT animData:data];
    [self addTypeNamed:SUBEXPLOSION_TEXT animData:data];
    [self addTypeNamed:SUB2EXPLOSION_TEXT animData:data];
    [self addTypeNamed:SKYISLEL7BURN_TEXT animData:data];
    [self addTypeNamed:SKYISLEL7DESTROYED_TEXT animData:data];
    [self addTypeNamed:SKYISLEL10BURN_TEXT animData:data];
    [self addTypeNamed:SKYISLEL10DESTROYED_TEXT animData:data];
    [self addTypeNamed:BOARSUBBURN_TEXT animData:data];
    [self addTypeNamed:BOARSUB2BURN_TEXT animData:data];
    [self addTypeNamed:@"SoloGun" animData:data];
    [self addTypeNamed:@"MutePlayer" animData:data];
}

- (void) addTypeNamed:(NSString *)curName animData:(LevelAnimData*)data
{
    CGSize curSize = [[GameObjectSizes getInstance] renderSizeFor:curName];
    AnimClipData* curData = [data getClipForName:curName];
    NSObject<AddonTypeDelegate>* newType = [[CargoAddon alloc] initWithClipData:curData renderSize:curSize];
    [archetypeLib setObject:newType forKey:curName];
    [newType release];    
}

@end
