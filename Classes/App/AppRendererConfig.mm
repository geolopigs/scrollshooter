//
//  AppRendererConfig.mm
//

#import "AppRendererConfig.h"
#import "RenderBucketsManager.h"


// constants
static const float GAMEVIEW_WIDTH = 16.0f;
static const float GAMEVIEW_HEIGHT = 24.0f;
static const float GAMEVIEW_WIDTH_IPAD = 18.0f;
static const float GAMEVIEW_HEIGHT_IPAD = 24.0f;

static const int SCROLLTILE_TEX_WIDTH = 512;
static const int SCROLLTILE_TEX_HEIGHT = 512;

@interface AppRendererConfig(AppRendererConfigPrivate)
- (void) configRenderBuckets;
- (void) configGameView;
@end

@implementation AppRendererConfig
@synthesize bucketsConfig;
@synthesize gameViewportSize;

#pragma mark -
#pragma mark Instance Methods
- (id) init
{
	if((self = [super init]))
	{
		bucketsConfig = [[RenderBucketsConfig alloc] init];
		[self configGameView];
		[self configRenderBuckets];
        
        scrollSubimageBuffer = new GLubyte[SCROLLTILE_TEX_WIDTH * SCROLLTILE_TEX_HEIGHT * 4];
        imageBuffer2 = new GLubyte[SCROLLTILE_TEX_WIDTH * SCROLLTILE_TEX_HEIGHT * 2];
	}
	return self;
}

- (void) dealloc
{
    delete [] imageBuffer2;
    delete [] scrollSubimageBuffer;
	[bucketsConfig release];
	[super dealloc];
}

- (CGRect) getViewportFrame
{
    float halfWidth = gameViewportSize.width * 0.5f;
    float halfHeight = gameViewportSize.height * 0.5f;
    
    // the origin of the result-frame is the coord of the screen-origin with respect to the bottom-left of the screen
    CGRect result = CGRectMake(halfWidth, halfHeight, gameViewportSize.width, gameViewportSize.height);
    return result;
}

- (GLubyte*) getScrollSubimageBuffer
{
    return scrollSubimageBuffer;
}

- (GLubyte*) getImageBuffer2
{
    return imageBuffer2;
}

#pragma mark -
#pragma mark Private Methods
- (void) configRenderBuckets
{
	[bucketsConfig addBucketByName:@"Background"];
    [bucketsConfig addBucketByName:@"GrPreDynamics"];
    [bucketsConfig addBucketByName:@"GrDynamics"];
    [bucketsConfig addBucketByName:@"GrPostDynamics"];
    [bucketsConfig addBucketByName:@"Shadows"];
    [bucketsConfig addBucketByName:@"BigDynamics"];
    [bucketsConfig addBucketByName:@"BigAddons"];
    [bucketsConfig addBucketByName:@"BigAddons2"];
	[bucketsConfig addBucketByName:@"Dynamics"];
    [bucketsConfig addBucketByName:@"Addons"];
    [bucketsConfig addBucketByName:@"Player"];
    [bucketsConfig addBucketByName:@"PlayerAddons"];
    [bucketsConfig addBucketByName:@"FrontLayer"];
    [bucketsConfig addBucketByName:@"Bullets"];
    [bucketsConfig addBucketByName:@"PointsHud"];
}

- (void) configGameView
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
    {
        gameViewportSize = CGSizeMake(GAMEVIEW_WIDTH, GAMEVIEW_HEIGHT);
    } 
    else 
    {
        gameViewportSize = CGSizeMake(GAMEVIEW_WIDTH_IPAD, GAMEVIEW_HEIGHT_IPAD);
    }
}

#pragma mark -
#pragma mark Singleton
static AppRendererConfig* singletonInstance = nil;
+ (AppRendererConfig*) getInstance
{
	@synchronized(self)
	{
		if (!singletonInstance)
		{
			singletonInstance = [[[AppRendererConfig alloc] init] retain];
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
