//
//  GameObjectSizes.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "GameObjectSizes.h"
#import "PlayerInventoryIds.h"

@interface GameObjSizeData : NSObject
{
    CGSize renderSize;
    CGSize colSize;
}
@property (nonatomic,assign) CGSize renderSize;
@property (nonatomic,assign) CGSize colSize;
- (id) initWithRenderWidth:(float)renderWidth renderHeight:(float)renderHeight colWidth:(float)colWidth colHeight:(float)colHeight;
+ (id) objectWithRenderWidth:(float)renderWidth renderHeight:(float)renderHeight colWidth:(float)colWidth colHeight:(float)colHeight;
@end

@implementation GameObjSizeData
@synthesize renderSize;
@synthesize colSize;
- (id) initWithRenderWidth:(float)renderWidth renderHeight:(float)renderHeight colWidth:(float)colWidth colHeight:(float)colHeight
{
    self = [super init];
    if(self)
    {
        renderSize = CGSizeMake(renderWidth, renderHeight);
        colSize = CGSizeMake(colWidth, colHeight);
    }
    return self;
}

+ (id) objectWithRenderWidth:(float)renderWidth renderHeight:(float)renderHeight colWidth:(float)colWidth colHeight:(float)colHeight
{
    GameObjSizeData* newSize = [[GameObjSizeData alloc] initWithRenderWidth:renderWidth renderHeight:renderHeight colWidth:colWidth colHeight:colHeight];
    return newSize;
}
@end


