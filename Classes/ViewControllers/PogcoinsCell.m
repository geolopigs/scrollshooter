//
//  PogcoinsCell.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/12/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogcoinsCell.h"
#import "ProductManager.h"
#import "MBProgressHUD.h"
#import "MenuResManager.h"

@interface PogcoinsCell (PrivateMethods)
- (void) buttonBuyPressed:(id)sender;
@end

@implementation PogcoinsCell
@synthesize titleLabel = _titleLabel;
@synthesize descLabel = _descLabel;
@synthesize priceLabel = _priceLabel;
@synthesize buttonBuy = _buttonBuy;
@synthesize indicatorImageView = _indicatorImageView;
@synthesize iconImageView = _iconImageView;
@synthesize isPurchasable = _isPurchasable;
@synthesize isPurchased = _isPurchased;
@synthesize productIdentifier = _productIdentifier;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        _isPurchasable = NO;
        _isPurchased = NO;
        _productIdentifier = nil;
        self.contentView.clipsToBounds = YES;

        // title (the frame is set when the titleLabel is set; so, doesn't matter at init)
        _titleLabel = [[UILabel alloc] initWithFrame:[self bounds]];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        
        // headerView for Get More Pogcoins
        {
            CGFloat headerCellWidth = self.bounds.size.width;
            CGFloat headerCellHeight = GETMORECOINS_HEADER_HEIGHT;
            CGFloat headerViewHeight = 0.9f * headerCellHeight;
            _headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, (headerCellHeight - headerViewHeight) * 0.5f, 
                                                                   0.93f * headerCellWidth, headerViewHeight)];
            [_headerView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:1.0f]];
            
            // accessory view (for expanding rows)
            // subview added in showIndicator 
            // (the offset factors were hand-tweaked so that the indicator icon at positioned correctly; don't change them)
            CGFloat contentWidth = self.contentView.frame.size.width;
            CGRect accessoryFrame = CGRectMake(contentWidth - (1.55f * GETMORECOINS_HEADER_HEIGHT), 0.02f * GETMORECOINS_HEADER_HEIGHT, 
                                               GETMORECOINS_HEADER_HEIGHT, GETMORECOINS_HEADER_HEIGHT);
            _indicatorImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iconStoreDisclosure.png"]];
            _indicatorImageView.frame = accessoryFrame;
        }
        
        // item and detailed views
        CGFloat cellWidth = self.bounds.size.width;
        CGFloat cellHeight = POGCOINSCELL_HEIGHT; 
        CGFloat containerViewWidth = 0.93f * cellWidth;
        CGFloat containerViewHeight = 0.945f * cellHeight;
        CGFloat containerViewY = (containerViewHeight - cellHeight) * 0.5f;
        _itemContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, containerViewY,
                                                                      containerViewWidth, containerViewHeight)];
        _itemContainerView.clipsToBounds = YES;
        [_itemContainerView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.2f]];
        
        // icon image
        CGFloat iconFrameWidth = cellHeight;
        CGRect iconFrame = CGRectMake(0.0f, 0.0f,
                                      iconFrameWidth, cellHeight);
        _iconImageView = [[UIImageView alloc] initWithFrame:iconFrame];
        _iconImageView.autoresizingMask = UIViewAutoresizingNone;
        [_itemContainerView addSubview:_iconImageView];

        // price label
        CGFloat priceX = 0.8f * containerViewWidth;
        CGFloat priceY = 0.1f * containerViewHeight;
        CGFloat priceWidth = containerViewWidth - priceX;
        CGFloat priceHeight = containerViewHeight - (2.0f * priceY);
        _priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(priceX, priceY, priceWidth, priceHeight)];
        [_priceLabel setBackgroundColor:[UIColor clearColor]];
        [_priceLabel setTextColor:[UIColor whiteColor]];
        [_priceLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0f]];
        [_itemContainerView addSubview:_priceLabel];
        
        // loading indicator
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_loadingIndicator setFrame:CGRectMake(priceX, priceY, GETMORECOINS_HEADER_HEIGHT, GETMORECOINS_HEADER_HEIGHT)];
        [_itemContainerView addSubview:_loadingIndicator];
        [_loadingIndicator setHidesWhenStopped:YES];
        
        // detailed view
        CGFloat detailedX = 0.0f;
        CGFloat detailedY = containerViewHeight + containerViewY;
        CGFloat detailedViewWidth = containerViewWidth;
        CGFloat detailedViewHeight = (POGCOINSCELL_DISCLOSEDHEIGHT - POGCOINSCELL_HEIGHT) * 0.95f;
        _detailedView = [[UIView alloc] initWithFrame:CGRectMake(detailedX, detailedY, 
                                                                 detailedViewWidth, detailedViewHeight)];
        [_detailedView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.4f]];
        [_detailedView setHidden:YES];

        // description
        CGFloat descX = 0.05f * detailedViewWidth;
        CGFloat descY = 0.0f;
        CGFloat descWidth = 0.68f * detailedViewWidth;
        CGFloat descHeight = detailedViewHeight;
        _descLabel = [[UILabel alloc] initWithFrame:CGRectMake(descX, descY, descWidth, descHeight)];
        [_descLabel setBackgroundColor:[UIColor clearColor]];
        [_descLabel setNumberOfLines:2];
        [_descLabel setTextColor:[UIColor orangeColor]];
        [_descLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0f]];
        [_detailedView addSubview:_descLabel];
        
        // buy button
        CGFloat buyX = 0.75f * detailedViewWidth;
        CGFloat buyY = -0.1f * detailedViewHeight;
        CGFloat buyWith = 0.23f * detailedViewWidth;
        CGFloat buyHeight = detailedViewHeight;
        _buttonBuy = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        _buttonBuy.frame = CGRectMake(buyX, buyY, buyWith, buyHeight);
        _buttonBuy.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _buttonBuy.enabled = NO;
        _buttonBuy.hidden = YES;
        _buttonBuy.layer.borderWidth = 1.0;
        _buttonBuy.layer.borderColor = [UIColor whiteColor].CGColor;
        _buttonBuy.layer.cornerRadius = 4.0;

        [_buttonBuy setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_buttonBuy.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0f]];
        [_buttonBuy setTitle:@"BUY" forState:UIControlStateNormal];
        [_buttonBuy addTarget:self action:@selector(buttonBuyPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_detailedView addSubview:_buttonBuy];
        
    }
    return self;
}

