//
//  FlyerSelectPage.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/23/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlyerSelectPage : UIViewController<UIAlertViewDelegate>
{
    IBOutlet UIView *backScrim;
    IBOutlet UIView *border;
    
    // screen components
    IBOutlet UILabel *_titleLabel;
    IBOutlet UILabel *_descLabel;
    IBOutlet UIButton *_buyButton;
    IBOutlet UIButton *_unlockButton;
    IBOutlet UIImageView *_imageView;
    IBOutlet UIView *_infoPane;
    IBOutlet UIActivityIndicatorView *_loadingIndicator;
    IBOutlet UIView *_buttonsView;
    IBOutlet UIView *_gimmieTipView;
    IBOutlet UIView *_gimmieTipBorder;
    IBOutlet UILabel *_gimmieTipLabel;
    
    // flyer info
    NSString* _flyerProductId;
    BOOL _wasUnlockPressed;
    
    // state
    BOOL _isInfoPaneCollapsed;
    CGPoint _infoPaneOrigin;    // origin from nib file; saved off in viewDidLoad;
}
@property (nonatomic,retain) UIImage* image;
@property (nonatomic,retain) NSString* flyerProductId;

- (id) initWithFlyerProductId:(NSString*)productId;

- (void) loadFlyerProductInfoSilent:(BOOL)silentFail;
- (void) hideFlyerProductInfo;

- (void) alignImageRightAnimated:(BOOL)animated;
- (void) alignImageLeftAnimated:(BOOL)animated;
- (void) alignImageCenterAnimated:(BOOL)animated;

- (IBAction)buyButtonPressed:(id)sender;
- (IBAction)unlockButtonPressed:(id)sender; // this only shows up if app fails to load product info
- (IBAction)descPressed:(id)sender;

@end
