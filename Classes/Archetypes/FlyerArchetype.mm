//
//  FlyerArchetype.mm
//

#import "FlyerArchetype.h"
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
#import "FlyerWoodenBullets.h"
#import "GameObjectSizes.h"

static const float COL_ORIGIN_X = -0.5f;
static const float COL_ORIGIN_Y = -0.25f;

// AutoFireShot
static const unsigned int NUM_WEAPONLEVELS = 6;
static const float PLAYER_AUTOFIRESHOT_SPEED = 100.0f;
static const float PLAYER_TRIPLEFIRE_ANGLE = M_PI * 0.05f;
static const float CENTER_LOCAL_X = 0.0f;
static const float CENTER_LOCAL_Y = 8.0f;
static const float LEFT_LOCAL_X = -4.0f;
static const float LEFT_LOCAL_Y = 8.0f;
static const float RIGHT_LOCAL_X = 4.0f;
static const float RIGHT_LOCAL_Y = 8.0f;

@interface FlyerArchetype (PrivateMethods)
- (void) initWeapon:(Player*)givenPlayer;
@end

@implementation FlyerArchetype

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

- (void) initWeapon:(Player *)givenPlayer
{
    FiringPath* centerL0 = [FiringPath playerFiringPathWithName:@"AutoFireShot" dir:0.0f speed:PLAYER_AUTOFIRESHOT_SPEED];
    centerL0.timeBetweenShots = 0.13f;
    centerL0.shotPos = CGPointMake(CENTER_LOCAL_X, CENTER_LOCAL_Y);

    FiringPath* leftL1 = [FiringPath playerFiringPathWithName:@"AutoFireShot" dir:0.0f speed:PLAYER_AUTOFIRESHOT_SPEED];
    leftL1.timeBetweenShots = 0.10f;
    leftL1.shotPos = CGPointMake(LEFT_LOCAL_X, LEFT_LOCAL_Y);
    FiringPath* rightL1 = [FiringPath playerFiringPathWithName:@"AutoFireShot" dir:0.0f speed:PLAYER_AUTOFIRESHOT_SPEED];
    rightL1.timeBetweenShots = 0.10f;
    rightL1.shotPos = CGPointMake(RIGHT_LOCAL_X, RIGHT_LOCAL_Y);

    FiringPath* leftL2 = [FiringPath playerFiringPathWithName:@"AutoFireShot" dir:0.0f speed:PLAYER_AUTOFIRESHOT_SPEED];
    leftL2.timeBetweenShots = 0.065f;
    leftL2.shotPos = CGPointMake(LEFT_LOCAL_X, LEFT_LOCAL_Y);
    FiringPath* rightL2 = [FiringPath playerFiringPathWithName:@"AutoFireShot" dir:0.0f speed:PLAYER_AUTOFIRESHOT_SPEED];
    rightL2.timeBetweenShots = 0.065f;
    rightL2.shotPos = CGPointMake(RIGHT_LOCAL_X, RIGHT_LOCAL_Y);

    FiringPath* leftL5 = [FiringPath playerFiringPathWithName:@"AutoFireShot" dir:PLAYER_TRIPLEFIRE_ANGLE speed:PLAYER_AUTOFIRESHOT_SPEED];
    leftL5.timeBetweenShots = 0.065f;
    leftL5.shotPos = CGPointMake(LEFT_LOCAL_X, LEFT_LOCAL_Y);
    FiringPath* rightL5 = [FiringPath playerFiringPathWithName:@"AutoFireShot" dir:-PLAYER_TRIPLEFIRE_ANGLE speed:PLAYER_AUTOFIRESHOT_SPEED];
    rightL5.timeBetweenShots = 0.065f;
    rightL5.shotPos = CGPointMake(RIGHT_LOCAL_X, RIGHT_LOCAL_Y);
    FiringPath* centerL5 = [FiringPath playerFiringPathWithName:@"AutoFireShot" dir:0.0f speed:PLAYER_AUTOFIRESHOT_SPEED];
    centerL5.timeBetweenShots = 0.10f;
    centerL5.shotPos = CGPointMake(CENTER_LOCAL_X, CENTER_LOCAL_Y);
    
    // init primary config
    FlyerWeapon* newWeapon = [[FlyerWeapon alloc] init];
    for(unsigned int i = 0; i < NUM_WEAPONLEVELS; ++i)
    {
        [newWeapon.primaryConfig addObject:[NSNull null]];
        [newWeapon.secondaryConfig addObject:[NSNull null]];
    }
    
    // add all the unique weapons into primary or secondary pools
    [newWeapon.primaryPool addObject:centerL0];
    [newWeapon.primaryPool addObject:leftL1];
    [newWeapon.primaryPool addObject:rightL1];
    [newWeapon.primaryPool addObject:leftL2];
    [newWeapon.primaryPool addObject:rightL2];
    [newWeapon.primaryPool addObject:leftL5];
    [newWeapon.primaryPool addObject:rightL5];
    [newWeapon.primaryPool addObject:centerL5];
    
    // Level0
    NSArray* primaryL0 = [NSArray arrayWithObject:centerL0];
    [newWeapon.primaryConfig replaceObjectAtIndex:0 withObject:primaryL0];
    
    // Level1
    NSArray* primaryL1 = [NSArray arrayWithObjects:leftL1, rightL1, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:1 withObject:primaryL1];

    // Level2
    NSArray* primaryL2 = [NSArray arrayWithObjects:leftL2, rightL2, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:2 withObject:primaryL2];
    
    // Level3
    NSMutableDictionary* missileConfigL3 = [NSMutableDictionary dictionaryWithObject:@"homingMissile" forKey:@"weaponType"];
    [missileConfigL3 setObject:[NSNumber numberWithUnsignedInt:2] forKey:@"numPerRound"];
    BossWeapon* missileL3 = [[BossWeapon alloc] initFromConfig:missileConfigL3];
    [newWeapon.primaryConfig replaceObjectAtIndex:3 withObject:primaryL2];
    [newWeapon.secondaryConfig replaceObjectAtIndex:3 withObject:missileL3];
    [newWeapon.secondaryPool addObject:missileL3];

    // Level4
    NSMutableDictionary* missileConfigL4 = [NSMutableDictionary dictionaryWithObject:@"homingMissile" forKey:@"weaponType"];
    [missileConfigL4 setObject:[NSNumber numberWithUnsignedInt:4] forKey:@"numPerRound"];
    BossWeapon* missileL4 = [[BossWeapon alloc] initFromConfig:missileConfigL4];
    [newWeapon.primaryConfig replaceObjectAtIndex:4 withObject:primaryL2];
    [newWeapon.secondaryConfig replaceObjectAtIndex:4 withObject:missileL4];
    [newWeapon.secondaryPool addObject:missileL4];
    
    // Level5
    NSArray* primaryL5 = [NSArray arrayWithObjects:leftL5, rightL5, centerL5, nil];
    [newWeapon.primaryConfig replaceObjectAtIndex:5 withObject:primaryL5];
    [newWeapon.secondaryConfig replaceObjectAtIndex:5 withObject:missileL4];
    
    // set weapon delegate
    FlyerWoodenBullets* woodenBulletsDelegate = [[FlyerWoodenBullets alloc] init];
    newWeapon.delegate = woodenBulletsDelegate;
    [woodenBulletsDelegate release];
    
    
    givenPlayer.weapon = newWeapon;
    [newWeapon release];
        
    [centerL5 release];
    [missileL4 release];
    [missileL3 release];
    [leftL5 release];
    [rightL5 release];
    [leftL2 release];
    [rightL2 release];
    [leftL1 release];
    [rightL1 release];
    [centerL0 release];
}

