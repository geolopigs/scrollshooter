//
//  PogcoinsCell.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/12/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define GETMORECOINS_HEADER_HEIGHT (25.0f)
#define POGCOINSCELL_HEIGHT (60.0f)
#define POGCOINSCELL_DISCLOSEDHEIGHT (100.0f)

@interface PogcoinsCell : UITableViewCell
{
    // container views
    UIView* _headerView;
    UIView* _itemContainerView;
    UIView* _detailedView;
    
    // components
    UIImageView* _iconImageView;
    UILabel* _titleLabel;
    UILabel* _descLabel;
    UIActivityIndicatorView* _loadingIndicator;
    UILabel* _priceLabel;
    UIButton* _buttonBuy;
    UIImageView* _indicatorImageView;
    BOOL _isPurchasable;
    BOOL _isPurchased;
    
    // product
    NSString* _productIdentifier;
}
@property (nonatomic,retain) UILabel* titleLabel;
@property (nonatomic,retain) UILabel* descLabel;
@property (nonatomic,retain) UILabel* priceLabel;
@property (nonatomic,retain) UIButton* buttonBuy;
@property (nonatomic,retain) UIImageView* indicatorImageView;
@property (nonatomic,retain) UIImageView* iconImageView;
@property (nonatomic,assign) BOOL isPurchasable;
@property (nonatomic,assign) BOOL isPurchased;
@property (nonatomic,retain) NSString* productIdentifier;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void) startLoading;
- (void) stopLoading;
- (void) showIndicator;
- (void) showExpandedIndicator;
- (void) hideIndicator;
- (void) setHeaderTitle:(NSString*)text;
- (void) setRegularTitle:(NSString*)text;
- (void) loadIconImage:(NSString*)imageName;
- (void) clearIconImage;
- (void) useCellForItem;


- (void) useCellForHeader;
@end
