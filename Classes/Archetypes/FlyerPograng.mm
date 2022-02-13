//
//  FlyerPograng.mm
//

#import "FlyerPograng.h"
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
#import "FlyerBoomerang.h"
#import "GameObjectSizes.h"

static const float COL_ORIGIN_X = -0.5f;
static const float COL_ORIGIN_Y = -0.25f;

// AutoFireShot
static const unsigned int NUM_WEAPONLEVELS = 6;
static const float CENTER_LOCAL_X = 0.0f;
static const float CENTER_LOCAL_Y = 4.0f;
static const float LEFT0_LOCAL_X = -3.0f;
static const float LEFT0_LOCAL_Y = 1.0f;
static const float RIGHT0_LOCAL_X = 3.0f;
static const float RIGHT0_LOCAL_Y = 1.0f;
static const float LEFT1_LOCAL_X = -7.0f;
static const float LEFT1_LOCAL_Y = 1.0f;
static const float RIGHT1_LOCAL_X = 7.0f;
static const float RIGHT1_LOCAL_Y = 1.0f;

@interface FlyerPograng (PrivateMethods)
- (void) initWeapon:(Player*)givenPlayer;
- (NSMutableDictionary*) configBoomerangShort;
- (NSMutableDictionary*) configBoomerangLong;
- (NSMutableDictionary*) configBoomerangDiag;
- (NSMutableDictionary*) configBoomerangDiagBack;
- (NSMutableDictionary*) configBoomerangShortHiFreq;
- (NSMutableDictionary*) configBoomerangLongHiFreq;
@end

@implementation FlyerPograng

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

- (NSMutableDictionary*) configBoomerangShort
{
    NSMutableDictionary* config = [NSMutableDictionary dictionaryWithObject:@"boomerang" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithUnsignedInt:1] forKey:@"numPerRound"];
    [config setObject:[NSNumber numberWithFloat:0.8f] forKey:@"shotDelay"];

    NSMutableDictionary* spec = [NSMutableDictionary dictionary];
    [spec setObject:[NSNumber numberWithFloat:40.0f] forKey:@"radius"];
    [config setObject:spec forKey:@"boomerangSpec"];
    
    return config;    
}

- (NSMutableDictionary*) configBoomerangLong
{
    NSMutableDictionary* config = [NSMutableDictionary dictionaryWithObject:@"boomerang" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithUnsignedInt:1] forKey:@"numPerRound"];
    [config setObject:[NSNumber numberWithFloat:1.0f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.4f] forKey:@"startupDelay"];

    NSMutableDictionary* spec = [NSMutableDictionary dictionary];
    [spec setObject:[NSNumber numberWithFloat:60.0f] forKey:@"radius"];
    [config setObject:spec forKey:@"boomerangSpec"];
    
    return config;    
}

- (NSMutableDictionary*) configBoomerangDiag
{
    NSMutableDictionary* config = [NSMutableDictionary dictionaryWithObject:@"boomerang" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithUnsignedInt:2] forKey:@"numPerRound"];
    [config setObject:[NSNumber numberWithFloat:0.8f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:-0.15f] forKey:@"boomerangAngleBegin"];
    [config setObject:[NSNumber numberWithFloat:0.3f] forKey:@"boomerangAngleSpan"];
    
    NSMutableDictionary* spec = [NSMutableDictionary dictionary];
    [spec setObject:[NSNumber numberWithFloat:30.0f] forKey:@"radius"];
    [config setObject:spec forKey:@"boomerangSpec"];
    
    return config;    
}

- (NSMutableDictionary*) configBoomerangDiagBack
{
    NSMutableDictionary* config = [NSMutableDictionary dictionaryWithObject:@"boomerang" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithUnsignedInt:2] forKey:@"numPerRound"];
    [config setObject:[NSNumber numberWithFloat:1.2f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.85f] forKey:@"boomerangAngleBegin"];
    [config setObject:[NSNumber numberWithFloat:0.3f] forKey:@"boomerangAngleSpan"];
    
    NSMutableDictionary* spec = [NSMutableDictionary dictionary];
    [spec setObject:[NSNumber numberWithFloat:30.0f] forKey:@"radius"];
    [config setObject:spec forKey:@"boomerangSpec"];
    
    return config;    
}

