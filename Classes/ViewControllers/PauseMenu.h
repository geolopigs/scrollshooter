//
//  PauseMenu.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/9/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PauseMenu;

// view-controller that presents the PauseMenu modally needs to adopt this so that it can dismiss the modal menu when user quits pause menu
@protocol PauseMenuDelegate <NSObject>
- (void) quitGameFromPauseMenu:(PauseMenu*)sender;
- (void) restartLevelFromPauseMenu:(PauseMenu*)sender;
- (void) resumeGameFromPauseMenu:(PauseMenu*)sender;
- (void) showTutorialFromPauseMenu:(PauseMenu*)sender;
@end

@interface PauseMenu : UIViewController
{
    IBOutlet UIButton* pauseButton;
    IBOutlet UIButton* soundButton;
    IBOutlet UIImageView* soundButtonOn;
    IBOutlet UIImageView* soundButtonOff;
    
    NSObject<PauseMenuDelegate>* delegate;
}
@property (nonatomic,retain) UIButton* pauseButton;
@property (nonatomic,retain) NSObject<PauseMenuDelegate>* delegate;

- (IBAction)resumeGame:(id)sender;
- (IBAction)quitGame:(id)sender;
- (IBAction)restartLevel:(id)sender;
- (IBAction) soundButtonPressed:(id)sender;
- (IBAction)helpButtonPressed:(id)sender;

@end


