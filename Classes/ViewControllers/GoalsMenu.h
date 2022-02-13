//
//  GoalsMenu.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/4/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameCenterManagerDelegates.h"
#import "AppEventDelegate.h"

@interface GoalsMenu : UIViewController<UITableViewDataSource,UITableViewDelegate,
                                        GameCenterManagerAuthenticationDelegate,
                                        AppEventDelegate>
{
    IBOutlet UIView *_contentView;
    // iPad border
    IBOutlet UIView *backScrim;
    IBOutlet UIView *border;
    
    IBOutlet UIButton *buttonGameCenter;

    IBOutlet UITableView *_tableView;
    IBOutlet UITableViewCell* _goalCell;
    
    // table selection
    unsigned int _selectedRow;
    
    BOOL _initShowGimmie;
}
@property (nonatomic,retain) UITableView* tableView;
@property (nonatomic,retain) UITableViewCell* goalCell;
@property (nonatomic,assign) BOOL initShowGimmie;

- (id) initToGimmie:(BOOL)showGimmie;

- (IBAction)buttonClosePressed:(id)sender;
- (IBAction)buttonGameCenterAchievementsPressed:(id)sender;
@end
