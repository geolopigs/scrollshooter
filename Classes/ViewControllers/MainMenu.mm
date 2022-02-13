//
//  MainMenu.mm
//  CurryFlyer
//

#import "MainMenu.h"
#import "RouteSelect.h"
#import "AppNavController.h"
#import "SoundManager.h"
#import "RouteInfo.h"
#import "StatsManager.h"
#import "Appirater.h"
#import "Texture.h"
#import "MenuResManager.h"
#import "CurryAppDelegate.h"
#import "LevelManager.h"
#import "GameViewController.h"
#import "SettingsMenu.h"
#import "DebugMenu.h"
#import "GameCenterManager.h"
#import "AchievementsManager.h"
#import "GameModeMenu.h"
#import "StoreMenu.h"
#import "GoalsMenu.h"
#import "ProductManager.h"
#import "GameManager.h"
#import "PlayerInventoryIds.h"
#import "PlayerInventory.h"
#import "FlyerSelectPage.h"
#import "PogUIPageControlDots.h"
#import "StatsController.h"
#import "Credits.h"
#import "TutorialTourney.h"
#import "GimmieEventIds.h"
#import "PogAnalytics+PeterPog.h"
#import "MoreMenu.h"
#import "PogUITextLabel.h"
#import "MBProgressHUD.h"
#import <iAd/iAd.h>

enum FLYERSELECT_PAGE 
{
    FLYERSELECT_PAGE_POGWING = 0,
    FLYERSELECT_PAGE_POGLIDER,
    FLYERSELECT_PAGE_POGRANG,
    
    FLYERSELECT_PAGES_NUM
};

@interface MainMenu () <GameCenterManagerAuthenticationDelegate, ADBannerViewDelegate>
@property (nonatomic, retain) ADBannerView* adBannerView;
- (void) loadImages;
- (void) fadeAndHideBalloon;
- (void) dismissFrontSubMenuImmediate;
- (void) dismissFrontSubMenuAnimated:(BOOL)animated;
- (BOOL) toggleFrontSubMenuForClass:(Class)nextSubMenuClass;
- (void) newGame;
- (void) tourneyGame;
- (void) setupSoundButtons;
- (void) layoutButtons;
- (void) resetButtonStates;
- (void) initFlyerSelect;
- (void) resetScrollView;
- (void) gotoPage:(unsigned int)pageIndex animated:(BOOL)isAnimated;
- (void) settleOnPage:(unsigned int)pageIndex;

- (CGPoint) screenPointFromNibPoint:(CGPoint)nibPoint;
- (CGPoint) screenPointFromTopRightOfNibRect:(CGRect)nibRect;
- (CGPoint) screenPointFromTopLeftOfNibRect:(CGRect)nibRect;
- (CGPoint) screenPointFromBotRightOfNibRect:(CGRect)nibRect;
- (CGPoint) screenPointFromBotLeftOfNibRect:(CGRect)nibRect;
- (CGPoint) screenPointFromCenterOfNibRect:(CGRect)nibRect;
- (CGPoint) screenPointFromTopCenterOfNibRect:(CGRect)nibRect;
- (CGPoint) screenPointFromBotCenterOfNibRect:(CGRect)nibRect;
- (CGRect) resizeRect:(CGRect)sourceRect byFactor:(float)resizeFactor;
- (CGAffineTransform) transformFromScreenPoint:(CGPoint)point;
- (void) slideSubInFromLeft;
- (void) slideSubOutToLeft;
- (void) slideSubInFromRight;
- (void) slideSubOutToRight;
- (void) subMenu:(UIViewController*)subController slideUpIntoView:(UIView*)subView;
- (void) subMenu:(UIViewController*)subController slideDownFromView:(UIView*)subView;
- (void) dismissFrontSubMenuFromView:(UIView*)subView;

- (void) setMainFrontAlpha:(float)alpha;
- (void) setMainfrontHidden:(BOOL)hidden;

- (void) startAccelerometer;
- (void) stopAccelerometer;

- (void) nextpeerDashboardWillAppear:(NSNotification*)note;
@end

@implementation MainMenu
@synthesize mainFrontviews = _mainFrontviews;
@synthesize frontSubMenu = _frontSubMenu;
@synthesize flyerSelectPages = _flyerSelectPages;
@synthesize shouldLaunchTourneyWhenViewLoaded = _shouldLaunchTourneyWhenViewLoaded;

// TODO: delete this one; it's not used
@synthesize shouldLaunchNextpeerWhenAppear = _shouldLaunchNextpeerWhenAppear;


- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self)
    {
        _screenSize = CGSizeMake(320.0f, 480.0f);
        _nibViewSize = _screenSize;
        _flyerSelectPages = [[NSMutableArray array] retain];
        _mainFrontviews = [[NSMutableArray array] retain];
        _currentPage = 0;
        _prevSettledPage = -1;
        _selectedFlyerIndex = 0;
        _pageControlUsed = NO;
        _accelSettled = YES;
        _allowAccelScroll = NO;
        _nextpeerRegistered = NO;
        _shouldLaunchTourneyWhenViewLoaded = NO;
        _shouldLaunchNextpeerWhenAppear = NO;
        _flyerIdsArray = [[NSArray arrayWithObjects:FLYER_ID_POGWING, FLYER_ID_POGLIDER, FLYER_ID_POGRANG, nil] retain];
    }
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[MenuResManager getInstance] removeDelegate:self];
    [self didUnloadFrontendImages];

    [self dismissFrontSubMenuAnimated:NO];
    [_mainFrontviews release];
    [backgroundImage release];
    [playButtonImage release];
    [loadingScreen release];
    [loadingImageView release];
    [rootView release];
    [settingsButton release];
    [buttonPlay release];
    [settingsButtonImage release];
    [soundToggleView release];
    [soundOnImage release];
    [soundOffImage release];
    [buttonSound release];
    [buttonStoreImage release];
    [buttonStore release];
    [mainView release];
    [playSubView release];
    [settingsSubview release];
    [_flyerIdsArray release];
    [restorePurchaseLabel release];
    for(FlyerSelectPage* cur in _flyerSelectPages)
    {
        [cur.view removeFromSuperview];
    }
    [_flyerSelectPages release];
    [flyerSelectScrollView release];
    [_flyerSelectPageDots release];
    [super dealloc];
}

