//
//  Sector.mm
//  Curry
//
//  Created by Shu Chiun Cheah on 6/29/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "Sector.h"
#import "Texture.h"
#import "BgLayer.h"
#import "RenderBucketsManager.h"


@implementation Sector
@synthesize rect;
@synthesize bgTex;
@synthesize renderer;

// !\brief
//  This function initializes a Sector at the given position with a given width; the height of the Sector
//  is calculated from the aspect-ratio of the given Bg Texture
- (id) initFromBgTex:(Texture*)tex atPosition:(CGPoint)pos withWidth:(float)width
{
    self = [super init];
    if(self)
    {
        assert(tex);
        self.bgTex = tex;
        
        // compute height from the aspect-ratio of the given texture
        float height = (width * bgTex.imageHeight) / bgTex.imageWidth;
        
        self.rect = CGRectMake(pos.x, pos.y, width, height);
        
        bucketId = [[RenderBucketsManager getInstance] getIndexFromName:@"Background"];
        self.renderer = [[BgLayer alloc] initWithFrame:self.rect texture:self.bgTex];
    }
    return self;
}

- (void) dealloc
{
    [bgTex release];
    [renderer release];
    [super dealloc];
}

- (void) addDraw
{
    BgLayerInstance* instanceData = [BgLayerInstance alloc];
    instanceData.pos = CGPointMake(0.0f, 0.0f);
	DrawCommand* cmd = [[DrawCommand alloc] initWithDrawDelegate:renderer DrawData:instanceData];
	[[RenderBucketsManager getInstance] addCommand:cmd toBucket:bucketId];
	[instanceData release];
    [cmd release];
}

@end
