//
//  StoreMenu.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoreMenuDelegate.h"
#import "PlayerInventoryDelegate.h"
#import "AppEventDelegate.h"

@interface StoreMenu : UIViewController<AppEventDelegate,
                                        UITableViewDataSource,
                                        UITableViewDelegate,
                                        PlayerInventoryDelegate,
                                        UIAlertViewDelegate>
{
    // delegate
    NSObject<StoreMenuDelegate>* _delegate;
    
    IBOutlet UIView *_contentView;
    IBOutlet UIView *border;
    // tableview
    IBOutlet UIView *_tableContainer;
    IBOutlet UITableView *_tableView;
    UIView* _getCoinsView;
    UIImageView* _getCoinsDiscloser;
    int _selectedRow;
    int _selectedSection;
    
    // top view
    IBOutlet UIView *_topView;
    IBOutlet UILabel *pogCoinsLabel;
    
    // in-app purchase
    BOOL _isVisbleCoinInAppSection;
    UIAlertView* _alertView;
    
}
@property (nonatomic,retain) NSObject<StoreMenuDelegate>* delegate;
@property (nonatomic,retain) UIAlertView* alertView;

- (id) initWithGetMoreCoins:(BOOL)showGetMoreCoins;

// buttons
- (IBAction) buttonBackPressed:(id)sender;

@end
