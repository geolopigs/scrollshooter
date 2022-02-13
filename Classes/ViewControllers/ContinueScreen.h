//
//  ContinueScreen.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ContinueScreen;

@protocol ContinueScreenDelegate <NSObject>
- (void) continueGame:(ContinueScreen*)sender;
- (void) endGame:(ContinueScreen*)sender;
@end

@interface ContinueScreen : UIViewController
{
    IBOutlet UILabel* continuesLabel;
    IBOutlet UILabel* fadeOutLabel;
    IBOutlet UILabel *titleLabel;
    IBOutlet UIView *backScrim;    
    IBOutlet UIView *border;
    
    NSObject<ContinueScreenDelegate>* delegate;
    
    unsigned int continuesRemaining;
}
@property (nonatomic,retain) NSObject<ContinueScreenDelegate>* delegate;
- (id) initWithContinuesRemaining:(unsigned int)remaining;
- (IBAction) continueGamePressed:(id)sender;
- (IBAction) endGamePressed:(id)sender;
@end