@implementation GameObjectSizes
@synthesize sizeReg;
- (id)init
{
    self = [super init];
    if (self) 
    {
        self.sizeReg = [NSMutableDictionary dictionary];

        // Enemy and Player objects
        [self addSizeNamed:@"Pogwing"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.5f
           collisionHeight:6.0f];
        
        [self addSizeNamed:@"Flyer"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.5f
           collisionHeight:6.0f];

        [self addSizeNamed:@"Pograng"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.5f
           collisionHeight:6.0f];
        
        [self addSizeNamed:@"BoarSolo"
               renderWidth:20.0f
              renderHeight:20.0f
            collisionWidth:10.0f
           collisionHeight:10.0f];
        [self addSizeNamed:@"SoloGun"
               renderWidth:20.0f renderHeight:20.0f 
            collisionWidth:10.0f collisionHeight:10.0f];

        [self addSizeNamed:@"TurretSingle"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:10.0f
           collisionHeight:10.0f];
        
        [self addSizeNamed:@"TurretDouble"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:10.0f
           collisionHeight:10.0f];
        
        [self addSizeNamed:@"TurretBasic"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:10.0f
           collisionHeight:10.0f];
        
        [self addSizeNamed:@"TurretLaser"
               renderWidth:16.0f
              renderHeight:16.0f
            collisionWidth:10.0f
           collisionHeight:10.0f];        
        
        [self addSizeNamed:@"CargoBoat"
               renderWidth:61.0f
              renderHeight:61.0f
            collisionWidth:22.0f
           collisionHeight:29.0f];
        
        [self addSizeNamed:@"BoarFighter"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:20.0f
           collisionHeight:20.0f];
        
        [self addSizeNamed:@"DuaSeato"
               renderWidth:30.0f
              renderHeight:30.0f
            collisionWidth:30.0f
           collisionHeight:22.0f];
        
        [self addSizeNamed:@"BoarPumpkinBlimp"
               renderWidth:120.0f
              renderHeight:120.0f
            collisionWidth:60.0f
           collisionHeight:80.0f];
        [self addSizeNamed:@"BoarPumpkinBlimpBurned"
               renderWidth:120.0f
              renderHeight:120.0f
            collisionWidth:40.0f
           collisionHeight:40.0f];

        [self addSizeNamed:@"BoarBlimp"
               renderWidth:90.0f
              renderHeight:90.0f
            collisionWidth:70.0f
           collisionHeight:80.0f];
        
        [self addSizeNamed:@"BoarBlimpBurning"
               renderWidth:120.0f
              renderHeight:120.0f
            collisionWidth:70.0f
           collisionHeight:80.0f];
        
        [self addSizeNamed:@"BoarSpeedo"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:12.0f
           collisionHeight:17.0f];
        
        [self addSizeNamed:@"CargoShipB"
               renderWidth:61.52f
              renderHeight:61.52f
            collisionWidth:30.0f
           collisionHeight:50.0f];

        [self addSizeNamed:@"BoarFighterBasic"
               renderWidth:18.0f
              renderHeight:18.0f
            collisionWidth:17.0f
           collisionHeight:17.0f];
        
        [self addSizeNamed:@"HoverFighter"
               renderWidth:17.0f
              renderHeight:17.0f
            collisionWidth:16.0f
           collisionHeight:16.0f];
        
        [self addSizeNamed:@"MidBlimp"
               renderWidth:70.0f
              renderHeight:70.0f
            collisionWidth:30.0f
           collisionHeight:40.0f];
        
        [self addSizeNamed:@"MidBlimpBoar"
               renderWidth:70.0f
              renderHeight:70.0f
            collisionWidth:40.0f
           collisionHeight:60.0f];
        
        [self addSizeNamed:@"MidTurretBlimp"
               renderWidth:70.0f
              renderHeight:70.0f
            collisionWidth:35.0f
           collisionHeight:60.0f];

        [self addSizeNamed:@"LargeBlimpLeft"
               renderWidth:140.0f
              renderHeight:140.0f
            collisionWidth:60.0f
           collisionHeight:60.0f];
    
        [self addSizeNamed:@"LargeBlimpRight"
               renderWidth:140.0f
              renderHeight:140.0f
            collisionWidth:60.0f
           collisionHeight:60.0f];

        [self addSizeNamed:@"LargeBlimpTurretLeft"
               renderWidth:140.0f
              renderHeight:140.0f
            collisionWidth:60.0f
           collisionHeight:60.0f];

        [self addSizeNamed:@"LargeBlimpTurretRight"
               renderWidth:140.0f
              renderHeight:140.0f
            collisionWidth:60.0f
           collisionHeight:60.0f];

        [self addSizeNamed:@"LargeBlimpTurrets"
               renderWidth:150.0f
              renderHeight:150.0f
            collisionWidth:150.0f
           collisionHeight:30.0f];
        
        [self addSizeNamed:@"LargeBlimp"
               renderWidth:140.0f
              renderHeight:140.0f
            collisionWidth:60.0f
           collisionHeight:60.0f];
        
        [self addSizeNamed:@"LandingPad"
               renderWidth:125.0f
              renderHeight:80.0f
            collisionWidth:42.0f
           collisionHeight:60.0f];

        [self addSizeNamed:@"FloatingIsland"
               renderWidth:100.0f
              renderHeight:100.0f
            collisionWidth:42.0f
           collisionHeight:60.0f];

        [self addSizeNamed:@"SkyIsleL7"
               renderWidth:85.0f
              renderHeight:85.0f
            collisionWidth:25.0f
           collisionHeight:20.0f];

        [self addSizeNamed:@"SkyIsleL10"
               renderWidth:85.0f
              renderHeight:85.0f
            collisionWidth:25.0f
           collisionHeight:20.0f];

        [self addSizeNamed:@"SkyIsleL7Burn"
               renderWidth:85.0f
              renderHeight:85.0f
            collisionWidth:25.0f
           collisionHeight:20.0f];
        
        [self addSizeNamed:@"SkyIsleL7Destroyed"
               renderWidth:85.0f
              renderHeight:85.0f
            collisionWidth:25.0f
           collisionHeight:20.0f];

        [self addSizeNamed:@"SkyIsleL10Burn"
               renderWidth:85.0f
              renderHeight:85.0f
            collisionWidth:25.0f
           collisionHeight:20.0f];
        
        [self addSizeNamed:@"SkyIsleL10Destroyed"
               renderWidth:85.0f
              renderHeight:85.0f
            collisionWidth:25.0f
           collisionHeight:20.0f];

        [self addSizeNamed:@"BoarSubmarine"
               renderWidth:120.0f
              renderHeight:120.0f
            collisionWidth:30.0f
           collisionHeight:40.0f];        
        [self addSizeNamed:@"BoarSubmarineWakes"
               renderWidth:120.0f
              renderHeight:120.0f
            collisionWidth:30.0f
           collisionHeight:40.0f];

        [self addSizeNamed:@"BoarSubBurn"
               renderWidth:120.0f
              renderHeight:120.0f
            collisionWidth:30.0f
           collisionHeight:40.0f];        
        
        [self addSizeNamed:@"SubExplosion"
               renderWidth:120.0f
              renderHeight:120.0f
            collisionWidth:30.0f
           collisionHeight:40.0f];        

        [self addSizeNamed:@"BoarSubmarine2"
               renderWidth:100.0f
              renderHeight:100.0f
            collisionWidth:40.0f
           collisionHeight:30.0f];        

        [self addSizeNamed:@"BoarSub2Burn"
               renderWidth:100.0f
              renderHeight:100.0f
            collisionWidth:40.0f
           collisionHeight:30.0f];        

        [self addSizeNamed:@"Sub2Explosion"
               renderWidth:100.0f
              renderHeight:100.0f
            collisionWidth:30.0f
           collisionHeight:40.0f];        

        // Bullets
        [self addSizeNamed:@"SpinTriBullet"
               renderWidth:4.0f
              renderHeight:4.0f
            collisionWidth:1.5f
           collisionHeight:1.5f];
        
        [self addSizeNamed:@"AutoFireShot"
               renderWidth:6.0f
              renderHeight:6.0f
            collisionWidth:3.0f
           collisionHeight:5.5f];

        [self addSizeNamed:@"Boomerang"
               renderWidth:6.0f
              renderHeight:6.0f
            collisionWidth:3.0f
           collisionHeight:5.5f];
        
        [self addSizeNamed:@"PlayerMissile"
               renderWidth:6.0f
              renderHeight:6.0f
            collisionWidth:3.0f
           collisionHeight:5.5f];

        [self addSizeNamed:@"BlueMissile"
               renderWidth:6.0f
              renderHeight:6.0f
            collisionWidth:3.0f
           collisionHeight:5.5f];
        
        [self addSizeNamed:@"MissileTrail"
               renderWidth:6.0f
              renderHeight:6.0f
            collisionWidth:3.0f
           collisionHeight:5.5f];
        
        [self addSizeNamed:@"BlueTrail"
               renderWidth:6.0f
              renderHeight:6.0f
            collisionWidth:3.0f
           collisionHeight:5.5f];

        [self addSizeNamed:@"BoomerangTrail"
               renderWidth:6.0f
              renderHeight:6.0f
            collisionWidth:3.0f
           collisionHeight:5.5f];
        
        [self addSizeNamed:@"ScatterBomb"
               renderWidth:10.0f
              renderHeight:10.0f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"WaterMine"
               renderWidth:10.0f
              renderHeight:10.0f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"TurretBullet"
               renderWidth:4.0f
              renderHeight:4.0f
            collisionWidth:1.5f
           collisionHeight:1.5f];

        [self addSizeNamed:@"YellowLaser"
               renderWidth:20.0f
              renderHeight:200.0f
            collisionWidth:5.0f
           collisionHeight:200.0f];

        [self addSizeNamed:@"YellowLaserInit"
               renderWidth:20.0f
              renderHeight:200.0f
            collisionWidth:5.0f
           collisionHeight:200.0f];
        
        [self addSizeNamed:@"YellowLaserGone"
               renderWidth:20.0f
              renderHeight:200.0f
            collisionWidth:5.0f
           collisionHeight:200.0f];

        
        [self addSizeNamed:@"BlueLaser"
               renderWidth:10.0f
              renderHeight:200.0f
            collisionWidth:2.0f
           collisionHeight:200.0f];
        
        [self addSizeNamed:@"BlueLaserInit"
               renderWidth:10.0f
              renderHeight:200.0f
            collisionWidth:2.0f
           collisionHeight:200.0f];
        
        [self addSizeNamed:@"BlueLaserGone"
               renderWidth:10.0f
              renderHeight:200.0f
            collisionWidth:2.0f
           collisionHeight:200.0f];

        // Effects
        [self addSizeNamed:@"BoarSoloDown"
               renderWidth:26.367f
              renderHeight:45.0f
            collisionWidth:26.367f
           collisionHeight:45.0f];
        
        [self addSizeNamed:@"BoarFighterDown"
               renderWidth:18.0f
              renderHeight:18.0f
            collisionWidth:18.0f
           collisionHeight:18.0f];
        
        [self addSizeNamed:@"BulletHit"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:11.0f
           collisionHeight:11.0f];

        [self addSizeNamed:@"Explosion"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:22.0f
           collisionHeight:22.0f];
        
        [self addSizeNamed:@"Explosion2"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:22.0f
           collisionHeight:22.0f];
        
        [self addSizeNamed:@"MissileHit"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:22.0f
           collisionHeight:22.0f];

        [self addSizeNamed:@"FlyerHitExplosion"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:11.0f
           collisionHeight:11.0f];
        
        [self addSizeNamed:@"SpawnGeneric"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:11.0f
           collisionHeight:11.0f];
        
        [self addSizeNamed:@"BlimpBurned"
               renderWidth:90.0f
              renderHeight:90.0f
            collisionWidth:70.0f
           collisionHeight:80.0f];
        
        [self addSizeNamed:@"MidBlimpBurned"
               renderWidth:70.0f
              renderHeight:70.0f
            collisionWidth:35.0f
           collisionHeight:60.0f];
        
        [self addSizeNamed:@"LargeBlimpBurned"
               renderWidth:140.0f
              renderHeight:140.0f
            collisionWidth:60.0f
           collisionHeight:60.0f];
        
        [self addSizeNamed:@"SpinTriBulletGone"
               renderWidth:4.0f
              renderHeight:4.0f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"TurretBulletGone"
               renderWidth:4.0f
              renderHeight:4.0f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"KillBullets"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.0f
           collisionHeight:3.0f];

        [self addSizeNamed:@"DarkCloudsSent"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"DarkCloudsReceived"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"FireworksSent"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"FireworksReceived"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"MuteSent"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.0f
           collisionHeight:3.0f];
        
        [self addSizeNamed:@"MuteReceived"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.0f
           collisionHeight:3.0f];

        [self addSizeNamed:@"MutePlayer"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.5f
           collisionHeight:6.0f];
        
        [self addSizeNamed:@"CargoPickedup"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:3.5f
           collisionHeight:6.0f];

        [self addSizeNamed:@"BoarSubmarine2Spawn"
               renderWidth:150.0f
              renderHeight:150.0f
            collisionWidth:70.0f
           collisionHeight:70.0f];

        // Pick-ups
        [self addSizeNamed:@"Cargo1"
               renderWidth:5.45f
              renderHeight:5.625
            collisionWidth:5.6f
           collisionHeight:5.6f];
        
        [self addSizeNamed:@"Cargo2"
               renderWidth:5.273f
              renderHeight:5.625f
            collisionWidth:5.6f
           collisionHeight:5.6f];
        
        [self addSizeNamed:@"HealthPack"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:11.0f
           collisionHeight:10.0f];
        
        [self addSizeNamed:@"CargoPack"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:10.0f
           collisionHeight:10.0f];
        
        [self addSizeNamed:@"DoubleBulletUpgrade"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:10.0f
           collisionHeight:10.0f];

        [self addSizeNamed:@"LaserUpgrade"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:10.0f
           collisionHeight:10.0f];

        [self addSizeNamed:@"BoomerangUpgrade"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:10.0f
           collisionHeight:10.0f];

        [self addSizeNamed:@"KillAllBulletUpgrade"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:10.0f
           collisionHeight:10.0f];

        [self addSizeNamed:@"MultiplayerUtilPickup"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:10.0f
           collisionHeight:10.0f];
        
        // Add-ons
        [self addSizeNamed:@"CargoAddon"
               renderWidth:11.25f
              renderHeight:11.25f
            collisionWidth:11.25f
           collisionHeight:11.25f];
        
        [self addSizeNamed:@"FlyerShadow"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:22.5f
           collisionHeight:22.5f];
        
        [self addSizeNamed:@"PograngShadow"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:22.5f
           collisionHeight:22.5f];
        
        [self addSizeNamed:@"PogwingShadow"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:22.5f
           collisionHeight:22.5f];
        
        [self addSizeNamed:@"WakeSpeedo"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:16.0f
           collisionHeight:5.0f];
        
        [self addSizeNamed:@"WakeSpeedo2"
               renderWidth:22.5f
              renderHeight:22.5f
            collisionWidth:16.0f
           collisionHeight:5.0f];
        
        [self addSizeNamed:@"WakeSpeedo3"
               renderWidth:45.0f
              renderHeight:45.0f
            collisionWidth:16.0f
           collisionHeight:5.0f];
        
        // CargoPacks that sit on ships
        [self addSizeNamed:@"CargoPackAddon"
               renderWidth:9.25f
              renderHeight:9.25f
            collisionWidth:1.0f
           collisionHeight:1.0f];

        [self addSizeNamed:@"TurretOpen"
               renderWidth:17.5f
              renderHeight:17.5f
            collisionWidth:1.0f
           collisionHeight:1.0f];        

        [self addSizeNamed:@"TurretOpenYellow"
               renderWidth:17.5f
              renderHeight:17.5f
            collisionWidth:1.0f
           collisionHeight:1.0f];   
        
        [self addSizeNamed:@"Propeller"
               renderWidth:17.5f
              renderHeight:17.5f
            collisionWidth:1.0f
           collisionHeight:1.0f];           

        [self addSizeNamed:@"TurretLaserIdle"
               renderWidth:20.0f
              renderHeight:20.0f
            collisionWidth:1.0f
           collisionHeight:1.0f];        
        [self addSizeNamed:@"TurretLaserActive"
               renderWidth:20.0f
              renderHeight:20.0f
            collisionWidth:1.0f
           collisionHeight:1.0f];        
    }
    
    return self;
}

