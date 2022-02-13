//
//  MoreMenu.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <iAd/ADBannerView.h>
#import "AppEventDelegate.h"
#import "GameCenterManagerDelegates.h"

@class MovieWebView;
@interface MoreMenu : UIViewController<AppEventDelegate,
                                       UITableViewDataSource,UITableViewDelegate,
                                       UIWebViewDelegate>
{
    IBOutlet UIView *_contentView;
    IBOutlet UIView *border;
    IBOutlet UITableView *_tableView;
    IBOutlet MovieWebView *_movieTopLeft;
    IBOutlet MovieWebView *_movieTopRight;
    IBOutlet MovieWebView *_movieBotLeft;
    IBOutlet UIButton *_buttonMoreVideos;
    IBOutlet UIView *_adBannerContainer;
}

- (IBAction)buttonBackPressed:(id)sender;
- (IBAction)buttonFacebookPressed:(id)sender;
- (IBAction)buttonTwitterPressed:(id)sender;
- (IBAction)buttonMoreVideosPressed:(id)sender;
@end
