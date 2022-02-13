//
//  FlyerPogwing.mm
//

#import "FlyerPogwing.h"
#import "Sprite.h"
#import "Player.h"
#import "AnimClipData.h"
#import "AnimLinearController.h"
#import "AnimClip.h"
#import "LevelManager.h"
#import "Level.h"
#import "LevelAnimData.h"
#import "FlyerWeapon.h"
#import "FiringPath.h"
#import "BossWeapon.h"
#import "FlyerWeapon.h"
#import "FlyerLaser.h"
#import "GameObjectSizes.h"

static const float COL_ORIGIN_X = -0.5f;
static const float COL_ORIGIN_Y = -0.25f;

// AutoFireShot
static const unsigned int NUM_WEAPONLEVELS = 6;
static const float PLAYER_AUTOFIRESHOT_SPEED = 100.0f;
static const float PLAYER_TRIPLEFIRE_ANGLE = M_PI * 0.05f;
static const float CENTER_LOCAL_X = 0.0f;
static const float CENTER_LOCAL_Y = 4.0f;
static const float LEFT_LOCAL_X = -4.0f;
static const float LEFT_LOCAL_Y = 2.0f;
static const float RIGHT_LOCAL_X = 4.0f;
static const float RIGHT_LOCAL_Y = 2.0f;

@interface FlyerPogwing (PrivateMethods)
- (void) initWeapon:(Player*)givenPlayer;
- (NSMutableDictionary*) configLaserL0;
- (NSMutableDictionary*) configLaserL1Left;
- (NSMutableDictionary*) configLaserL1Right;
- (NSMutableDictionary*) configLaserL2Center;
- (NSMutableDictionary*) configLaserL2Left;
- (NSMutableDictionary*) configLaserL2Right;
- (NSMutableDictionary*) configLaserL5Center;
- (NSMutableDictionary*) missileConfig;
@end

@implementation FlyerPogwing

- (id) init
{
    self = [super init];
    if(self)
	{
		
	}
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (NSMutableDictionary*) configLaserL0
{
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    [config setObject:@"laser" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithFloat:0.5f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"startupDelay"];
    NSMutableDictionary* laserSpec = [NSMutableDictionary dictionary];
    
    // init laser to point up (laser dir 0.0f is down)
    [laserSpec setObject:[NSNumber numberWithFloat:1.0f] forKey:@"initDir"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.4f] forKey:@"initDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"onDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"offDur"];
    [laserSpec setObject:@"BlueLaser" forKey:@"animName"];
    [laserSpec setObject:@"BlueLaserInit" forKey:@"initAnimName"];
    [laserSpec setObject:@"BlueLaserGone" forKey:@"offAnimName"];
    [config setObject:laserSpec forKey:@"laserSpec"];
    return config;
}

- (NSMutableDictionary*) configLaserL1Left
{
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    [config setObject:@"laser" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"startupDelay"];
    NSMutableDictionary* laserSpec = [NSMutableDictionary dictionary];
    
    // init laser to point up (laser dir 0.0f is down)
    [laserSpec setObject:[NSNumber numberWithFloat:1.0f] forKey:@"initDir"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.8f] forKey:@"initDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"onDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"offDur"];
    [laserSpec setObject:@"BlueLaser" forKey:@"animName"];
    [laserSpec setObject:@"BlueLaserInit" forKey:@"initAnimName"];
    [laserSpec setObject:@"BlueLaserGone" forKey:@"offAnimName"];
    [config setObject:laserSpec forKey:@"laserSpec"];
    return config;
}

- (NSMutableDictionary*) configLaserL1Right
{
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    [config setObject:@"laser" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.4f] forKey:@"startupDelay"];
    NSMutableDictionary* laserSpec = [NSMutableDictionary dictionary];
    
    // init laser to point up (laser dir 0.0f is down)
    [laserSpec setObject:[NSNumber numberWithFloat:1.0f] forKey:@"initDir"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.8f] forKey:@"initDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"onDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"offDur"];
    [laserSpec setObject:@"BlueLaser" forKey:@"animName"];
    [laserSpec setObject:@"BlueLaserInit" forKey:@"initAnimName"];
    [laserSpec setObject:@"BlueLaserGone" forKey:@"offAnimName"];
    [config setObject:laserSpec forKey:@"laserSpec"];
    return config;
}

- (NSMutableDictionary*) configLaserL2Center
{
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    [config setObject:@"laser" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"startupDelay"];
    NSMutableDictionary* laserSpec = [NSMutableDictionary dictionary];
    
    // init laser to point up (laser dir 0.0f is down)
    [laserSpec setObject:[NSNumber numberWithFloat:1.0f] forKey:@"initDir"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.3f] forKey:@"initDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.3f] forKey:@"onDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"offDur"];
    [laserSpec setObject:@"BlueLaser" forKey:@"animName"];
    [laserSpec setObject:@"BlueLaserInit" forKey:@"initAnimName"];
    [laserSpec setObject:@"BlueLaserGone" forKey:@"offAnimName"];
    [config setObject:laserSpec forKey:@"laserSpec"];
    return config;
}

