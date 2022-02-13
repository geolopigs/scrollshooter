//
//  StatsCell.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define STATSCELL_HEIGHT (25.0f)

@interface StatsCell : UITableViewCell
{
    UILabel* _title;
    UILabel* _value;
    UIImageView* _icon;
}
@property (nonatomic,retain) UILabel* title;
@property (nonatomic,retain) UILabel* value;
@property (nonatomic,retain) UIImageView* icon;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier cellSize:(CGSize)cellSize;
- (void) setTitleText:(NSString*)text;
- (void) setValueWithInt:(unsigned int)number;
- (void) setValueWithTime:(NSTimeInterval)time;
- (void) setValueWithMultiplier:(unsigned int)number;
- (void) showCoinIcon;
- (void) hideCoinIcon;

@end