- (NSMutableDictionary*) configBoomerangShortHiFreq
{
    NSMutableDictionary* config = [NSMutableDictionary dictionaryWithObject:@"boomerang" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithUnsignedInt:1] forKey:@"numPerRound"];
    [config setObject:[NSNumber numberWithFloat:0.6f] forKey:@"shotDelay"];
    
    NSMutableDictionary* spec = [NSMutableDictionary dictionary];
    [spec setObject:[NSNumber numberWithFloat:40.0f] forKey:@"radius"];
    [config setObject:spec forKey:@"boomerangSpec"];
    
    return config;    
}

- (NSMutableDictionary*) configBoomerangLongHiFreq
{
    NSMutableDictionary* config = [NSMutableDictionary dictionaryWithObject:@"boomerang" forKey:@"weaponType"];
    [config setObject:[NSNumber numberWithUnsignedInt:1] forKey:@"numPerRound"];
    [config setObject:[NSNumber numberWithFloat:0.4f] forKey:@"shotDelay"];
    [config setObject:[NSNumber numberWithFloat:0.4f] forKey:@"startupDelay"];

    NSMutableDictionary* spec = [NSMutableDictionary dictionary];
    [spec setObject:[NSNumber numberWithFloat:65.0f] forKey:@"radius"];
    [config setObject:spec forKey:@"boomerangSpec"];
    
    return config;    
}


