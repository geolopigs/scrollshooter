//
//  GameModeMenu.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 12/30/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameModeMenuDelegate.h"

@interface GameModeMenu : UIViewController
{
    NSObject<GameModeMenuDelegate>* _delegate;
    
    IBOutlet UIButton *buttonNextpeerMultiplayer;
    
    // for border
    IBOutlet UIView *backScrim;
    IBOutlet UIView *border;
}
@property (nonatomic,retain) NSObject<GameModeMenuDelegate>* delegate;

- (IBAction)nextpeerMultiplayerPressed:(id)sender;
- (IBAction)campaignPressed:(id)sender;
@end
