//
//  StoreItemCell.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "StoreItemCell.h"
#import "PlayerInventoryIds.h"
#import "PlayerInventory.h"
#import "StoreManager.h"
#import "MenuResManager.h"
#import "PogUISlotBar.h"

@implementation StoreItemCell

#pragma mark - properties
@synthesize titleLabel = _titleLabel;
@synthesize priceLabel = _priceLabel;
@synthesize descLabel = _descLabel;
@synthesize descShortLabel = _descShortLabel;
@synthesize itemCategory = _itemCategory;
@synthesize itemIdentifier = _itemIdentifier;
@synthesize itemPrice = _itemPrice;
@synthesize buyConfirm = _buyConfirm;

- (void) setPriceWithAmount:(unsigned int)amount
{    
    if(0 == amount)
    {
        [self.priceLabel setText:@"FREE"];
    }
    else
    {
        // get formatted string
        NSString* formatted = [StoreManager pogcoinsStringForAmount:amount]; 
        [self.priceLabel setText:formatted];
    }
}

- (unsigned int) curLevel
{
    return _curLevel;
}

- (void) setCurLevel:(unsigned int)curLevel
{
    // +1 because PogUISlotBar takes number of slots to fill as param
    [_levelBar setNumFilled:(curLevel + 1)];
    
    // set the value
    _curLevel = curLevel;
}

- (unsigned int) numLevels
{
    return _numLevels;
}

- (void) setNumLevels:(unsigned int)numLevels
{
    [_levelBar setNumSlots:numLevels];
    _numLevels = numLevels;
}