- (void) initWeapon:(Player *)givenPlayer
{    
    // init primary config
    FlyerWeapon* newWeapon = [[FlyerWeapon alloc] init];
    for(unsigned int i = 0; i < NUM_WEAPONLEVELS; ++i)
    {
        [newWeapon.primaryConfig addObject:[NSNull null]];
        [newWeapon.secondaryConfig addObject:[NSNull null]];
    }
    
    // init primary weapon pools
    BossWeapon* priL0Left = [[BossWeapon alloc] initFromConfig:[self configBoomerangShort]];
    priL0Left.localPos = CGPointMake(LEFT0_LOCAL_X, LEFT0_LOCAL_Y);
    [newWeapon.primaryPool addObject:priL0Left];

    BossWeapon* priL0Right = [[BossWeapon alloc] initFromConfig:[self configBoomerangShort]];
    priL0Right.localPos = CGPointMake(RIGHT0_LOCAL_X, RIGHT0_LOCAL_Y);
    [newWeapon.primaryPool addObject:priL0Right];

    BossWeapon* priL1Left = [[BossWeapon alloc] initFromConfig:[self configBoomerangShort]];
    priL1Left.localPos = CGPointMake(LEFT1_LOCAL_X, LEFT1_LOCAL_Y);
    [newWeapon.primaryPool addObject:priL1Left];
    
    BossWeapon* priL1Right = [[BossWeapon alloc] initFromConfig:[self configBoomerangShort]];
    priL1Right.localPos = CGPointMake(RIGHT1_LOCAL_X, RIGHT1_LOCAL_Y);
    [newWeapon.primaryPool addObject:priL1Right];

    BossWeapon* priL1LongLeft = [[BossWeapon alloc] initFromConfig:[self configBoomerangLong]];
    priL1LongLeft.localPos = CGPointMake(LEFT0_LOCAL_X, LEFT0_LOCAL_Y);
    [newWeapon.primaryPool addObject:priL1LongLeft];
    
    BossWeapon* priL1LongRight = [[BossWeapon alloc] initFromConfig:[self configBoomerangLong]];
    priL1LongRight.localPos = CGPointMake(RIGHT0_LOCAL_X, RIGHT0_LOCAL_Y);
    [newWeapon.primaryPool addObject:priL1LongRight];
    
    BossWeapon* priDiag = [[BossWeapon alloc] initFromConfig:[self configBoomerangDiag]];
    priDiag.localPos = CGPointMake(CENTER_LOCAL_X, CENTER_LOCAL_Y);
    [newWeapon.primaryPool addObject:priDiag];
    
    BossWeapon* priDiagBack = [[BossWeapon alloc] initFromConfig:[self configBoomerangDiagBack]];
    priDiagBack.localPos = CGPointMake(CENTER_LOCAL_X, CENTER_LOCAL_Y);
    [newWeapon.primaryPool addObject:priDiagBack];
    
    BossWeapon* priHiLongLeft = [[BossWeapon alloc] initFromConfig:[self configBoomerangLongHiFreq]];
    priHiLongLeft.localPos = CGPointMake(LEFT0_LOCAL_X, LEFT0_LOCAL_Y);
    [newWeapon.primaryPool addObject:priHiLongLeft];
    
    BossWeapon* priHiLongRight = [[BossWeapon alloc] initFromConfig:[self configBoomerangLongHiFreq]];
    priHiLongRight.localPos = CGPointMake(RIGHT0_LOCAL_X, RIGHT0_LOCAL_Y);
    [newWeapon.primaryPool addObject:priHiLongRight];
    
    BossWeapon* priHiShortLeft = [[BossWeapon alloc] initFromConfig:[self configBoomerangShortHiFreq]];
    priHiShortLeft.localPos = CGPointMake(LEFT1_LOCAL_X, LEFT1_LOCAL_Y);
    [newWeapon.primaryPool addObject:priHiShortLeft];
    
    BossWeapon* priHiShortRight = [[BossWeapon alloc] initFromConfig:[self configBoomerangShortHiFreq]];
    priHiShortRight.localPos = CGPointMake(RIGHT1_LOCAL_X, RIGHT1_LOCAL_Y);
    [newWeapon.primaryPool addObject:priHiShortRight];
    
    // Level0
    NSArray* primaryL0 = [NSArray arrayWithObjects:priL0Left, priL0Right, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:0 withObject:primaryL0];

    // Level1
    NSArray* primaryL1 = [NSArray arrayWithObjects:priL1Left, priL1Right, priL1LongLeft, priL1LongRight, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:1 withObject:primaryL1];
    
    // Level2
    NSArray* primaryL2 = [NSArray arrayWithObjects:priL1Left, priL1Right, priL1LongLeft, priL1LongRight, priDiag, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:2 withObject:primaryL2];
    
    // Level3
    NSArray* primaryL3 = [NSArray arrayWithObjects:priL1Left, priL1Right, priL1LongLeft, priL1LongRight, priDiag, priDiagBack, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:3 withObject:primaryL3];

    // Level4
    NSArray* primaryL4 = [NSArray arrayWithObjects:priHiShortLeft, priHiShortRight, priL1LongLeft, priL1LongRight, priDiag, priDiagBack, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:4 withObject:primaryL4];

    // Level5
    NSArray* primaryL5 = [NSArray arrayWithObjects:priHiShortLeft, priHiShortRight, priHiLongLeft, priHiLongRight, priDiag, priDiagBack, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:5 withObject:primaryL5];

    // set weapon delegate
    FlyerBoomerang* weaponDelegate = [[FlyerBoomerang alloc] init];
    newWeapon.delegate = weaponDelegate;
    [weaponDelegate release];
    
    givenPlayer.weapon = newWeapon;
    [newWeapon release];
        
    [priL0Left release];
    [priL0Right release];
    [priL1Left release];
    [priL1Right release];
    [priL1LongLeft release];
    [priL1LongRight release];
    [priDiag release];
    [priDiagBack release];
    [priHiLongLeft release];
    [priHiLongRight release];
    [priHiShortLeft release];
    [priHiShortRight release];
}

#pragma mark -
#pragma mark PlayerInitProtocol
- (void) initPlayer:(Player*)givenPlayer
{
    givenPlayer.flyerType = FlyerTypePograng;
    
    NSString* objectTypename = @"Pograng";
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
    
    givenPlayer.shadowName = @"PograngShadow";
    givenPlayer.pickupTypename = @"BoomerangUpgrade";

    // init weapon system
    [self initWeapon:givenPlayer];
}

@end
