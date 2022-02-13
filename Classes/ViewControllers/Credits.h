//
//  Credits.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEventDelegate.h"

@interface Credits : UIViewController<AppEventDelegate>
{
    IBOutlet UIView *_contentView;
    IBOutlet UILabel *_version;
}
- (IBAction)buttonClosePressed:(id)sender;

@end
