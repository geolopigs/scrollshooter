//
//  StatsCell.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/10/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "StatsCell.h"
#import "StoreManager.h"
#import "PogUIUtility.h"

@implementation StatsCell
@synthesize title = _title;
@synthesize value = _value;
@synthesize icon = _icon;

#pragma mark - init / shutdown

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier cellSize:(CGSize)cellSize
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        
        // title
        CGFloat cellWidth = cellSize.width;
        CGFloat cellHeight = STATSCELL_HEIGHT; 
        CGFloat titleWidth = 0.55f * cellWidth;
        CGFloat titleHeight = cellHeight;
        CGFloat titleX = 0.05f * cellWidth;
        _title = [[UILabel alloc] initWithFrame:CGRectMake(titleX, 0.0f,
                                                           titleWidth, titleHeight)];
        [_title setBackgroundColor:[UIColor clearColor]];
        [_title setTextColor:[UIColor whiteColor]];
        [_title setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
        [self.contentView addSubview:_title];

        // icon
        CGFloat iconWidth = 0.9f * cellHeight;
        CGFloat iconHeight = 0.9f * cellHeight;
        CGFloat iconX = cellWidth - iconWidth - (0.03f * cellWidth);
        CGFloat iconY = 0.1f * cellHeight;
        _icon = [[UIImageView alloc] initWithFrame:CGRectMake(iconX, iconY, iconWidth, iconHeight)];
        [self.contentView addSubview:_icon];
        
        // value
        CGFloat valueX = titleX + titleWidth;
        CGFloat valueY = 0.0f;
        CGFloat valueWidth = cellWidth - titleWidth - iconWidth - (0.09f * cellWidth); // the 0.09 cellWidth accounts for spacings
        CGFloat valueHeight = cellHeight;
        _value = [[UILabel alloc] initWithFrame:CGRectMake(valueX, valueY, valueWidth, valueHeight)];
        [_value setTextColor:[UIColor orangeColor]];
        [_value setBackgroundColor:[UIColor clearColor]];
        [_value setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
        [_value setTextAlignment:NSTextAlignmentRight];
        [self.contentView addSubview:_value];
    }
    return self;
}

- (void) dealloc
{
    [_icon release];
    [_value release];
    [_title release];
    [super dealloc];
}

#pragma mark - accessors
- (void) setTitleText:(NSString *)text
{
    [_title setText:text];
}

- (void) setValueWithInt:(unsigned int)number
{
    // format it like pogcoins with commas every 3 digits
    NSString* formatted = [PogUIUtility commaSeparatedStringFromUnsignedInt:number]; 
    [_value setText:formatted];
}

- (void) setValueWithTime:(NSTimeInterval)time
{
    NSString* formatted = [PogUIUtility stringFromTimeInterval:time];
    [_value setText:formatted];
}

- (void) setValueWithMultiplier:(unsigned int)number
{
    NSString* formatted = [NSString stringWithFormat:@"x%d",number];
    [_value setText:formatted];
}

- (void) showCoinIcon
{
    _icon.image = [UIImage imageNamed:@"coin.png"];
}

- (void) hideCoinIcon
{
    _icon.image = nil;
}

@end
