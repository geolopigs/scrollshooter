//
//  MainMenu.h
//  CurryFlyer
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "AppEventDelegate.h"
#import "MenuResManager.h"
#import "SettingsMenuDelegate.h"
#import "GameModeMenuDelegate.h"
#import "StoreMenuDelegate.h"
#import "RouteSelectDelegate.h"

@class PogUITextLabel;
@class PogUIPageControlDots;
@interface MainMenu : UIViewController<AppEventDelegate,
                                        MenuResDelegate,
                                        SettingsMenuDelegate,
                                        GameModeMenuDelegate,
                                        StoreMenuDelegate,
                                        RouteSelectDelegate,
                                        UIScrollViewDelegate>
{
    IBOutlet UIView *rootView;
    IBOutlet UIView *loadingScreen;
    IBOutlet UIView *mainView;
    NSMutableArray* _mainFrontviews;     // front items in main menu; hidden when slide-in submenus appear
    IBOutlet UIImageView *loadingImageView;
    IBOutlet UILabel* versionLabel;
    CGAffineTransform balloonInit;
    
    // flyer selection
    IBOutlet UIScrollView *flyerSelectScrollView;
    IBOutlet PogUIPageControlDots *_flyerSelectPageDots;
    NSMutableArray* _flyerSelectPages;
    unsigned int _currentPage;
    int _prevSettledPage;
    unsigned int _selectedFlyerIndex;
    BOOL _pageControlUsed;
    NSArray* _flyerIdsArray;
    
    // settings button and sub-menu
    IBOutlet UIImageView *settingsButtonImage;
    IBOutlet UIButton *settingsButton;
    IBOutlet UIView *settingsSubview;

    // play button and sub-menu
    IBOutlet UIImageView *playButtonImage;
    IBOutlet UIButton *buttonPlay;
    IBOutlet UIView *playSubView;
    
    IBOutlet UIImageView *buttonStoreImage;
    IBOutlet UIButton *buttonStore;
    IBOutlet PogUITextLabel *restorePurchaseLabel;
    IBOutlet UIView *restorePurchaseContainer;


    // sound on/off button
    IBOutlet UIView *soundToggleView;
    IBOutlet UIImageView *soundOnImage;
    IBOutlet UIImageView *soundOffImage;
    IBOutlet UIButton *buttonSound;
    
    // parameters for screen layout
    CGSize _screenSize;
    CGSize _nibViewSize;
    
    // runtime vars
    UIViewController* _frontSubMenu;
    UIAccelerationValue _accelX;
    UIAccelerationValue _accelY;
    UIAccelerationValue _accelZ;
    UIAccelerationValue _prevX;
    UIAccelerationValue _prevY;
    UIAccelerationValue _prevZ;
    BOOL _accelSettled;
    BOOL _allowAccelScroll;
    
    // nextpeer
    BOOL _shouldLaunchTourneyWhenViewLoaded;
    BOOL _nextpeerRegistered;
    BOOL _shouldLaunchNextpeerWhenAppear;   // special flag to launch tourney coming back from tutorial
    
    IBOutlet UIImageView *backgroundImage;
}
@property (assign) IBOutlet UIView* bottomButtonsView;
@property (nonatomic,retain) UIViewController* frontSubMenu;
@property (nonatomic,retain) NSMutableArray* mainFrontviews;
@property (nonatomic,retain) NSMutableArray* flyerSelectPages;
@property (nonatomic,assign) BOOL shouldLaunchTourneyWhenViewLoaded;
@property (nonatomic,assign) BOOL shouldLaunchNextpeerWhenAppear;


- (void)changeToPage:(unsigned int)pageIndex;
- (void) registerToObserveNextpeerDashboardWillAppear;
- (BOOL) isShowingStory;

- (IBAction) buttonPlayPressed:(id)sender;
- (IBAction) settingsButtonPressed:(id)sender;
- (IBAction) buttonStorePressed:(id)sender;
- (IBAction) debugButtonPressed:(id)sender;
- (IBAction) soundButtonPressed:(id)sender;
- (IBAction)leftFlyerPressed:(id)sender;
- (IBAction)rightFlyerPressed:(id)sender;
- (IBAction) restorePurchasePressed:(id)sender;
@end
