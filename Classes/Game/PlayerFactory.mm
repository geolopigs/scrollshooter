//
//  PlayerFactory.mm
//

#import "PlayerFactory.h"
#import "Player.h"
#import "AnimArchetype.h"
#import "FlyerArchetype.h"
#import "FlyerPogwing.h"
#import "FlyerPograng.h"

@implementation PlayerFactory

#pragma mark -
#pragma mark Singleton

static PlayerFactory* singletonInstance = nil;
+ (PlayerFactory*)getInstance
{
    @synchronized(self)
    {
        if (singletonInstance == nil)
		{
			singletonInstance = [[PlayerFactory alloc] init];
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

#pragma mark -
#pragma mark factory methods

- (id) init
{
	if((self = [super init]))
	{
        [self initArchetypeLib];
	}
	return self;
}

- (void) dealloc
{
	[archetypeLib release];
	[super dealloc];
}

- (Player*) createFromKey:(NSString *)key AtPos:(CGPoint)givenPos
{
	Player* newPlayer = nil;
	AnimArchetype<PlayerInitProtocol>* cur = [archetypeLib objectForKey:key];
	if(cur)
	{
		newPlayer = [[Player alloc] initAtPos:givenPos usingDelegate:cur];
        
        //NSLog(@"Created player %@", key);
	}
	
	return newPlayer;	
}

- (void) initArchetypeLib
{
	archetypeLib = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
	
	// Flyer archetype
	NSObject<PlayerInitProtocol>* newType = [[FlyerArchetype alloc] init];
	[archetypeLib setObject:newType forKey:@"Flyer"];
    [newType release];

    // Pogwing
    NSObject<PlayerInitProtocol>* pogwing = [[FlyerPogwing alloc] init];
    [archetypeLib setObject:pogwing forKey:@"Pogwing"];
    [pogwing release];
    
    // Pograng
    NSObject<PlayerInitProtocol>* pograng = [[FlyerPograng alloc] init];
    [archetypeLib setObject:pograng forKey:@"Pograng"];
    [pograng release];
}

@end