- (void) dealloc
{
    self.sizeReg = nil;
    [super dealloc];
}

- (CGSize) renderSizeFor:(NSString *)name
{
    CGSize result = CGSizeMake(22.5f, 22.5f);
    GameObjSizeData* regSize = [sizeReg objectForKey:name];
    assert(regSize);
    if(regSize)
    {
        result = [regSize renderSize];
    }
    return result;
}

- (CGSize) colSizeFor:(NSString *)name
{
    CGSize result = CGSizeMake(22.5f, 22.5f);
    GameObjSizeData* regSize = [sizeReg objectForKey:name];
    assert(regSize);
    if(regSize)
    {
        result = [regSize colSize];
    }
    return result;    
}

- (void) addSizeNamed:(NSString *)name 
          renderWidth:(float)renderWidth 
         renderHeight:(float)renderHeight 
       collisionWidth:(float)collisionWidth 
      collisionHeight:(float)collisionHeight
{
    GameObjSizeData* newSize = [GameObjSizeData objectWithRenderWidth:renderWidth renderHeight:renderHeight colWidth:collisionWidth colHeight:collisionHeight];
    [sizeReg setObject:newSize forKey:name];
    [newSize release];
}
                   
                   
#pragma mark -
#pragma mark Singleton
static GameObjectSizes* singletonInstance = nil;
+ (GameObjectSizes*) getInstance
{
	@synchronized(self)
	{
		if (!singletonInstance)
		{
			singletonInstance = [[[GameObjectSizes alloc] init] retain];
		}
	}
	return singletonInstance;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singletonInstance release];
		singletonInstance = nil;
	}
}

@end