- (NSMutableDictionary*) configLaserL2Left
{
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    [config setObject:@"laser" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.4f] forKey:@"startupDelay"];
    NSMutableDictionary* laserSpec = [NSMutableDictionary dictionary];
    
    // init laser to point up (laser dir 0.0f is down)
    [laserSpec setObject:[NSNumber numberWithFloat:1.0f] forKey:@"initDir"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.4f] forKey:@"initDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"onDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"offDur"];
    [laserSpec setObject:@"BlueLaser" forKey:@"animName"];
    [laserSpec setObject:@"BlueLaserInit" forKey:@"initAnimName"];
    [laserSpec setObject:@"BlueLaserGone" forKey:@"offAnimName"];
    [config setObject:laserSpec forKey:@"laserSpec"];
    return config;
}

- (NSMutableDictionary*) configLaserL2Right
{
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    [config setObject:@"laser" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.4f] forKey:@"startupDelay"];
    NSMutableDictionary* laserSpec = [NSMutableDictionary dictionary];
    
    // init laser to point up (laser dir 0.0f is down)
    [laserSpec setObject:[NSNumber numberWithFloat:1.0f] forKey:@"initDir"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.4f] forKey:@"initDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"onDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"offDur"];
    [laserSpec setObject:@"BlueLaser" forKey:@"animName"];
    [laserSpec setObject:@"BlueLaserInit" forKey:@"initAnimName"];
    [laserSpec setObject:@"BlueLaserGone" forKey:@"offAnimName"];
    [config setObject:laserSpec forKey:@"laserSpec"];
    return config;
}

- (NSMutableDictionary*) configLaserL5Center
{
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    [config setObject:@"laser" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"startupDelay"];
    NSMutableDictionary* laserSpec = [NSMutableDictionary dictionary];
    
    // init laser to point up (laser dir 0.0f is down)
    [laserSpec setObject:[NSNumber numberWithFloat:1.0f] forKey:@"initDir"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.4f] forKey:@"initDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.8f] forKey:@"onDur"];
    [laserSpec setObject:[NSNumber numberWithFloat:0.2f] forKey:@"offDur"];
    [laserSpec setObject:@"BlueLaser" forKey:@"animName"];
    [laserSpec setObject:@"BlueLaserInit" forKey:@"initAnimName"];
    [laserSpec setObject:@"BlueLaserGone" forKey:@"offAnimName"];
    [laserSpec setObject:[NSNumber numberWithFloat:4.0f] forKey:@"objScaleX"];
    [config setObject:laserSpec forKey:@"laserSpec"];
    return config;
}

- (NSMutableDictionary*) missileConfig
{
    NSMutableDictionary* config = [NSMutableDictionary dictionary];
    [config setObject:@"straight" forKey:@"subType"];
    [config setObject:[NSNumber numberWithFloat:0.0f] forKey:@"initDelay"];
    [config setObject:[NSNumber numberWithFloat:0.2f] forKey:@"launchDelay"];
    return config;
}