- (void) setAdBannerView:(ADBannerView *)adBannerView {
    if(_adBannerView != adBannerView) {
        _adBannerView.delegate = nil;
        [_adBannerView removeFromSuperview];
        _adBannerView = adBannerView;
        
        if(adBannerView) {
            adBannerView.delegate = self;
            [self.view addSubview:adBannerView];
        }
    }
}

- (void) setupADBanner {
    if(!self.adBannerView) {
        self.adBannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
//        CGRect bannerFrame = self.adBannerView.frame;
//        bannerFrame.origin.y = self.view.bounds.size.height;
//        self.adBannerView.frame = bannerFrame;
    }
}

- (void) layoutADBannerAnimated:(BOOL)animated {
    if(self.adBannerView.superview == self.view) {
        CGRect bannerFrame = self.adBannerView.frame;
        CGRect bottomFrame = self.bottomButtonsView.frame;
        CGRect contentRect = self.bottomButtonsView.superview.frame;
        CGRect settingsFrame = settingsSubview.frame;
        if (self.adBannerView.bannerLoaded) {
            CGFloat contentBottom = self.view.bounds.size.height - self.adBannerView.bounds.size.height;
            bannerFrame.origin.y = contentBottom;
            
            CGPoint bannerOriginInContent = [self.view convertPoint:bannerFrame.origin toView:self.bottomButtonsView.superview];
            bottomFrame.origin.y = bannerOriginInContent.y - bottomFrame.size.height;
        } else {
            bannerFrame.origin.y = self.view.bounds.size.height;
            bottomFrame.origin.y = contentRect.size.height - bottomFrame.size.height;
        }
        settingsFrame.origin.y = bottomFrame.origin.y + (0.5 * bottomFrame.size.height) - settingsFrame.size.height;
        [UIView animateWithDuration:animated ? 0.2 : 0.0 animations:^{
            self.bottomButtonsView.frame = bottomFrame;
            self.adBannerView.frame = bannerFrame;
            settingsSubview.frame = settingsFrame;
        }];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];

    // init screen-size and nib-view-size before any of components get moved around
    _screenSize = [[UIScreen mainScreen] bounds].size;
    _nibViewSize = self.view.frame.size;
    
    [self layoutButtons];
    [self initFlyerSelect];
#if defined(DEBUG)
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    versionLabel.text = versionString;
    versionLabel.hidden = NO;
#else
    versionLabel.hidden = YES;
#endif
    loadingScreen.hidden = YES;
    
    [[MenuResManager getInstance] addDelegate:self];

    // register nextpeer callbacks
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextpeerDashboardWillAppear:) 
                                                 name:kNextpeerDashboardWillAppear object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productManagerRestoreFinished:) name:kProductManagerRestoreFinishedNotification object:nil];
    _nextpeerRegistered = YES;
    _shouldLaunchNextpeerWhenAppear = NO;
    
    [restorePurchaseLabel setText:@"RESTORE PURCHASES"];
    [restorePurchaseLabel setBackgroundColor:[UIColor clearColor]];

    // start music
    [[SoundManager getInstance] playMusic:@"Ambient1" doLoop:YES];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _nextpeerRegistered = NO;
    [[MenuResManager getInstance] removeDelegate:self];
    [self didUnloadFrontendImages];
    
    [self dismissFrontSubMenuAnimated:NO];
    [_mainFrontviews removeAllObjects];
    [backgroundImage release];
    backgroundImage = nil;
    [playButtonImage release];
    playButtonImage = nil;
    
    [loadingScreen release];
    loadingScreen = nil;
    [loadingImageView release];
    loadingImageView = nil;
    [rootView release];
    rootView = nil;
    [settingsButton release];
    settingsButton = nil;
    [buttonPlay release];
    buttonPlay = nil;
    [settingsButtonImage release];
    settingsButtonImage = nil;
    [soundToggleView release];
    soundToggleView = nil;
    [soundOnImage release];
    soundOnImage = nil;
    [soundOffImage release];
    soundOffImage = nil;
    [buttonSound release];
    buttonSound = nil;
    [buttonStoreImage release];
    buttonStoreImage = nil;
    [buttonStore release];
    buttonStore = nil;
    [mainView release];
    mainView = nil;
    [playSubView release];
    playSubView = nil;
    [settingsSubview release];
    settingsSubview = nil;
    for(FlyerSelectPage* cur in _flyerSelectPages)
    {
        [cur.view removeFromSuperview];
    }
    [_flyerSelectPages removeAllObjects];
    [flyerSelectScrollView release];
    flyerSelectScrollView = nil;
    [_flyerSelectPageDots release];
    _flyerSelectPageDots = nil;
    [super viewDidUnload];
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutADBannerAnimated:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // set scrollView delegate
    flyerSelectScrollView.delegate = self;
    for(FlyerSelectPage* cur in _flyerSelectPages)
    {
        [cur viewWillAppear:NO];
    }
    
    // init hide/unhide states
    [self resetButtonStates];
    [self resetScrollView];
    
    // setup texture resource management
    [[MenuResManager getInstance] addDelegate:self];
    [self loadImages];
    
    // external callbacks
    //[Appirater appEnteredForeground:YES];

    if(!_nextpeerRegistered)
    {
        // register nextpeer callbacks
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextpeerDashboardWillAppear:) 
                                                     name:kNextpeerDashboardWillAppear object:nil];
        _nextpeerRegistered = YES;
    }
    if(_shouldLaunchTourneyWhenViewLoaded)
    {
        [self tourneyGame];
        _shouldLaunchTourneyWhenViewLoaded = NO;
    }
    if(_shouldLaunchNextpeerWhenAppear)
    {
        // this is when we came back from TutorialTourney
        _shouldLaunchNextpeerWhenAppear = NO;
        [self tourneyGame];
//        [Nextpeer launchDashboard];
    }
    
    [self setupADBanner];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[GameCenterManager getInstance] setAuthenticationDelegate:self];
    [[GameCenterManager getInstance] checkAndAuthenticate];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.adBannerView = nil;
}

