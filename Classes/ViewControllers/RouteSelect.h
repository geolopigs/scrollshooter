//
//  RouteSelect.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/15/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEventDelegate.h"
#import "RouteSelectPage.h"
#import "MenuResManager.h"
#import "RouteSelectDelegate.h"

@interface RouteSelect : UIViewController<RouteSelectPageDelegate,MenuResDelegate>
{
    NSObject<RouteSelectDelegate>* _delegate;
    
    IBOutlet UIView* loadingScreen;
    IBOutlet UIButton* rightArrow;
    IBOutlet UIButton* leftArrow;
    IBOutlet UIScrollView* routeSelectPageView;
    CGAffineTransform balloonInit;
    UIView* _storyView;
    UIView* _storyPanSubview;
    UIButton* _storySkipButton;
    BOOL _storySkipped;
    BOOL _storyStarted;
    
    NSMutableArray* routeInfos;
    NSMutableArray* routePages;
    unsigned int numPages;
    unsigned int currentPage;
    
    // for fonts
    IBOutlet UIImageView *loadingImageView;
    
    // border
    IBOutlet UIView *backScrim;
    IBOutlet UIView *border;
    
}
@property (assign) IBOutlet UIView* contentView;
@property (nonatomic,retain) NSObject<RouteSelectDelegate>* delegate;
@property (nonatomic,retain) NSMutableArray* routeInfos;
@property (nonatomic,retain) NSMutableArray* routePages;
@property (nonatomic,assign) BOOL storyStarted;

- (IBAction)dismissButtonPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;
- (IBAction)nextPage:(id)sender;

@end