- (void) initWeapon:(Player *)givenPlayer
{
    // init config slots for weapon levels
    FlyerWeapon* newWeapon = [[FlyerWeapon alloc] init];
    for(unsigned int i = 0; i < NUM_WEAPONLEVELS; ++i)
    {
        [newWeapon.primaryConfig addObject:[NSNull null]];
        [newWeapon.secondaryConfig addObject:[NSNull null]];
    }
    
    // init weapon pools
    NSMutableDictionary* laserL0Config = [self configLaserL0];
    BossWeapon* laserL0 = [[BossWeapon alloc] initFromConfig:laserL0Config];
    laserL0.localPos = CGPointMake(CENTER_LOCAL_X, CENTER_LOCAL_Y);
    [newWeapon.primaryPool addObject:laserL0];

    BossWeapon* laserL1Left = [[BossWeapon alloc] initFromConfig:[self configLaserL1Left]];
    laserL1Left.localPos = CGPointMake(LEFT_LOCAL_X, LEFT_LOCAL_Y);
    [newWeapon.primaryPool addObject:laserL1Left];
    
    BossWeapon* laserL1Right = [[BossWeapon alloc] initFromConfig:[self configLaserL1Right]];
    laserL1Right.localPos = CGPointMake(RIGHT_LOCAL_X, RIGHT_LOCAL_Y);
    [newWeapon.primaryPool addObject:laserL1Right];

    BossWeapon* laserL2Center = [[BossWeapon alloc] initFromConfig:[self configLaserL2Center]];
    laserL2Center.localPos = CGPointMake(CENTER_LOCAL_X, CENTER_LOCAL_Y);
    [newWeapon.primaryPool addObject:laserL2Center];
    
    BossWeapon* laserL2Left = [[BossWeapon alloc] initFromConfig:[self configLaserL2Left]];
    laserL2Left.localPos = CGPointMake(LEFT_LOCAL_X, LEFT_LOCAL_Y);
    [newWeapon.primaryPool addObject:laserL2Left];
    
    BossWeapon* laserL2Right = [[BossWeapon alloc] initFromConfig:[self configLaserL2Right]];
    laserL2Right.localPos = CGPointMake(RIGHT_LOCAL_X, RIGHT_LOCAL_Y);
    [newWeapon.primaryPool addObject:laserL2Right];

    BossWeapon* laserL5Center = [[BossWeapon alloc] initFromConfig:[self configLaserL5Center]];
    laserL5Center.localPos = CGPointMake(CENTER_LOCAL_X, CENTER_LOCAL_Y);
    [newWeapon.primaryPool addObject:laserL5Center];

    // level0
    NSArray* primaryL0 = [NSArray arrayWithObject:laserL0];
    [newWeapon.primaryConfig replaceObjectAtIndex:0 withObject:primaryL0];
        
    // level 1
    NSArray* primaryL1 = [NSArray arrayWithObjects:laserL1Left, laserL1Right, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:1 withObject:primaryL1];
    
    // level 2
    NSArray* primaryL2 = [NSArray arrayWithObjects:laserL2Center, laserL2Left, laserL2Right, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:2 withObject:primaryL2];
    
    // Level3
    NSMutableDictionary* missileConfigL3 = [NSMutableDictionary dictionaryWithObject:@"homingMissile" forKey:@"weaponType"];
    [missileConfigL3 setObject:[NSNumber numberWithUnsignedInt:2] forKey:@"numPerRound"];
    [missileConfigL3 setObject:[NSNumber numberWithFloat:-0.25f] forKey:@"missileAngleBegin"];
    [missileConfigL3 setObject:[NSNumber numberWithFloat:0.5f] forKey:@"missileAngleSpan"];
    [missileConfigL3 setObject:[self missileConfig] forKey:@"missileSpec"];
    BossWeapon* missileL3 = [[BossWeapon alloc] initFromConfig:missileConfigL3];
    [newWeapon.primaryConfig replaceObjectAtIndex:3 withObject:primaryL2];
    [newWeapon.secondaryConfig replaceObjectAtIndex:3 withObject:missileL3];
    [newWeapon.secondaryPool addObject:missileL3];
    
    // Level4
    NSMutableDictionary* missileConfigL4 = [NSMutableDictionary dictionaryWithObject:@"homingMissile" forKey:@"weaponType"];
    [missileConfigL4 setObject:[NSNumber numberWithUnsignedInt:4] forKey:@"numPerRound"];
    [missileConfigL3 setObject:[NSNumber numberWithFloat:-0.45f] forKey:@"missileAngleBegin"];
    [missileConfigL3 setObject:[NSNumber numberWithFloat:0.9f] forKey:@"missileAngleSpan"];
    [missileConfigL4 setObject:[self missileConfig] forKey:@"missileSpec"];
    BossWeapon* missileL4 = [[BossWeapon alloc] initFromConfig:missileConfigL4];
    [newWeapon.primaryConfig replaceObjectAtIndex:4 withObject:primaryL2];
    [newWeapon.secondaryConfig replaceObjectAtIndex:4 withObject:missileL4];
    [newWeapon.secondaryPool addObject:missileL4];
    
    // Level5
    NSArray* primaryL5 = [NSArray arrayWithObjects:laserL5Center, laserL2Left, laserL2Right, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:5 withObject:primaryL5];
    [newWeapon.secondaryConfig replaceObjectAtIndex:5 withObject:missileL4];
    
    // set weapon delegate
    FlyerLaser* weaponDelegate = [[FlyerLaser alloc] init];
    newWeapon.delegate = weaponDelegate;
    [weaponDelegate release];
    
    givenPlayer.weapon = newWeapon;
    [newWeapon release];
    
    [laserL0 release];
    [laserL1Left release];
    [laserL1Right release];
    [laserL2Center release];
    [laserL2Left release];
    [laserL2Right release];
    [missileL3 release];
    [missileL4 release];
    [laserL5Center release];
}

#pragma mark - PlayerInitProtocol
- (void) initPlayer:(Player*)givenPlayer
{
    givenPlayer.flyerType = FlyerTypePogwing;
    
    NSString* objectTypename = @"Pogwing";
	CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:objectTypename];
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:objectTypename];

    givenPlayer.colAABB = CGRectMake(COL_ORIGIN_X * colSize.width, COL_ORIGIN_Y * colSize.height, colSize.width, colSize.height);

	Sprite* myRenderer = [[Sprite alloc] initWithSize:mySize colRect:[givenPlayer colAABB]];
	givenPlayer.renderer = myRenderer;
	[myRenderer release];

    LevelAnimData* levelAnimData = [[[LevelManager getInstance] curLevel] animData];
    AnimClipData* data = [levelAnimData getClipForName:objectTypename];
    
    AnimLinearController* newController = [[AnimLinearController alloc] initFromAnimClipData:data];
    givenPlayer.anim = [NSArray arrayWithObjects: newController, nil];
    
    givenPlayer.animController = newController;
    [newController release];
    
    givenPlayer.shadowName = @"PogwingShadow";
    givenPlayer.pickupTypename = @"LaserUpgrade";

    // init weapon system
    [self initWeapon:givenPlayer];
}

@end