- (void) viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _nextpeerRegistered = NO;
    _shouldLaunchNextpeerWhenAppear = NO;

    [[MenuResManager getInstance] removeDelegate:self];
    [self didUnloadFrontendImages];
    [self dismissFrontSubMenuAnimated:NO];

    for(FlyerSelectPage* cur in _flyerSelectPages)
    {
        [cur viewDidDisappear:NO];
    }
    flyerSelectScrollView.delegate = nil;
    [super viewDidDisappear:animated];
}

- (BOOL) isShowingStory
{
    BOOL result = NO;
    if(([self frontSubMenu]) &&
       ([self.frontSubMenu isMemberOfClass:[RouteSelect class]]))
    {
        RouteSelect* routeSelect = (RouteSelect*)[self frontSubMenu];
        if([routeSelect storyStarted])
        {
            result = YES;
        }
    }
    return result;
}

#pragma mark - setup

// resets hide/unhide for all buttons to the state when the main menu just appeared fresh
- (void) resetButtonStates
{
    [self setupSoundButtons];
    loadingScreen.hidden = YES;
    [self setMainFrontAlpha:1.0f];
    [self setMainfrontHidden:NO];
    playSubView.hidden = YES;
    settingsSubview.hidden = YES;
    [self dismissFrontSubMenuAnimated:NO];    
}

- (void) layoutButtons
{
    // programmatically layout buttons on iPad based on their relative positions in the nib file
    // no need to lay them out on the iPhone because the nib files are designed for the iPhone
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        const float iPadScale = ([[UIScreen mainScreen] bounds].size.height / rootView.frame.size.height);
        [rootView setTransform:CGAffineTransformMakeScale(iPadScale, iPadScale)];
    }
    
    // add items to be occluded by slide-in sub-menus to the mainFronviews list
    // (clipping subviews are not added in here because they keep track of their hidden states
    //  when the play and settings buttons are pressed)
    [_mainFrontviews addObject:soundToggleView];
    [_mainFrontviews addObject:buttonPlay];
    [_mainFrontviews addObject:playButtonImage];
    [_mainFrontviews addObject:settingsButton];
    [_mainFrontviews addObject:settingsButtonImage];
    [_mainFrontviews addObject:buttonStore];
    [_mainFrontviews addObject:buttonStoreImage];
    [_mainFrontviews addObject:flyerSelectScrollView];
    [_mainFrontviews addObject:_flyerSelectPageDots];
}

- (void) loadImages
{
    playButtonImage.image = [[MenuResManager getInstance] loadImage:@"ButtonPlay_v3" isIngame:NO];
    
    NSArray* flyerIdsArray = [NSArray arrayWithObjects:
                              FLYER_ID_POGWING,
                              FLYER_ID_POGLIDER,
                              FLYER_ID_POGRANG,
                              nil];
    for(unsigned int index = 0; index < FLYERSELECT_PAGES_NUM; ++index)
    {
        FlyerSelectPage* curPage = [_flyerSelectPages objectAtIndex:index];
        NSString* curId = [flyerIdsArray objectAtIndex:index];
        curPage.image = [[MenuResManager getInstance] loadImage:
                         [[ProductManager getInstance] getFlyerImageNameForProductId:curId]
                                                       isIngame:NO];
    }
}

- (void) setupSoundButtons
{
    if([[SoundManager getInstance] enabled])
    {
        soundOnImage.hidden = NO;
        soundOffImage.hidden = YES;
    }
    else
    {
        soundOnImage.hidden = YES;
        soundOffImage.hidden = NO;
    }
}

static const float kFlyerSelectPageOriginY = 40.0f;
- (void) initFlyerSelect
{
    CGRect pageFrame = [flyerSelectScrollView frame];
    [_flyerSelectPageDots setupWithNumPages:FLYERSELECT_PAGES_NUM];
    for(unsigned int index = 0; index < FLYERSELECT_PAGES_NUM; ++index)
    {
        FlyerSelectPage* newFlyerPage = [[FlyerSelectPage alloc] initWithFlyerProductId:[_flyerIdsArray objectAtIndex:index]];
        [_flyerSelectPages addObject:newFlyerPage];
        [flyerSelectScrollView addSubview:newFlyerPage.view];  
        CGRect myFrame = newFlyerPage.view.frame;
        myFrame.origin.x = (pageFrame.size.width * index);
        myFrame.origin.y = kFlyerSelectPageOriginY;
        newFlyerPage.view.frame = myFrame;    
        
        if(index < (FLYERSELECT_PAGES_NUM / 2))
        {
            [newFlyerPage alignImageRightAnimated:NO];
        }
        else if(index > (FLYERSELECT_PAGES_NUM / 2))
        {
            [newFlyerPage alignImageLeftAnimated:NO];
        }
        else
        {
            [newFlyerPage alignImageCenterAnimated:NO];
        }
        [newFlyerPage release];
    }
    flyerSelectScrollView.pagingEnabled = YES;
    flyerSelectScrollView.scrollEnabled = YES;
    flyerSelectScrollView.contentSize = CGSizeMake(pageFrame.size.width * FLYERSELECT_PAGES_NUM,
                                                   pageFrame.size.height - kFlyerSelectPageOriginY);
    flyerSelectScrollView.showsHorizontalScrollIndicator = NO;
    flyerSelectScrollView.showsVerticalScrollIndicator = NO;
    flyerSelectScrollView.scrollsToTop = NO;
    flyerSelectScrollView.delaysContentTouches = NO;
}

