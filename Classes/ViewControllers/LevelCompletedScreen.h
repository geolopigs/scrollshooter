//
//  LevelCompletedScreen.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/19/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LevelCompletedScreen;

@interface LevelCompletedScreen : UIViewController
{
    IBOutlet UILabel* cargoNum;
    IBOutlet UILabel *_pogcoinsLabel;
    IBOutlet UILabel* gradeLabel;
    IBOutlet UILabel* gradeLabelFade;
    IBOutlet UILabel* currentScore;
    IBOutlet UIView *backScrim;
    IBOutlet UIView *border;
    
	NSTimeInterval prevTick;
    unsigned int screenState;
}


@end
