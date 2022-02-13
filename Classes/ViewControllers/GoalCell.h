//
//  GoalCell.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/7/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GoalCell : UITableViewCell
{
    UILabel*        _progressLabel;
    
    UIView*         _gimmieView;
    UILabel*        _gimmiePointsLabel;
    UIImageView*    _gimmieIcon;
}
@property (nonatomic,retain) UILabel* progressLabel;

- (void) selectedForAchievementId:(NSString*)achievementId;
- (void) deselectedForAchievementId:(NSString*)achievementId;
- (void) showGimmiePoints:(unsigned int)points;
- (void) hideGimmiePoints;

@end