- (void) resetScrollView
{
    unsigned int resetPage = 0;
    NSString* curGameFlyer = [[GameManager getInstance] flyerType];
    for(NSString* curId in _flyerIdsArray)
    {
        if([curGameFlyer isEqualToString:[[ProductManager getInstance] getFlyerTypeNameForProductId:curId]])
        {
            break;
        }
        ++resetPage;
    }

    // hide info on all pages
    for(FlyerSelectPage* cur in _flyerSelectPages)
    {
        [cur hideFlyerProductInfo];
    }
    _prevSettledPage = -1;
    
    _pageControlUsed = YES;
    [self gotoPage:resetPage animated:NO];
    [self settleOnPage:resetPage];
    
    // force update pageControl dots because this is a reset
    [_flyerSelectPageDots setCurPage:_currentPage];
}

- (void) gotoPage:(unsigned int)pageIndex animated:(BOOL)isAnimated
{
    if(pageIndex > FLYERSELECT_PAGES_NUM)
    {
        pageIndex = FLYERSELECT_PAGES_NUM - 1;
    }

    // hide info on all pages
    for(FlyerSelectPage* cur in _flyerSelectPages)
    {
        [cur hideFlyerProductInfo];
    }

    _currentPage = pageIndex;
    if(_pageControlUsed)
    {
        CGRect myFrame = [flyerSelectScrollView frame];
        myFrame.origin.x = (myFrame.size.width * _currentPage);
        myFrame.origin.y = 0.0f;
        [flyerSelectScrollView scrollRectToVisible:myFrame animated:isAnimated];
    }    
    else
    {
        // not page-control triggered, player swiped in scrollView
        // just set the page control currentPage
        [_flyerSelectPageDots setCurPage:pageIndex];
    }
}    

- (void) settleOnPage:(unsigned int)pageIndex
{
    if(pageIndex > FLYERSELECT_PAGES_NUM)
    {
        pageIndex = FLYERSELECT_PAGES_NUM - 1;
    }
/*
    if((_prevSettledPage != pageIndex) && (0 <= _prevSettledPage) && (_prevSettledPage < FLYERSELECT_PAGES_NUM))
    {
        FlyerSelectPage* prev = [_flyerSelectPages objectAtIndex:_prevSettledPage];
        [prev hideFlyerProductInfo];
    }*/
    _prevSettledPage = pageIndex;
        
    // adjust image transforms on all pages
    if(pageIndex == (FLYERSELECT_PAGES_NUM / 2))
    {
        // if on center page, move the other pages closer to center
        for(unsigned int i = 0; i < FLYERSELECT_PAGES_NUM; ++i)
        {
            if(i < (FLYERSELECT_PAGES_NUM / 2))
            {
                [[_flyerSelectPages objectAtIndex:i] alignImageRightAnimated:YES];
            }
            else if(i > (FLYERSELECT_PAGES_NUM / 2))
            {
                [[_flyerSelectPages objectAtIndex:i] alignImageLeftAnimated:YES];
            }
        }
        restorePurchaseContainer.hidden = YES;
    }
    else
    {
        // otherwise, put everyone back to center
        for(unsigned int i = 0; i < FLYERSELECT_PAGES_NUM; ++i)
        {
            [[_flyerSelectPages objectAtIndex:i] alignImageCenterAnimated:YES];
        }
        restorePurchaseContainer.hidden = NO;
    }
    
    // load product info for the target page if necessary
    [[_flyerSelectPages objectAtIndex:pageIndex] loadFlyerProductInfoSilent:YES];
    _selectedFlyerIndex = pageIndex;
    
    // tell accelerometer that we've just settled
    _accelSettled = YES;
}

- (void)changeToPage:(unsigned int)pageIndex
{
    // set this so that gotoPage doesn't recursively set the page-control page
    _pageControlUsed = YES;
    [self gotoPage:pageIndex animated:YES];
    [self settleOnPage:pageIndex];
}

- (void) registerToObserveNextpeerDashboardWillAppear
{
    if(!_nextpeerRegistered)
    {
        // register nextpeer callbacks
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nextpeerDashboardWillAppear:) 
                                                     name:kNextpeerDashboardWillAppear object:nil];
        _nextpeerRegistered = YES;
    }
}


#pragma mark - private methods
- (CGPoint) screenPointFromNibPoint:(CGPoint)nibPoint
{
    CGPoint resultPos = CGPointMake((nibPoint.x / _nibViewSize.width) * _screenSize.width,
                                    (nibPoint.y / _nibViewSize.height) * _screenSize.height);
    return resultPos;
}

- (CGPoint) screenPointFromTopLeftOfNibRect:(CGRect)nibRect
{
    CGPoint nibPoint = nibRect.origin;
    CGPoint result = [self screenPointFromNibPoint:nibPoint];
    return result;
}