#pragma mark -
#pragma mark PlayerInitProtocol
- (void) initPlayer:(Player*)givenPlayer
{
    givenPlayer.flyerType = FlyerTypePoglider;
    
    NSString* objectTypename = @"Flyer";
	CGSize mySize = [[GameObjectSizes getInstance] renderSizeFor:objectTypename];
    CGSize colSize = [[GameObjectSizes getInstance] colSizeFor:objectTypename];

    givenPlayer.colAABB = CGRectMake(COL_ORIGIN_X * colSize.width, COL_ORIGIN_Y * colSize.height, colSize.width, colSize.height);

	Sprite* myRenderer = [[Sprite alloc] initWithSize:mySize colRect:[givenPlayer colAABB]];
	givenPlayer.renderer = myRenderer;
	[myRenderer release];

    LevelAnimData* levelAnimData = [[[LevelManager getInstance] curLevel] animData];
    AnimClipData* data = [levelAnimData getClipForName:objectTypename];
    
    AnimLinearController* newController = [[AnimLinearController alloc] initFromAnimClipData:data];
    givenPlayer.anim = [NSArray arrayWithObjects:newController, nil];
    
    givenPlayer.animController = newController;
    [newController release];
    
    // flyer type specific associated items
    givenPlayer.shadowName = @"FlyerShadow";
    givenPlayer.pickupTypename = @"DoubleBulletUpgrade";
    
    // init weapon system
    [self initWeapon:givenPlayer];
}

@end
