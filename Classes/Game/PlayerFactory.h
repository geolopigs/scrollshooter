//
//  PlayerFactory.h
//

#import <Foundation/Foundation.h>

@class Player;

@interface PlayerFactory : NSObject 
{
	NSMutableDictionary* archetypeLib;
}

+ (PlayerFactory*)getInstance;
+ (void) destroyInstance;
    
- (void) initArchetypeLib;
- (Player*) createFromKey:(NSString*)key AtPos:(CGPoint)givenPos;

@end