#pragma mark - public methods

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        // init item entries, the actual values will be set in the table datasource as soon as
        // this cell is returned to it
        self.itemCategory = [NSString stringWithFormat:@"%@",CATEGORY_ID_UPGRADES];
        self.itemIdentifier = [NSString stringWithFormat:@"%@",UPGRADE_ID_WOODENBULLETS];
        self.itemPrice = 0;
        _curLevel = 0;
        _numLevels = 1;

        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        [self.textLabel setTextColor:[UIColor orangeColor]];

        CGFloat cellWidth = self.bounds.size.width;
        CGFloat cellHeight = STORECELL_HEIGHT; 
        CGFloat containerViewWidth = 0.93f * cellWidth;
        CGFloat containerViewHeight = 0.945f * cellHeight;
        CGFloat containerViewY = (containerViewHeight - cellHeight) * 0.5f;
        _itemContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, containerViewY,
                                                                      containerViewWidth, containerViewHeight)];
        _itemContainerView.clipsToBounds = YES;
        [_itemContainerView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.2f]];
        [self.contentView addSubview:_itemContainerView];
        
        // icon image
        CGFloat iconFrameHeight = 0.8f * cellHeight;
        CGFloat iconFrameWidth = iconFrameHeight;
        CGFloat iconY = (cellHeight - iconFrameHeight) * 0.5f;
        CGRect iconFrame = CGRectMake(0.0f, iconY,
                                      iconFrameWidth, iconFrameHeight);
        _iconImageView = [[UIImageView alloc] initWithFrame:iconFrame];
        _iconImageView.autoresizingMask = UIViewAutoresizingNone;
        [_itemContainerView addSubview:_iconImageView];

        // title
        CGFloat titleX = 1.01f * iconFrameWidth;
        CGFloat titleWidth = (0.8f * containerViewWidth) - titleX;
        CGFloat titleHeight = 0.5f * cellHeight;
        CGRect titleFrame = CGRectMake(titleX, 0.0f, titleWidth, titleHeight);
        _titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
        [_titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_titleLabel setTextColor:[UIColor orangeColor]];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        [_titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0f]];
        [_itemContainerView addSubview:_titleLabel];
        
        // inventory level bar
        CGFloat barX = 1.01f * iconFrameWidth;
        CGFloat barHeight = 0.3f * cellHeight;
        CGFloat barY = 0.6f * containerViewHeight;
        CGFloat barWidth = (0.8f * containerViewWidth) - barX;
        CGRect barFrame = CGRectMake(barX, barY, barWidth, barHeight);
        _levelBar = [[PogUISlotBar alloc] initWithFrame:barFrame];
        [_levelBar setOpaque:NO];
        [_itemContainerView insertSubview:_levelBar aboveSubview:_titleLabel];

        // price
        CGFloat priceX = 0.8f * containerViewWidth;
        CGFloat priceY = 0.0f;
        CGFloat priceWidth = 0.9f * (containerViewWidth - priceX);
        CGFloat priceHeight = 0.5f * cellHeight;
        _priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(priceX, priceY, priceWidth, priceHeight)];
        [_priceLabel setTextAlignment:NSTextAlignmentRight];
        [_priceLabel setBackgroundColor:[UIColor clearColor]];
        [_priceLabel setTextColor:[UIColor whiteColor]];
        [_priceLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0f]];
        [_itemContainerView addSubview:_priceLabel];

        // equipped stamp
        CGFloat equippedX = 0.8f * containerViewWidth;
        CGFloat equippedY = 0.0f;
        CGFloat equippedHeight = cellHeight;
        CGFloat equippedWidth = 1.28f * equippedHeight;
        _equippedStamp = [[UIImageView alloc] initWithFrame:CGRectMake(equippedX, equippedY, equippedWidth, equippedHeight)];
        [_equippedStamp setBackgroundColor:[UIColor clearColor]];
        [_equippedStamp setImage:[UIImage imageNamed:@"EquippedLabel.png"]];
        [_itemContainerView addSubview:_equippedStamp];
        [_equippedStamp setHidden:YES];
        
        // detailed view
        CGFloat detailedX = 0.0f;
        CGFloat detailedY = containerViewHeight + containerViewY;
        CGFloat detailedViewWidth = containerViewWidth;
        CGFloat detailedViewHeight = (STORECELL_DISCLOSEDHEIGHT - STORECELL_HEIGHT) * 0.95f;
        _detailedView = [[UIView alloc] initWithFrame:CGRectMake(detailedX, detailedY, 
                                                                 detailedViewWidth, detailedViewHeight)];
        [_detailedView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.4f]];
        [_detailedView setHidden:YES];
        [self.contentView addSubview:_detailedView];

        // description
        CGFloat descX = 0.05f * detailedViewWidth;
        CGFloat descY = 0.0f;
        CGFloat descWidth = 0.68f * detailedViewWidth;
        CGFloat descHeight = detailedViewHeight;
        _descLabel = [[UILabel alloc] initWithFrame:CGRectMake(descX, descY, descWidth, descHeight)];
        [_descLabel setBackgroundColor:[UIColor clearColor]];
        [_descLabel setNumberOfLines:2];
        [_descLabel setTextColor:[UIColor whiteColor]];
        [_descLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0f]];
        [_detailedView addSubview:_descLabel];
        
        // short description for items without level-bar (this gets added in show/hide LevelBar)
        CGFloat descShortX = 1.01f * iconFrameWidth;
        CGFloat descShortHeight = 0.3f * containerViewHeight;
        CGFloat descShortY = 0.6f * containerViewHeight;
        CGFloat descShortWidth = (0.8f * containerViewWidth) - descX;
        _descShortLabel = [[UILabel alloc] initWithFrame:CGRectMake(descShortX, descShortY, 
                                                                    descShortWidth, descShortHeight)];
        [_descShortLabel setBackgroundColor:[UIColor clearColor]];
        [_descShortLabel setTextColor:[UIColor whiteColor]];
        [_descShortLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0f]];
        
        // buy button
        CGFloat buyX = 0.7f * detailedViewWidth;
        CGFloat buyY = -0.1f * detailedViewHeight;
        CGFloat buyWith = 0.28f * detailedViewWidth;
        CGFloat buyHeight = detailedViewHeight;
        _buttonBuy = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        _buttonBuy.frame = CGRectMake(buyX, buyY, buyWith, buyHeight);
        _buttonBuy.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _buttonBuy.enabled = NO;
        _buttonBuy.hidden = YES;
        
        [_buttonBuy setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        [_buttonBuy.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14.0f]];
        [_buttonBuy setTitle:@"UPGRADE" forState:UIControlStateNormal];
        [_buttonBuy addTarget:self action:@selector(buttonBuyPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_detailedView addSubview:_buttonBuy];
    }
    return self;
}