- (CGPoint) screenPointFromTopRightOfNibRect:(CGRect)nibRect
{
    CGPoint nibPoint = CGPointMake(nibRect.origin.x + nibRect.size.width,
                                   nibRect.origin.y);
    CGPoint result = [self screenPointFromNibPoint:nibPoint];
    result.x -= nibRect.size.width;
    return result;    
}

- (CGPoint) screenPointFromBotLeftOfNibRect:(CGRect)nibRect
{
    CGPoint nibPoint = CGPointMake(nibRect.origin.x,
                                   nibRect.origin.y + nibRect.size.height);
    CGPoint result = [self screenPointFromNibPoint:nibPoint];
    result.y -= nibRect.size.height;
    return result;    
}

- (CGPoint) screenPointFromBotRightOfNibRect:(CGRect)nibRect
{
    CGPoint nibPoint = CGPointMake(nibRect.origin.x + nibRect.size.width,
                                   nibRect.origin.y + nibRect.size.height);
    CGPoint result = [self screenPointFromNibPoint:nibPoint];
    result.x -= nibRect.size.width;
    result.y -= nibRect.size.height;
    return result;    
}

- (CGPoint) screenPointFromTopCenterOfNibRect:(CGRect)nibRect
{
    CGPoint nibPoint = CGPointMake(nibRect.origin.x + (0.5f * nibRect.size.width),
                                   nibRect.origin.y);
    CGPoint result = [self screenPointFromNibPoint:nibPoint];
    result.x -= (0.5f * nibRect.size.width);
    return result;            
}

- (CGPoint) screenPointFromBotCenterOfNibRect:(CGRect)nibRect
{
    CGPoint nibPoint = CGPointMake(nibRect.origin.x + (0.5f * nibRect.size.width),
                                   nibRect.origin.y + nibRect.size.height);
    CGPoint result = [self screenPointFromNibPoint:nibPoint];
    result.x -= (0.5f * nibRect.size.width);
    result.y -= nibRect.size.height;
    return result;            
}

- (CGPoint) screenPointFromCenterOfNibRect:(CGRect)nibRect
{
    CGPoint nibPoint = CGPointMake(nibRect.origin.x + (0.5f * nibRect.size.width),
                                   nibRect.origin.y + (0.5f * nibRect.size.height));
    CGPoint result = [self screenPointFromNibPoint:nibPoint];
    result.x -= (0.5f * nibRect.size.width);
    result.y -= (0.5f * nibRect.size.height);
    return result;        
}

- (CGRect) resizeRect:(CGRect)sourceRect byFactor:(float)resizeFactor
{
    CGPoint center = CGPointMake(sourceRect.origin.x + (0.5f * sourceRect.size.width),
                                 sourceRect.origin.y + (0.5f * sourceRect.size.height));
    CGSize newSize = CGSizeMake(sourceRect.size.width * resizeFactor,
                                sourceRect.size.height * resizeFactor);
    CGPoint newOrigin = CGPointMake(center.x - (0.5f * newSize.width),
                                    center.y - (0.5f * newSize.height));
    CGRect result = CGRectMake(newOrigin.x, newOrigin.y, newSize.width, newSize.height);
    return result;
}

- (CGAffineTransform) transformFromScreenPoint:(CGPoint)point
{
    CGAffineTransform result = CGAffineTransformTranslate(CGAffineTransformIdentity, 
                                                          (point.x * self.view.bounds.size.width),
                                                          (point.y* self.view.bounds.size.height));
    return result;
}

- (void) subMenu:(UIViewController*)subController slideUpIntoView:(UIView*)subView
{
    [[SoundManager getInstance] playClip:@"BackForwardButton"];

    // unhide the clipping subview first
    subView.hidden = NO;
    
    CGRect myFrame = subController.view.frame;
    [subView addSubview:[[self frontSubMenu] view]];
    [[self frontSubMenu] viewWillAppear:YES];
    CGAffineTransform beginTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, 
                                                                  0.0f, subView.frame.size.height);
    CGAffineTransform endTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, 
                                                                0.0f, subView.frame.size.height - myFrame.size.height);
    subController.view.transform = beginTransform;
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         subController.view.transform = endTransform;
                     }
                     completion:NULL];
}

- (void) subMenu:(UIViewController*)subController slideDownFromView:(UIView*)subView
{
    [[SoundManager getInstance] playClip:@"BackForwardButton"];

    CGAffineTransform beginTransform = subController.view.transform;
    CGAffineTransform endTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, 
                                                                0.0f, subView.frame.size.height);
    subController.view.transform = beginTransform;
    [UIView animateWithDuration:0.1f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         subController.view.transform = endTransform;
                     }
                     completion:^(BOOL finished){
                         subView.hidden = YES;
                         [subController.view removeFromSuperview];
                         [subController viewDidDisappear:YES];
                     }];
}


- (void) slideSubInFromLeft
{
    [[SoundManager getInstance] playClip:@"BackForwardButton"];
    [self setMainFrontAlpha:1.0f];
    self.frontSubMenu.view.transform = [self transformFromScreenPoint:CGPointMake(-1.0f,0.0f)];
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{ 
                         self.frontSubMenu.view.transform = [self transformFromScreenPoint:CGPointZero];
                         [self setMainFrontAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         //mainView.hidden = YES;
                         [self setMainfrontHidden:YES];
                     }];
}

