//
//  StatsController.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEventDelegate.h"
#import "GameCenterManagerDelegates.h"

@interface StatsController : UIViewController<AppEventDelegate,UITableViewDataSource,UITableViewDelegate,
                                              GameCenterManagerAuthenticationDelegate>
{
    IBOutlet UIView *_contentView;
    IBOutlet UIView *border;
    IBOutlet UIButton *_buttonGameCenter;
    IBOutlet UITableView *_tableView;
    
    // data
    NSArray* _titleNames;
}

- (IBAction)buttonBackPressed:(id)sender;
- (IBAction)buttonGameCenterPressed:(id)sender;
@end