- (void) dealloc
{
    if(_buyConfirm)
    {
        [_buyConfirm dismissWithClickedButtonIndex:0 animated:NO];
        [_buyConfirm release];
        _buyConfirm = nil;
    }    
    [_equippedStamp removeFromSuperview];
    [_equippedStamp release];
    [_levelBar removeFromSuperview];
    [_levelBar release];
    [_buttonBuy removeTarget:self action:@selector(buttonBuyPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_buttonBuy removeFromSuperview];
    [_buttonBuy release];
    [_descShortLabel removeFromSuperview];
    [_descShortLabel release];
    [_descLabel removeFromSuperview];
    [_descLabel release];
    [_priceLabel removeFromSuperview];
    [_priceLabel release];
    [_titleLabel removeFromSuperview];
    [_titleLabel release];
    [_iconImageView setImage:nil];
    [_iconImageView removeFromSuperview];
    [_iconImageView release];
    [_detailedView removeFromSuperview];
    [_detailedView release];
    [_itemContainerView removeFromSuperview];
    [_itemContainerView release];
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if(selected)
    {
        [_buttonBuy setHidden:NO];
        [_detailedView setHidden:NO];
        [_itemContainerView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.4f]];
    }
    else
    {
        // hide button after refreshCellState because refreshCellState will turn on the button
        // if item is available for purchase
        [_detailedView setHidden:YES];
        [_buttonBuy setHidden:YES];
        [_itemContainerView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.2f]];
    }
    
    // refreshCellState after unhiding because it can turn off the button
    // if item is not available
    [self refreshCellState];
}

- (void) loadIconImage:(NSString *)imageName
{
    _iconImageView.image = [[MenuResManager getInstance] loadImage:imageName isIngame:NO];
}

- (void) loadIconImage:(NSString *)imageName withColor:(UIColor*)color withKey:(NSString*)key
{
    _iconImageView.image = [[MenuResManager getInstance] loadImage:imageName 
                                                         withColor:color
                                                           withKey:key
                                                          isIngame:NO];
}

- (void) showLevelBar
{
    [_levelBar setHidden:NO];
    [_descShortLabel removeFromSuperview];
}

- (void) hideLevelBar
{
    [_levelBar setHidden:YES];
    [_itemContainerView addSubview:_descShortLabel];
}

- (void) setButtonText:(NSString *)text
{
    [_buttonBuy setTitle:text forState:UIControlStateNormal];
}

- (void) showEquippedStamp
{
    [_equippedStamp setHidden:NO];
}

- (void) hideEquippedStamp
{
    [_equippedStamp setHidden:YES];
}

#pragma mark - buttons
- (void)buttonBuyPressed:(id)sender
{
    NSLog(@"buy %@ %@", [self itemCategory], [self itemIdentifier]);
    if([self itemPrice] <= [[PlayerInventory getInstance] curPogcoins])
    {
        // buy it
        [[PlayerInventory getInstance] buyItemWithCategory:[self itemCategory] identifier:[self itemIdentifier] withPrice:[self itemPrice]];
        
        // refresh cell content
        [self refreshCellState];
    }
    else
    {
        // not enough pogcoins
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not enough Pogcoins" 
                                                        message:nil
                                                       delegate:self 
                                              cancelButtonTitle:@"Ok" 
                                              otherButtonTitles:nil];
        [alert show];
        self.buyConfirm = alert;
        [alert release];    
    }
    
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView cancelButtonIndex] == buttonIndex)
    {
        // canceled
        self.buyConfirm = nil;
    }
    else
    {
        // buy it
        [[PlayerInventory getInstance] buyItemWithCategory:[self itemCategory] identifier:[self itemIdentifier] withPrice:[self itemPrice]];
        
        // refresh cell content
        [self refreshCellState];
        
        self.buyConfirm = nil;
    }
}

- (void) refreshCellState
{
    NSDictionary* item = [[StoreManager getInstance] getItemForIdentifier:[self itemIdentifier] category:[self itemCategory]];
    unsigned int newPrice = 0;
    unsigned int numPriceTiers = [[StoreManager getInstance] numPriceTiersForItem:item];

    unsigned int curUpgradeLevel = [[PlayerInventory getInstance] curGradeForWeaponGradeKey:[[StoreManager getInstance] identifierForItem:item]];
    [self setCurLevel:curUpgradeLevel];
    if([[PlayerInventory getInstance] isMaxForWeaponGradeKey:[self itemIdentifier]])
    {
        // at Max, disable button and price
        [_buttonBuy setEnabled:NO];
        [_buttonBuy setHidden:YES];
        [self.priceLabel setHidden:YES];
        
        // if single-use, show the equipped stamp
        if([[StoreManager getInstance] isSingleUseItem:item])
        {
            [self showEquippedStamp];
        }
    }
    else
    {
        [_buttonBuy setEnabled:YES];
        [_buttonBuy setHidden:NO];
        [self.priceLabel setHidden:NO];
        
        unsigned int priceTier = curUpgradeLevel;
        if(priceTier >= numPriceTiers)
        {
            priceTier = numPriceTiers - 1;
        }
        newPrice = [[StoreManager getInstance] priceForItem:item atTier:priceTier];
        self.itemPrice = newPrice;
        [self setPriceWithAmount:newPrice];
    }
    
    [_levelBar setNeedsDisplay];
}


@end