- (void) slideSubOutToLeft
{
    if([self frontSubMenu])
    {
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
        [self setMainfrontHidden:NO];
        [self setMainFrontAlpha:0.0f];
        self.frontSubMenu.view.transform = [self transformFromScreenPoint:CGPointZero];
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ 
                             self.frontSubMenu.view.transform = [self transformFromScreenPoint:CGPointMake(-1.0f,0.0f)];
                             [self setMainFrontAlpha:1.0f];
                         }
                         completion:^(BOOL finished){
                             [self dismissFrontSubMenuImmediate];
                         }];    
    }
}

- (void) slideSubInFromRight
{
    [[SoundManager getInstance] playClip:@"BackForwardButton"];
    [self setMainFrontAlpha:1.0f];
    self.frontSubMenu.view.transform = [self transformFromScreenPoint:CGPointMake(1.0f,0.0f)];
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{ 
                         self.frontSubMenu.view.transform = [self transformFromScreenPoint:CGPointZero];
                         [self setMainFrontAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         [self setMainfrontHidden:YES];
                     }];
}

- (void) slideSubOutToRight
{
    [[SoundManager getInstance] playClip:@"BackForwardButton"];
    if([self frontSubMenu])
    {
        [self setMainfrontHidden:NO];
        [self setMainFrontAlpha:0.0f];
        self.frontSubMenu.view.transform = [self transformFromScreenPoint:CGPointZero];
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ 
                             self.frontSubMenu.view.transform = [self transformFromScreenPoint:CGPointMake(1.0f,0.0f)];
                             [self setMainFrontAlpha:1.0f];
                         }
                         completion:^(BOOL finished){
                             [self dismissFrontSubMenuImmediate];
                         }];    
    }
}

- (void) setMainFrontAlpha:(float)alpha
{
    for(UIView* cur in _mainFrontviews)
    {
        cur.alpha = alpha;
    }
}

- (void) setMainfrontHidden:(BOOL)hidden
{
    for(UIView* cur in _mainFrontviews)
    {
        cur.hidden = hidden;
    }
}

#pragma mark - navigation

