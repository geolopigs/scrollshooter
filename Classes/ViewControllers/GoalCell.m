//
//  GoalCell.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/7/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "GoalCell.h"
#import "AchievementsManager.h"
#import "AchievementRegEntry.h"
#import "AchievementsData.h"
#import "MenuResManager.h"

@implementation GoalCell
@synthesize progressLabel = _progressLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        [self.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
        [self.textLabel setTextColor:[UIColor colorWithRed:0.92f green:0.56f blue:0.30f alpha:1.0f]];
        [self.textLabel setNumberOfLines:1];
        [self setSelectionStyle:UITableViewCellSelectionStyleBlue];
        
        CGRect progressLabelFrame = CGRectMake(50.0f, 30.0f, 200.0f, 10.0f);
        _progressLabel = [[UILabel alloc] initWithFrame:progressLabelFrame];
        _progressLabel.textAlignment = NSTextAlignmentRight;
        _progressLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        
        _gimmieIcon = [[UIImageView alloc] initWithFrame:CGRectMake(-3.0f, 10.0f, 30.0f, 30.0f)];
        UIImage* image = [UIImage imageNamed:@"ButtonGimmieworldMain.png"];
        [_gimmieIcon setImage:image];
        [_gimmieIcon setBackgroundColor:[UIColor clearColor]];
        _gimmiePointsLabel = [[UILabel alloc] initWithFrame:CGRectMake(18.0f, 8.0f, 30.0f, 25.0f)];
        [_gimmiePointsLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0f]];
        [_gimmiePointsLabel setTextColor:[UIColor whiteColor]];
        [_gimmiePointsLabel setBackgroundColor:[UIColor clearColor]];
        [_gimmiePointsLabel setTextAlignment:NSTextAlignmentRight];

        CGRect imageViewBounds = self.imageView.bounds;
        _gimmieView = [[UIView alloc] initWithFrame:imageViewBounds];
        [_gimmieView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|
         UIViewAutoresizingFlexibleRightMargin];
        [_gimmieView setBackgroundColor:[UIColor blueColor]];
        
        [_gimmieView addSubview:_gimmieIcon];
        [_gimmieView addSubview:_gimmiePointsLabel];
    }
    return self;
}

- (void) dealloc
{
    [_gimmiePointsLabel removeFromSuperview];
    [_gimmiePointsLabel release];
    [_gimmieIcon removeFromSuperview];
    [_gimmieIcon release];
    [_gimmieView removeFromSuperview];
    [_gimmieView release];
    [_progressLabel release];
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


- (void) selectedForAchievementId:(NSString *)achievementId
{
    AchievementRegEntry* curAchievementInfo = [[AchievementsManager getInstance].achievementsRegistry objectForKey:achievementId];
    if(curAchievementInfo)
    {
        [self.textLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0]];
        [self.textLabel setNumberOfLines:2];
        [self.detailTextLabel setTextColor:[UIColor colorWithRed:1.0f green:0.66f blue:0.40f alpha:1.0f]];
        [self.detailTextLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0f]];
        [self.detailTextLabel setNumberOfLines:3];
        NSDictionary* playerAchievements = [[AchievementsManager getInstance] getGameAchievementsData];
        AchievementsData* playerProgress = nil;
        if(playerAchievements)
        {
            playerProgress = [playerAchievements objectForKey:achievementId];
        }
        if(([curAchievementInfo targetValue] > 1) && playerProgress)
        {
            // progressive achievement, show number remaining
            NSString* progress = [NSString stringWithFormat:[curAchievementInfo progressFormat], [curAchievementInfo targetValue] - [playerProgress currentValue]];
            [self.detailTextLabel setText:progress];
        }
        else
        {
            // one shot achievement; just show the description text
            [self.detailTextLabel setText:[curAchievementInfo description]];
        }
    }
}

- (void) deselectedForAchievementId:(NSString *)achievementId
{
    AchievementRegEntry* curAchievementInfo = [[AchievementsManager getInstance].achievementsRegistry objectForKey:achievementId];
    if(curAchievementInfo)
    {
        [self.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
        [self.textLabel setNumberOfLines:1];
        [self.detailTextLabel setFont:[UIFont fontWithName:@"Helvetica" size:10.0f]];
        [self.detailTextLabel setTextColor:[UIColor colorWithRed:0.92f green:0.56f blue:0.30f alpha:0.5f]];
        [self.detailTextLabel setNumberOfLines:2];            
        [self.detailTextLabel setText:[curAchievementInfo description]];
        [self.progressLabel setText:nil];        
    }
}

- (void) showGimmiePoints:(unsigned int)points
{
    [_gimmiePointsLabel setText:[NSString stringWithFormat:@"%d",points]];
    [self.imageView addSubview:_gimmieView];  
}

- (void) hideGimmiePoints
{
    [_gimmieView removeFromSuperview];
}

@end
