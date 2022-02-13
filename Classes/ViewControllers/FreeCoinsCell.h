//
//  FreeCoinsCell.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FREECOINSCELL_HEIGHT (60.0f)
#define FREECOINSCELL_DISCLOSEDHEIGHT (100.0f)

@interface FreeCoinsCell : UITableViewCell
{
    // container views
    UIView* _itemContainerView;
    UIView* _detailedView;

    // components
    UIImageView* _iconImageView;
    UILabel* _titleLabel;
    UILabel* _priceLabel;
    UILabel* _descLabel;
    UIButton* _buttonBuy;
    UIImageView* _equippedStamp;
    
    // item
    NSString* _itemCategory;
    NSString* _itemIdentifier;
    unsigned int _itemPrice;
    UIAlertView* _buyConfirm;
    unsigned int _numLevels;
    unsigned int _curLevel;
}
@property (nonatomic,retain) UILabel* titleLabel;
@property (nonatomic,retain) UILabel* priceLabel;
@property (nonatomic,retain) UILabel* descLabel;
@property (nonatomic,retain) NSString* itemCategory;
@property (nonatomic,retain) NSString* itemIdentifier;
@property (nonatomic,assign) unsigned int itemPrice;
@property (nonatomic,retain) UIAlertView* buyConfirm;
@property (nonatomic,assign) unsigned int numLevels;
@property (nonatomic,assign) unsigned int curLevel;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void) setPriceWithAmount:(unsigned int)amount;
- (void) refreshCellState;

- (void) loadIconImage:(NSString *)imageName;
- (void) showEquippedStamp;
- (void) hideEquippedStamp;

- (void) setButtonText:(NSString*)text;

- (void)buttonBuyPressed:(id)sender;

@end