- (void) dismissFrontSubMenuImmediate
{
    if([self.frontSubMenu presentedViewController])
    {
        [self.frontSubMenu.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    [self.frontSubMenu.view removeFromSuperview];
    [self.frontSubMenu viewDidDisappear:NO];
    self.frontSubMenu = nil;
}

- (void) dismissFrontSubMenuFromView:(UIView*)subView
{
    if([self frontSubMenu])
    {
        if(subView)
        {
            if([self.frontSubMenu presentedViewController])
            {
                [self.frontSubMenu.presentedViewController dismissViewControllerAnimated:NO completion:nil];
            }
            [self subMenu:[self frontSubMenu] slideDownFromView:subView];
            self.frontSubMenu = nil;
        }
        else
        {
            [self dismissFrontSubMenuImmediate];
        }
    }
}

- (void) dismissFrontSubMenuAnimated:(BOOL)animated
{
    if([self frontSubMenu])
    {
        if(animated)
        {
            // dismissal of floating sub menus
            UIView* subView = nil;
            if([self.frontSubMenu isMemberOfClass:[GameModeMenu class]])
            {
                subView = playSubView;
            }
            else if([self.frontSubMenu isMemberOfClass:[SettingsMenu class]])
            {
                subView = settingsSubview;
            }
            [self dismissFrontSubMenuFromView:subView];
        }
        else
        {
            [self dismissFrontSubMenuImmediate];
        }
    }
}

- (BOOL) toggleFrontSubMenuForClass:(Class)nextSubMenuClass
{
    BOOL shouldOpenSubMenu = YES;
    if([self frontSubMenu])
    {
        // if current frontSubMenu is already the submenu we want to show, don't show it after dismissal
        if([[self frontSubMenu] isMemberOfClass:nextSubMenuClass])
        {
            shouldOpenSubMenu = NO;
        }
    }
    
    [self dismissFrontSubMenuAnimated:YES];
    
    return shouldOpenSubMenu;
}



#pragma mark - button actions


- (void) newGame
{
    BOOL shouldOpenSubMenu = [self toggleFrontSubMenuForClass:[StoreMenu class]];
    if(shouldOpenSubMenu)
    {
        RouteSelect* controller = [[RouteSelect alloc] initWithNibName:@"RouteSelect" bundle:nil];
        controller.delegate = self;
        controller.view.frame = self.view.bounds;
        self.frontSubMenu = controller;
        [controller release];

        [rootView addSubview:[[self frontSubMenu] view]];
        [[self frontSubMenu] viewWillAppear:YES];
        [self slideSubInFromRight];
    }
}

- (void) tourneyGame
{
    // NOTE: this loadingScreen delay is important because this
    // funciton gets called from the nextpeerDashboardWillAppear callback
    // which could get called immediately by the launchDashboard in 
    // MainMenu viewWillAppear. And if there's no delay, it would immediately
    // push the gameViewController causing main menu to not unregister
    // the observer for dashboardWillAppear, and that will cause gameViewController
    // to be launched twice (will crash at the end of the first tourney game)
    
    // show loading screen and launch nextpeer dashboard
    loadingScreen.hidden = NO;
    loadingScreen.alpha = 0.0f;
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{ 
                         loadingScreen.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                         [[LevelManager getInstance] selectEnvNamed:@"Tourney" level:0];
                         [LevelManager getInstance].tourneyGameTime = 120.0f;
                         
                         // unload frontend images
                         [[MenuResManager getInstance] unloadFrontendImages];
                         
                         // load game
                         GameViewController* controller = [[GameViewController alloc] init];
                         [[AppNavController getInstance] pushViewController:controller animated:NO];
                         [controller release];   
                     }];
}


- (IBAction) buttonPlayPressed:(id)sender
{
    // Go straight to campagin;
    // Tourney mode disabled for now until we have Infinite mode
    [self dismissAndGoToGameMode:GAMEMODE_CAMPAIGN];
/*
    BOOL shouldOpenSubMenu = [self toggleFrontSubMenuForClass:[GameModeMenu class]];
    if(shouldOpenSubMenu)
    {
      NSString* flyerId = [_flyerIdsArray objectAtIndex:_selectedFlyerIndex];
        if(![[PlayerInventory getInstance] doesHangarHaveFlyer:flyerId])
        {
            // show alert if not yet purchased
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pogwing" 
                                                            message:@"Purchase this flyer to use it in the game"
                                                           delegate:nil 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];                    
        }
        else
        {
            GameModeMenu* controller = [[GameModeMenu alloc] initWithNibName:@"GameModeMenu" bundle:nil];
            controller.delegate = self;
            self.frontSubMenu = controller;
            [controller release];
            
            [self subMenu:[self frontSubMenu] slideUpIntoView:playSubView];
        }
    }
 */
}


- (IBAction) settingsButtonPressed:(id)sender
{
    BOOL shouldOpenSettingsMenu = [self toggleFrontSubMenuForClass:[SettingsMenu class]];
    if(shouldOpenSettingsMenu)
    {
        SettingsMenu* controller = [[SettingsMenu alloc] initWithNibName:@"SettingsMenu" bundle:nil];
        controller.delegate = self;
        self.frontSubMenu = controller;
        [controller release];

        [self subMenu:[self frontSubMenu] slideUpIntoView:settingsSubview];
    }
}



- (IBAction) buttonStorePressed:(id)sender
{
    BOOL shouldOpenSubMenu = [self toggleFrontSubMenuForClass:[StoreMenu class]];
    if(shouldOpenSubMenu)
    {
        [[PogAnalytics getInstance] logStoreFromMainMenu];
        StoreMenu* controller = [[StoreMenu alloc] initWithGetMoreCoins:NO];
        [[AppNavController getInstance] pushFromLeftViewController:controller animated:YES];
        [controller release];
    }
}

- (IBAction)soundButtonPressed:(id)sender
{
    [[SoundManager getInstance] toggleSound];
    [self setupSoundButtons];    
}

- (IBAction)leftFlyerPressed:(id)sender 
{
    if(0 < _currentPage)
    {
        unsigned int newPage = _currentPage - 1;
        [self changeToPage:newPage];
    }
}

- (IBAction)rightFlyerPressed:(id)sender 
{
    if((FLYERSELECT_PAGES_NUM -1) > _currentPage)
    {
        unsigned int newPage = _currentPage + 1;
        [self changeToPage:newPage];
    }
}

- (IBAction)debugButtonPressed:(id)sender
{
#if defined(DEBUG)
    DebugMenu* controller = [[DebugMenu alloc] initWithNibName:@"DebugMenu" bundle:nil];
    [[AppNavController getInstance] pushViewController:controller animated:YES];
    [controller release];
#endif
}

- (IBAction)restorePurchasePressed:(id)sender {
    [[SoundManager getInstance] playClip:@"ButtonPressed"];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    hud.labelText = @"Restoring purchases...";

    [[ProductManager getInstance] restorePurchases];
}

- (void) productManagerRestoreFinished:(NSNotification*)note {
    [MBProgressHUD hideHUDForView:self.view.window animated:YES];
}

#pragma mark - SettingsMenuDelegate
- (void) handleButtonLeaderboards
{
    // dismiss settings menu before bringing out the Goals menu
    [self dismissFrontSubMenuAnimated:YES];

    [[PogAnalytics getInstance] logStatsFromMainMenu];
    StatsController* controller = [[StatsController alloc] initWithNibName:@"StatsController" bundle:nil];
    [[AppNavController getInstance] pushFromRightViewController:controller animated:YES];
    [controller release];
}


- (void) handleButtonGoals
{
    // dismiss settings menu before bringing out the Goals menu
    [self dismissFrontSubMenuAnimated:YES];

    [[PogAnalytics getInstance] logGoalsFromMainMenu];
    GoalsMenu* controller = [[GoalsMenu alloc] initToGimmie:NO];
    [[AppNavController getInstance] pushFromRightViewController:controller animated:YES];
    [controller release];  
}

- (void) handleButtonCredits
{
    // dismiss settings menu before bringing out the Goals menu
    [self dismissFrontSubMenuAnimated:YES];
    
    Credits* controller = [[Credits alloc] initWithNibName:[CurryAppDelegate getXibNameFor:@"Credits"] bundle:nil];
    [[AppNavController getInstance] pushFromRightViewController:controller animated:YES];
    [controller release];  
}

- (void) handleMore
{
    // dismiss settings menu before bringing out the Goals menu
    [self dismissFrontSubMenuAnimated:YES];
    
    [[PogAnalytics getInstance] logMoreFromMainMenu];
    MoreMenu* controller = [[MoreMenu alloc] initWithNibName:@"MoreMenu" bundle:nil];
    [[AppNavController getInstance] pushFromRightViewController:controller animated:YES];
    [controller release];
    
    /*
    YouTubeView* movieView = [[YouTubeView alloc] initWithFrame:CGRectMake(20.0f, 20.0f, 240.0f, 180.0f)];
    [self.view addSubview:movieView];
    [movieView loadYouTubeURLString:@"http://www.youtube.com/embed/V9ERbxT3hwU"];
*/
//    NSString *channelLink = @"http://www.youtube.com/user/Geolopigs/videos";  
//    NSString* videoId = @"V9ERbxT3hwU"; 
//    NSString* youtubeLink = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", videoId];
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:youtubeLink]];  
}

