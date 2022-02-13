//
//  TourneyMessageView.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/15/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TourneyMessageView : UIView
{
    UIView* _backScrim;
    UILabel* _message;
    UIImageView* _icon;
}

- (void) setMessageText:(NSString*)text;
- (void) setIconImage:(UIImage*)image;
@end
