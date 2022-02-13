//
//  DrawCommand.mm
//
//

#import "DrawCommand.h"


@implementation DrawCommand
@synthesize drawDelegate;
@synthesize drawData;

- (id) initWithDrawDelegate:(id)delegate DrawData:(id)data
{
	if((self = [super init]))
	{
		self.drawDelegate = delegate;
		self.drawData = data;
	}
	return self;
}

- (void) dealloc
{
    self.drawData = nil;
    self.drawDelegate = nil;
	[super dealloc];
}


@end