- (void) handleFacebook
{
    NSString *peterpogFacebookLink = @"http://m.facebook.com/pages/PeterPog/175696365845047";  
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:peterpogFacebookLink]];  
}

#pragma mark - GameModeMenuDelegate
- (void) dismissAndGoToGameMode:(GameMode)selectedGameMode
{
    [self dismissFrontSubMenuAnimated:YES];
    
    NSString* flyerId = [_flyerIdsArray objectAtIndex:_selectedFlyerIndex];
    if(![[PlayerInventory getInstance] doesHangarHaveFlyer:flyerId])
    {
        // show alert if not yet purchased
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pogwing" 
                                                        message:@"Purchase this flyer to use it in the game"
                                                       delegate:nil 
                                              cancelButtonTitle:@"Ok" 
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];                    
    }
    else
    {        
        // go ahead and commit selected flyerType to GameManager
        [[GameManager getInstance] setFlyerId:flyerId];

        switch(selectedGameMode)
        {
            case GAMEMODE_CAMPAIGN:
                [self newGame];
                break;
                
            case GAMEMODE_TIMEBASED:
                // play button
                [[SoundManager getInstance] playClip:@"ButtonPressed"];
                if([[StatsManager getInstance] hasCompletedTutorialTourney])
                {
//                    [Nextpeer launchDashboard];
                    [self tourneyGame];
                }
                else
                {
                    // show tutorial
                    TutorialTourney* controller = [[TutorialTourney alloc] initGuided:YES];
                    [[AppNavController getInstance] pushViewController:controller animated:YES];
                    [controller release];   
                }
                break;
                
            default:
                // do nothing
                break;
        }
    }
}

#pragma mark - StoreMenuDelegate
- (void) dismissStoreMenu
{
    [self slideSubOutToLeft];
}

#pragma mark - RouteSelectDelegate
- (void) dismissRouteSelectAnimated:(BOOL)animated
{
    if(animated)
    {
        [self slideSubOutToRight];
    }
    else
    {
        [self dismissFrontSubMenuAnimated:NO];
    }
}

#pragma mark - ScrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    // to avoid conflicts between the scrollView delegate and page-control,
    // only process delegate when the pageControlUsed boolean is not set
    if((!_pageControlUsed) && (!_allowAccelScroll))
    {
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = flyerSelectScrollView.frame.size.width;
        int page = floor((flyerSelectScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
        [self gotoPage:page animated:NO];
    }
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)sender
{
    _pageControlUsed = NO;
    _allowAccelScroll = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
    _pageControlUsed = NO; 
    [self settleOnPage:_currentPage];
    _allowAccelScroll = YES;
    [[SoundManager getInstance] playClip:@"BackForwardButton"];
}

#pragma mark - nextpeer
- (void) nextpeerDashboardWillAppear:(NSNotification*)note
{
    if(!_shouldLaunchTourneyWhenViewLoaded)
    {
        // only respond to this callback when main menu isn't appearing right after
        // app was launched from openURL
        [self tourneyGame];
    }
}


#pragma mark - AppEventDelegate
- (void) appWillResignActive
{
    // do nothing
}

- (void) appDidBecomeActive
{
	// do nothing
}

- (void) appDidEnterBackground
{
    BOOL dismiss = YES;
    if(([self frontSubMenu]) &&
       ([self.frontSubMenu isMemberOfClass:[RouteSelect class]]))
    {
        // don't dismiss RouteSelect if it has already started showing intro story
        // because when we come back from background, the NSTimer started
        // for story will kick in and launch GameViewController
        RouteSelect* routeSelect = (RouteSelect*)[self frontSubMenu];
        if([routeSelect storyStarted])
        {
            dismiss = NO;
        }
    }

    if(dismiss)
    {
        [self dismissFrontSubMenuAnimated:NO];
    }
}

- (void) appWillEnterForeground
{
    BOOL reset = YES;

    if(([self frontSubMenu]) &&
       ([self.frontSubMenu isMemberOfClass:[RouteSelect class]]))
    {
        // don't dismiss RouteSelect if it has already started showing intro story
        // because when we come back from background, the NSTimer started
        // for story will kick in and launch GameViewController
        RouteSelect* routeSelect = (RouteSelect*)[self frontSubMenu];
        if([routeSelect storyStarted])
        {
            reset = NO;
        }
    }
    if(reset)
    {
        [self resetButtonStates];
    }
}

- (void) abortToRootViewControllerNow
{
    [[AppNavController getInstance] popToRootViewControllerAnimated:NO];
}

#pragma mark - MenuResDelegate
- (void) didUnloadFrontendImages
{
    if(backgroundImage)
    {
        backgroundImage.image = nil;
    }
    if(playButtonImage)
    {
        playButtonImage.image = nil;
    }
    if(loadingImageView)
    {
        loadingImageView.image = nil;
    }
    for(UIImageView* cur in _flyerSelectPages)
    {
        [cur setImage:nil];
    }
}

- (void) didUnloadIngameImages
{
    // do nothing
}

#pragma mark - GameCenterManagerAuthenticationDelegate
- (void) showAuthenticationDialog:(UIViewController *)authViewController {
    [self presentViewController:authViewController animated:YES completion:nil];
}

- (void) didSucceedAuthentication {
    // do nothing
}

#pragma mark - ADBannerViewDelegate
- (void) bannerViewDidLoadAd:(ADBannerView *)banner {
    [self layoutADBannerAnimated:YES];
}

- (void) bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [self layoutADBannerAnimated:YES];
}

- (BOOL) bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    [[SoundManager getInstance] pauseMusic];
    return YES;
}

- (void) bannerViewActionDidFinish:(ADBannerView *)banner {
    [[SoundManager getInstance] resumeMusic];
}
@end
