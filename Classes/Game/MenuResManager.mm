//
//  MenuResManager.mm
//
//

#import "MenuResManager.h"
#import "Texture.h"
#import "UIImage+Pog.h"
#import "CurryAppDelegate.h"

@interface MenuResManager (MenuResManagerPrivate)
- (void) initIngameMenu;
- (void) shutdownIngameMenu;
@end

@implementation MenuResManager
@synthesize buttonPause;
@synthesize frontendBackground = _frontendBackground;
@synthesize frontendImages = _frontendImages;
@synthesize ingameImages = _ingameImages;
@synthesize unloadDelegates = _unloadDelegates;

#pragma mark - accessors
- (void) addDelegate:(NSObject<MenuResDelegate>*)newDelegate
{
    [self.unloadDelegates addObject:newDelegate];
}

- (void) removeDelegate:(NSObject<MenuResDelegate>*)toRemove
{
    [self.unloadDelegates removeObject:toRemove];
}

- (void) unloadFrontendImages
{
    self.frontendBackground.image = nil;
    for(NSObject<MenuResDelegate>* cur in _unloadDelegates)
    {
        [cur didUnloadFrontendImages];
    }
    [self.frontendImages removeAllObjects];
    [(CurryAppDelegate*)[UIApplication sharedApplication].delegate setToInGameBackgroundColor];
}

- (void) unloadIngameImages
{
    /*
#if DEBUG
    for(NSString* cur in _ingameImages)
    {
        UIImage* curImage = [_ingameImages objectForKey:cur];
        NSLog(@"%@ retain count %d", cur, [curImage retainCount]);
    }
#endif
    */
    // in-game menus are not managed by AppNavController; so, the screens are expected to release their images
    // no need to callback to them
    [self.ingameImages removeAllObjects];
    
    // after that, load up the frontend background
    [self loadFrontendBackgroundImage];
    [(CurryAppDelegate*)[UIApplication sharedApplication].delegate setToFrontendBackgroundColor];
}

- (UIImage*) loadImage:(NSString *)name isIngame:(BOOL)ingame
{
    UIImage* result = [self.frontendImages objectForKey:name];
    if(!result)
    {
        result = [self.ingameImages objectForKey:name];
    }
    if(!result)
    {
        result = [Texture loadTifImageFromFileName:name];
        if(result)
        {
            if(ingame)
            {
                [self.ingameImages setObject:result forKey:name];
            }
            else
            {
                [self.frontendImages setObject:result forKey:name];
            }
            [result release];
        }
    }
    return result;
}

- (UIImage*) loadImage:(NSString *)name withColor:(UIColor*)color withKey:(NSString*)key isIngame:(BOOL)ingame
{
    UIImage* result = [self.frontendImages objectForKey:key];
    if(!result)
    {
        result = [self.ingameImages objectForKey:key];
    }
    if(!result)
    {
        result = [UIImage imageNamed:name withColor:color];
        if(result)
        {
            if(ingame)
            {
                [self.ingameImages setObject:result forKey:key];
            }
            else
            {
                [self.frontendImages setObject:result forKey:key];
            }
        }
    }
    return result;
}


- (UIAlertView*) alertView
{
    return _alertView;
}

- (void) setAlertView:(UIAlertView *)alertView
{
    if(_alertView)
    {
        [_alertView dismissWithClickedButtonIndex:0 animated:YES];
        [_alertView release];
    }
    _alertView = [alertView retain];
}


#pragma mark -
#pragma mark Singleton
static MenuResManager* singletonMenuResManager = nil;
+ (MenuResManager*) getInstance
{
	@synchronized(self)
	{
		if (!singletonMenuResManager)
		{
			singletonMenuResManager = [[[MenuResManager alloc] init] retain];
		}
	}
	return singletonMenuResManager;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singletonMenuResManager release];
		singletonMenuResManager = nil;
	}
}

#pragma mark -
#pragma mark Member Methods
- (id) init
{
	if(self = [super init])
	{
        _frontendBackground = nil;
        self.frontendImages = [NSMutableDictionary dictionary];
        self.ingameImages = [NSMutableDictionary dictionary];
        self.unloadDelegates = [NSMutableSet set];
        _alertView = nil;
		[self initIngameMenu];
	}
	return self;
}

- (void) dealloc
{
    self.alertView = nil;
    self.ingameImages = nil;
    self.frontendImages = nil;
    self.unloadDelegates = nil;
    [_frontendBackground release];
	[self shutdownIngameMenu];
	[super dealloc];
}

- (void) initBackgroundImageWithFrame:(CGRect)givenFrame
{
    UIImageView* bgImageView = [[UIImageView alloc] initWithFrame:givenFrame];
    self.frontendBackground = bgImageView;
    [bgImageView release];
}

- (void) loadFrontendBackgroundImage
{
    self.frontendBackground.image = [self loadImage:@"mainBG_v3" isIngame:NO];
}

- (void) dismissAlertView
{
    // dismiss any active alertview that need to go away
    // when app enters background
    self.alertView = nil;
}

#pragma mark -
#pragma mark Private Methods
- (void) initIngameMenu
{
    self.buttonPause = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage* pauseImage = [Texture loadTifImageFromFileName:@"ButtonPause"];
    [self.buttonPause setImage:pauseImage forState:UIControlStateNormal];
    [pauseImage release];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    static const float PAUSEBUTTON_WIDTH = 0.1f;
    static const float PAUSEBUTTON_HEIGHT = 0.1f;
    static const float PAUSEBUTTON_X = 0.9f;
    static const float PAUSEBUTTON_Y = 0.0f;
    CGRect buttonFrame = CGRectMake(PAUSEBUTTON_X * screenBounds.size.width, PAUSEBUTTON_Y * screenBounds.size.width,
                                    PAUSEBUTTON_WIDTH * screenBounds.size.width, PAUSEBUTTON_HEIGHT * screenBounds.size.width);
    self.buttonPause.frame = buttonFrame;
}

- (void) shutdownIngameMenu
{
    [self.buttonPause setImage:nil forState:UIControlStateNormal];
    self.buttonPause = nil;
	[igMenu release];
}

@end
