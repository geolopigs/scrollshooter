//
//  RouteButton.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/15/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StatsManager.h"

enum ROUTEBUTTON_STATES
{
    ROUTEBUTTON_STATE_NONE = 0,
    ROUTEBUTTON_STATE_SELECTABLE,
    ROUTEBUTTON_STATE_FORSALE
};

@interface RouteButton : UIViewController
{
    IBOutlet UILabel* routeNameLabel;
    IBOutlet UIView* routeSignView;
    IBOutlet UIImageView *routeUnlockedImage;
    IBOutlet UIImageView* constructionSign;
    IBOutlet UILabel* businessPendingSign;
    IBOutlet UILabel* scoreGradeLabel;
    IBOutlet UIImageView *iconLocked;
    float routeNameFontSize;
    float serviceLabelFontSize;
    float businessPendingFontSize;
    
    NSString* envName;
    unsigned int levelIndex;
    NSString* serviceName;
    NSString* routeName;
    unsigned int selectableState;
    BOOL underConstruction;
    float rotation;
    enum ScoreGrades scoreGrade;
}
@property (nonatomic,retain) NSString* envName;
@property (nonatomic,assign) unsigned int levelIndex;
@property (nonatomic,retain) NSString* serviceName;
@property (nonatomic,retain) NSString* routeName;
@property (nonatomic,assign) unsigned int selectableState;
@property (nonatomic,assign) BOOL underConstruction;
@property (nonatomic,assign) float rotation;
@property (nonatomic,assign) enum ScoreGrades scoreGrade;
@property (nonatomic,retain) UIImageView* iconLocked;
@property (nonatomic,retain) UIImageView* routeUnlockedImage;

@property (retain, nonatomic) IBOutlet UIImageView *routeSign;

- (void) updateLabels;
@end