- (void) dealloc
{
    [_indicatorImageView setImage:nil];
    [_indicatorImageView removeFromSuperview];
    [_indicatorImageView release];
    [_iconImageView setImage:nil];
    [_iconImageView removeFromSuperview];
    [_iconImageView release];
    [_buttonBuy removeFromSuperview];
    [_buttonBuy release];
    [_priceLabel removeFromSuperview];
    [_priceLabel release];
    [_loadingIndicator removeFromSuperview];
    [_loadingIndicator release];
    [_descLabel removeFromSuperview];
    [_descLabel release];
    [_titleLabel removeFromSuperview];
    [_titleLabel release];
    [_detailedView removeFromSuperview];
    [_detailedView release];
    [_itemContainerView removeFromSuperview];
    [_itemContainerView release];
    [_headerView removeFromSuperview];
    [_headerView release];
    [_productIdentifier release];
    [super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    if(selected)
    {
        if([self isPurchasable])
        {
            if([self isPurchased])
            {
                _buttonBuy.enabled = NO;
                _buttonBuy.hidden = YES;
            }
            else
            {
                _buttonBuy.enabled = YES;
                _buttonBuy.hidden = NO;
            }
            [_detailedView setHidden:NO];
            [_itemContainerView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.4f]];
        }
    }
    else
    {
        _buttonBuy.enabled = NO;
        _buttonBuy.hidden = YES;
        [_detailedView setHidden:YES];
        [_itemContainerView setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:0.2f]];
    }
}

- (void) startLoading
{
    [_loadingIndicator startAnimating];
}

- (void) stopLoading
{
    [_loadingIndicator stopAnimating];
}

- (void) showIndicator
{
    _indicatorImageView.transform = CGAffineTransformIdentity;
    [self.contentView addSubview:_indicatorImageView];
    
    [self.contentView setNeedsDisplay];
}

- (void) showExpandedIndicator
{
    CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI_2);
    _indicatorImageView.transform = rotate;
    [self.contentView addSubview:_indicatorImageView];
    [self.contentView setNeedsDisplay];
}

- (void) hideIndicator
{
    [_indicatorImageView removeFromSuperview];
}

- (void) setHeaderTitle:(NSString *)text
{
    [_titleLabel setTextColor:[UIColor colorWithRed:0.1f green:0.16f blue:0.156f alpha:1.0f]];
    [_titleLabel setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:18.0f]];
    CGRect myFrame = CGRectMake(5.0f, 0.0f, 
                                _titleLabel.frame.size.width, GETMORECOINS_HEADER_HEIGHT);
    [_titleLabel setFrame:myFrame];
    [_titleLabel setText:text];
}

- (void) setRegularTitle:(NSString *)text
{
    [_titleLabel setTextColor:[UIColor orangeColor]];
    [_titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0f]];
    CGFloat titleX = 1.025f * _iconImageView.frame.size.width;
    CGRect myFrame = CGRectMake(titleX, 0.0f, 
                                _titleLabel.frame.size.width, [_itemContainerView frame].size.height);
    [_titleLabel setFrame:myFrame];
    [_titleLabel setText:text];
}

- (void) useCellForHeader
{
    // title
    [_titleLabel removeFromSuperview];
    [_headerView addSubview:_titleLabel];
    
    // contentview
    [_detailedView removeFromSuperview];
    [_itemContainerView removeFromSuperview];
    [self.contentView addSubview:_headerView];
}

- (void) useCellForItem
{
    // title
    [_titleLabel removeFromSuperview];
    [_itemContainerView addSubview:_titleLabel];

    // contentView
    [_headerView removeFromSuperview];
    [self.contentView addSubview:_itemContainerView];
    [self.contentView addSubview:_detailedView];
}

- (void) loadIconImage:(NSString *)imageName
{
    _iconImageView.image = [[MenuResManager getInstance] loadImage:imageName isIngame:NO];
}

- (void) clearIconImage
{
    [_iconImageView setImage:nil];
}

#pragma mark - button actions
- (void) buttonBuyPressed:(id)sender
{
    if([self productIdentifier])
    {
        NSLog(@"buy product %@", [self productIdentifier]);        
        [[ProductManager getInstance] purchaseUpgradeByProductID:[self productIdentifier]];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
        hud.labelText = @"Purchase in progress";
    }
}

@end
