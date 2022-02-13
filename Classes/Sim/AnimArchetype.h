//
//  AnimArchetype.h
//
//

#import <Foundation/Foundation.h>


@interface AnimArchetype : NSObject 
{
	NSMutableArray* animFrames;
	float	animSpeed;
}
@property (nonatomic,readonly) NSMutableArray* animFrames;
@property (nonatomic,readonly) float animSpeed;

- (id) initWithFilename:(NSString*)filename 
			  NumFrames:(unsigned int)numFrames 
			  AnimSpeed:(float)givenSpeed;

@end
