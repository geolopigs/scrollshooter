//
//  AnimArchetype.mm
//

#import "AnimArchetype.h"
#import "Texture.h"

@implementation AnimArchetype
@synthesize animFrames;
@synthesize animSpeed;


- (id) initWithFilename:(NSString*)filename NumFrames:(unsigned int)numFrames AnimSpeed:(float)givenSpeed
{
	if((self = [super init]))
	{
		animSpeed = givenSpeed;
		animFrames = [[NSMutableArray arrayWithCapacity:numFrames] retain];
		for(unsigned int i = 0; i < numFrames; ++i)
		{
			NSString* frameFilename;
			if(10 > i)
			{
				frameFilename = [NSString stringWithFormat:@"%@_00%d",filename,i];
			}
			else if(100 > i)
			{
				frameFilename = [NSString stringWithFormat:@"%@_0%d",filename,i];
			}
			else
			{
				frameFilename = [NSString stringWithFormat:@"%@_%d",filename,i];
			}
				
				
			Texture* newFrame = [[[Texture alloc] initFromFileName:frameFilename] retain];
			[animFrames addObject:newFrame];
		}
	}
	return self;
}

- (void) dealloc
{
	[animFrames release];
	[super dealloc];
}

@end
