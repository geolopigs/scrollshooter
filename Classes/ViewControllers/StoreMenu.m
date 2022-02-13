//
//  StoreMenu.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/2/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "StoreMenu.h"
#import "SoundManager.h"
#import "StoreManager.h"
#import "PlayerInventory.h"
#import "StoreItemCell.h"
#import "PogcoinsCell.h"
#import "FreeCoinsCell.h"
#import "ProductManager.h"
#import "MBProgressHUD.h"
#import "AppNavController.h"
#import "MenuResManager.h"
#import "GameManager.h"
#import "GameViewController.h"
#import <QuartzCore/QuartzCore.h>

static const float SECTIONHEADER_HEIGHT = 40.0f;

enum StoreMenuStaticSection
{
    STATIC_SECTION_POGCOINS = 0,
    STATIC_SECTION_NUM
};

@interface StoreMenu ()
{
    BOOL _showViewWithGetMoreCoins;
}
- (void) refreshPogcoinsLabel;
- (void) handleProductsFetched:(NSNotification*)note;
- (void) handleSKTransactionCanceled:(NSNotification*)note;
- (void) handleSKTransactionFailed:(NSNotification*)note;
- (void) handleSKTransactionSucceeded:(NSNotification*)note;

- (void) createGetCoinsView;
- (void) refreshGetCoinsView;
- (void) getMoreCoinsPressed:(id)sender;
- (UITableViewCell*)tableView:(UITableView*)tv pogcoinsCellAtIndexPath:(NSIndexPath*)indexPath;
@end

@implementation StoreMenu
@synthesize  delegate = _delegate;

- (id)initWithGetMoreCoins:(BOOL)showGetMoreCoins
{
    self = [super initWithNibName:@"StoreMenu" bundle:nil];
    if (self) 
    {
        _delegate = nil;
        _selectedRow = -1;
        _selectedSection = -1;
        _isVisbleCoinInAppSection = NO;
    
        _showViewWithGetMoreCoins = showGetMoreCoins;
    }
    return self;
}

- (void)dealloc 
{
    [_getCoinsDiscloser removeFromSuperview];
    [_getCoinsDiscloser release];
    [_getCoinsView removeFromSuperview];
    [_getCoinsView release];

    if([self alertView])
    {
        [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
        self.alertView = nil;
    }    
    [_delegate release];
    [_tableView release];
    [pogCoinsLabel release];
    [_topView release];
    [_tableContainer release];
    [_contentView release];
    [border release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (UIAlertView*) alertView
{
    return _alertView;
}

- (void) setAlertView:(UIAlertView *)alertView
{
    if(_alertView)
    {
        [_alertView dismissWithClickedButtonIndex:0 animated:YES];
        [_alertView release];
    }
    _alertView = [alertView retain];
}

#pragma mark - product manager

- (void) handleProductsFetched:(NSNotification *)note
{
    [_tableView reloadData];
}

- (void) handleProductsFetchFailed:(NSNotification*) note
{
    [_tableView reloadData];
}

- (void) handleSKTransactionCanceled:(NSNotification *)note
{
    [MBProgressHUD hideHUDForView:self.view.window animated:YES];
}

- (void) handleSKTransactionFailed:(NSNotification *)note
{
    [MBProgressHUD hideHUDForView:self.view.window animated:YES];  
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase failed" 
                                                    message:@"Try again later"
                                                   delegate:self 
                                          cancelButtonTitle:@"Ok" 
                                          otherButtonTitles:nil];
    self.alertView = alert;
    [alert show];
    [alert release];    
}

- (void) handleSKTransactionSucceeded:(NSNotification *)note
{
    [MBProgressHUD hideHUDForView:self.view.window animated:YES];  
    
    [self refreshPogcoinsLabel];
    _selectedRow = -1;
    _selectedSection = -1;
    [_tableView reloadData];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Completed"
                                                    message:nil
                                                   delegate:self 
                                          cancelButtonTitle:@"Ok" 
                                          otherButtonTitles:nil];
    self.alertView = alert;
    [alert show];
    [alert release];        
}

- (void) loadCoinProductInfoSilentFail:(BOOL)silentFail
{
    BOOL requested = [[ProductManager getInstance] requestProductData];
    if(!requested)
    {
        if(!silentFail)
        {
            // network not reachable, show an alert
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection" 
                                                            message:@"Try again later"
                                                           delegate:nil 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil];
            [alert show];
            [MenuResManager getInstance].alertView = alert;
            [alert release];                    
        }
    }
}

#pragma mark - get more pogcoins view

- (void) createGetCoinsView
{
    float tableViewWidth = _tableView.bounds.size.width;
    _getCoinsView = [[UIView alloc] initWithFrame:CGRectMake(_tableView.frame.origin.x, 0.0f, 
                                                                tableViewWidth, SECTIONHEADER_HEIGHT)];
    [_getCoinsView setBackgroundColor:[UIColor clearColor]];
    
    // add a container view for the label to set the background color
    // so that label text can be adjusted within the area with background color
    float myFrameHeight = 0.9f * SECTIONHEADER_HEIGHT;
    float myFrameWidth = 0.98f * tableViewWidth;
    CGRect containerFrame = CGRectMake(0.0f, 0.0f, 
                                       myFrameWidth, myFrameHeight);
    UIView* labelContainer = [[[UIView alloc] initWithFrame:containerFrame] autorelease];
    [labelContainer setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:1.0f]];
    [_getCoinsView addSubview:labelContainer];
    
    // the label itself
    CGRect labelFrame = CGRectMake(5.0f, 0.0f, myFrameWidth, SECTIONHEADER_HEIGHT);
    UILabel* sectionHeaderLabel = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
    sectionHeaderLabel.autoresizingMask = UIViewAutoresizingNone;
    [sectionHeaderLabel setBackgroundColor:[UIColor clearColor]];
    [sectionHeaderLabel setTextColor:[UIColor colorWithRed:0.1f green:0.16f blue:0.156f alpha:1.0f]];
    [sectionHeaderLabel setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:26.0f]];
    [sectionHeaderLabel setText:@"Get More Pogcoins"];
    [labelContainer addSubview:sectionHeaderLabel];
        
    // make the labelContainer width smaller to show the discloser indicator for pogcoins section
    labelContainer.frame = CGRectMake(0.0f, 0.0f, 0.95f * myFrameWidth, myFrameHeight);
    
    // add a button to let user expand the coins section
    UIButton* getMoreCoinsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    getMoreCoinsButton.frame = CGRectMake(0.0f, 0.0f, tableViewWidth, SECTIONHEADER_HEIGHT);
    [getMoreCoinsButton addTarget:self action:@selector(getMoreCoinsPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_getCoinsView addSubview:getMoreCoinsButton];
    
    CGRect accessoryFrame = CGRectMake(tableViewWidth - (0.95f * SECTIONHEADER_HEIGHT), -0.05f * SECTIONHEADER_HEIGHT, 
                                       SECTIONHEADER_HEIGHT, SECTIONHEADER_HEIGHT);
    _getCoinsDiscloser = [[UIImageView alloc] initWithFrame:accessoryFrame];
    _getCoinsDiscloser.image = [UIImage imageNamed:@"iconStoreDisclosure.png"];
    [_getCoinsView addSubview:_getCoinsDiscloser];
}

- (void) refreshGetCoinsView
{
    if(_isVisbleCoinInAppSection)
    {
        _getCoinsDiscloser.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
    }
    else
    {
        _getCoinsDiscloser.transform = CGAffineTransformIdentity;
    }    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        const float iPadScale = 0.95f * ([[UIScreen mainScreen] bounds].size.height / _contentView.frame.size.height);
        [_contentView setTransform:CGAffineTransformMakeScale(iPadScale, iPadScale)];
        [[_contentView layer] setCornerRadius:6.0f];
        [[_contentView layer] setMasksToBounds:YES];
        [border setTransform:CGAffineTransformMakeScale(iPadScale, iPadScale)];
        [[border layer] setCornerRadius:8.0f];
        [[border layer] setMasksToBounds:YES];
        [[border layer] setBorderWidth:3.0f];
        [[border layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    }
    
    [self refreshPogcoinsLabel];
    [[PlayerInventory getInstance] setDelegate:self];
    _isVisbleCoinInAppSection = NO;
    
    [self createGetCoinsView];
    [_tableContainer addSubview:_getCoinsView];

    if(_showViewWithGetMoreCoins)
    {
        // if init with more-coins section, expand it right away
        [self getMoreCoinsPressed:nil];
    }
}

- (void)viewDidUnload
{
    [_getCoinsDiscloser removeFromSuperview];
    [_getCoinsDiscloser release];
    _getCoinsDiscloser = nil;
    [_getCoinsView removeFromSuperview];
    [_getCoinsView release];
    _getCoinsView = nil;
    [[PlayerInventory getInstance] setDelegate:nil];
    [_tableView release];
    _tableView = nil;
    [pogCoinsLabel release];
    pogCoinsLabel = nil;
    [_topView release];
    _topView = nil;
    [_tableContainer release];
    _tableContainer = nil;
    [_contentView release];
    _contentView = nil;
    [border release];
    border = nil;
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[PlayerInventory getInstance] setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleProductsFetched:) 
                                                 name:kProductManagerProductsFetchedNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleProductsFetchFailed:) 
                                                 name:kProductManagerFetchFailedNotification 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSKTransactionSucceeded:) 
                                                 name:kProductManagerTransactionSucceededNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSKTransactionFailed:) 
                                                 name:kProductManagerTransactionFailedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSKTransactionCanceled:) 
                                                 name:kProductManagerTransactionCanceledNotification
                                               object:nil];
    
    // request product info loads (it is ok to call this repeatedly)
}

- (void) viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[PlayerInventory getInstance] setDelegate:nil];    
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark UITableViewDataSource Methods 
- (UITableViewCell*)tableView:(UITableView*)tv pogcoinsCellAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* pogcoinsCellIdentifier = @"PogcoinsCell";
    PogcoinsCell* cell = [tv dequeueReusableCellWithIdentifier:pogcoinsCellIdentifier];
    if(nil == cell)
    {
        cell = [[PogcoinsCell alloc] initWithReuseIdentifier:pogcoinsCellIdentifier];
    }
    
    {
        [cell useCellForItem];
        unsigned int coinProductIndex = [indexPath row];
        
        {
            // purchaseable coins
            // get title and description
            NSString* productId = [[ProductManager getInstance] getCoinIdentifierAtIndex:coinProductIndex];
            NSString* productTitle = [[ProductManager getInstance] getCoinTitleForProductId:productId];
            NSString* productDesc = [[ProductManager getInstance] getCoinDescForProductId:productId];
            [cell setRegularTitle:productTitle];
            [cell.descLabel setText:productDesc];
            [cell loadIconImage:[[ProductManager getInstance] getImageNameForProductId:productId]];
            
            // get product price
            SKProduct* coinProduct = [[ProductManager getInstance] getCoinProductAtIndex:coinProductIndex];
            if(coinProduct)
            {
                [cell setRegularTitle:[coinProduct localizedTitle]];
                [cell.descLabel setText:[coinProduct localizedDescription]];
                
                // set price label with the currency format of the product's locale
                NSNumberFormatter *priceStyle = [[NSNumberFormatter alloc] init];
                [priceStyle setFormatterBehavior:[NSNumberFormatter defaultFormatterBehavior]];
                [priceStyle setNumberStyle:NSNumberFormatterCurrencyStyle];
                [priceStyle setLocale:[coinProduct priceLocale]];
                NSString* formatted = [priceStyle stringFromNumber:[coinProduct price]]; 
                [cell.priceLabel setText:formatted];
                cell.isPurchasable = YES;
                cell.productIdentifier = [coinProduct productIdentifier];
                
                // turn off loading indicator
                [cell stopLoading];
            }
            else
            {
                cell.isPurchasable = NO;
                cell.productIdentifier = nil;
                
                // turn on loading indicator
                [cell startLoading];
            }
            [cell hideIndicator];
        }
    }
    return cell;
}

- (UITableViewCell*)tableView:(UITableView*)tv storeCoinItemCellAtSection:(unsigned int)section row:(unsigned int)row
{
    static NSString* cellIdentifier = @"FreeCoinsCell";
    FreeCoinsCell* cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
    if( nil == cell ) 
    {
        cell = [[FreeCoinsCell alloc] initWithReuseIdentifier:cellIdentifier];
    }
    const NSString* catName = [[StoreManager getInstance] categoryIdForIndex:section];
    NSDictionary* item = [[StoreManager getInstance] getItemAtIndex:row forCategory:catName];
    
    // for free coins at row 0, if player already obtained it, show row 1 then
    if([[PlayerInventory getInstance] isMaxForWeaponGradeKey:[[StoreManager getInstance] identifierForItem:item]])
    {
        item = [[StoreManager getInstance] getItemAtIndex:row+1 forCategory:catName];
    }
    
    NSString* title = [[StoreManager getInstance] titleForItem:item];
    NSString* desc = [[StoreManager getInstance] descForItem:item];
    [cell.titleLabel setText:title];
    [cell.descLabel setText:desc];
    [cell loadIconImage:[[StoreManager getInstance] imageNameForItem:item]];

    // item level
    // note the +1 for maxUpgradeLevel because the levels in player-inventory are inclusive; so, max is the max level, that means the number of 
    // levels is one more than the max level
    unsigned int numLevels = [[PlayerInventory getInstance] maxForWeaponGradeKey:[[StoreManager getInstance] identifierForItem:item]] + 1;
    unsigned int curUpgradeLevel = [[PlayerInventory getInstance] curGradeForWeaponGradeKey:[[StoreManager getInstance] identifierForItem:item]];
    
    [cell setNumLevels:numLevels];
    [cell setCurLevel:curUpgradeLevel];

    // button
    [cell setButtonText:@"GET"];

    // price
    unsigned int numPriceTiers = [[StoreManager getInstance] numPriceTiersForItem:item];
    unsigned int curPriceTier = curUpgradeLevel;
    if(curPriceTier >= numPriceTiers)
    {
        curPriceTier = numPriceTiers - 1;
    }
    unsigned int price = [[StoreManager getInstance] priceForItem:item atTier:curPriceTier];
    [cell setPriceWithAmount:price];

    // set item info
    cell.itemCategory = [NSString stringWithFormat:@"%@", catName];
    cell.itemIdentifier = [[StoreManager getInstance] identifierForItem:item];
    cell.itemPrice = price;
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    UITableViewCell* result = nil;
    if(STATIC_SECTION_NUM > section)
    {
        switch(section)
        {
            case STATIC_SECTION_POGCOINS:
                if(row < [[ProductManager getInstance] getNumCoinProducts])
                {
                    result = [self tableView:tv pogcoinsCellAtIndexPath:indexPath];
                }
                else
                {
                    result = [self tableView:tv storeCoinItemCellAtSection:section 
                                         row:row - [[ProductManager getInstance] getNumCoinProducts]];
                }
                break;
            
            default:
                //do nothing
                break;
        }
    }
    else
    {
        StoreItemCell* cell = nil;
        
        static NSString *cellIdentifier = @"StoreCell";
        
        cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
        if( nil == cell ) 
        {
            cell = [[StoreItemCell alloc] initWithReuseIdentifier:cellIdentifier];
        }
        cell.backgroundColor = [UIColor whiteColor];
        const NSString* catName = [[StoreManager getInstance] categoryIdForIndex:section];
        NSDictionary* item = [[StoreManager getInstance] getItemAtIndex:[indexPath row] forCategory:catName];
        NSString* title = [[StoreManager getInstance] titleForItem:item];
        [cell.titleLabel setText:title];

        // icon image
        NSString* imageName = [[StoreManager getInstance] imageNameForItem:item];
        NSString* itemIdentifier = [[StoreManager getInstance] identifierForItem:item];
        if([[StoreManager getInstance] hasImageColorForItem:item])
        {
            UIColor* imageColor = [[StoreManager getInstance] imageColorForItem:item];
            [cell loadIconImage:imageName 
                      withColor:imageColor
                        withKey:[NSString stringWithFormat:@"%@_%@", imageName, itemIdentifier]];
        }
        else
        {
            [cell loadIconImage:imageName];
        }
        
        // item level
        // note the +1 for maxUpgradeLevel because the levels in player-inventory are inclusive; so, max is the max level, that means the number of 
        // levels is one more than the max level
        unsigned int numLevels = [[PlayerInventory getInstance] maxForWeaponGradeKey:itemIdentifier] + 1;
        unsigned int curUpgradeLevel = [[PlayerInventory getInstance] curGradeForWeaponGradeKey:itemIdentifier];
        
        [cell setNumLevels:numLevels];
        [cell setCurLevel:curUpgradeLevel];
        if([[StoreManager getInstance] isSingleUseCategory:catName])
        {
            [cell hideLevelBar];
            [cell setButtonText:@"EQUIP"];
        }
        else
        {
            [cell showLevelBar];
            [cell setButtonText:@"UPGRADE"];
        }
        [cell hideEquippedStamp];

        // price
        unsigned int numPriceTiers = [[StoreManager getInstance] numPriceTiersForItem:item];
        unsigned int curPriceTier = curUpgradeLevel;
        if(curPriceTier >= numPriceTiers)
        {
            curPriceTier = numPriceTiers - 1;
        }
        unsigned int price = [[StoreManager getInstance] priceForItem:item atTier:curPriceTier];
        [cell setPriceWithAmount:price];
        
        NSString* desc = [[StoreManager getInstance] descForItem:item];
        [cell.descLabel setText:desc];
        NSString* descShort = [[StoreManager getInstance] descShortForItem:item];
        [cell.descShortLabel setText:descShort];
        
        // set item info
        cell.itemCategory = [NSString stringWithFormat:@"%@", catName];
        cell.itemIdentifier = [[StoreManager getInstance] identifierForItem:item];
        cell.itemPrice = price;
        
        result = (UITableViewCell*)cell;
    }    
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	NSInteger numSections = [[StoreManager getInstance] numCategories];
	return numSections;
}


- (NSInteger)tableView:(UITableView *)tv
 numberOfRowsInSection:(NSInteger)section
{
    const NSString* catName = [[StoreManager getInstance] categoryIdForIndex:section];
    NSInteger numRows = 0;
    if(STATIC_SECTION_POGCOINS == section)
    {
        numRows = 0;
        if(_isVisbleCoinInAppSection)
        {
            numRows += [[ProductManager getInstance] getNumCoinProducts];
            numRows += [[PlayerInventory getInstance] getNumFreeCoinPacksRemaining];
        }
    }
    else
    {
        numRows = [[StoreManager getInstance] numItemsForCategory:catName];
    }
    return numRows;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* result = nil;
    if(STATIC_SECTION_NUM <= section)
    {
        result = [[StoreManager getInstance] categoryTitleForIndex:section];
    }
    return result;
}

#pragma mark UITableViewDelegate Methods

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tv
didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    BOOL doSelect = YES;
    if((STATIC_SECTION_POGCOINS == [indexPath section]) &&
       ([indexPath row] < [[ProductManager getInstance] getNumCoinProducts]))
    {
        // for pog coins, only select if product info is available
        PogcoinsCell* curCell = (PogcoinsCell*)[self tableView:tv cellForRowAtIndexPath:indexPath];
        if(![curCell isPurchasable])
        {
            // not selectable
            doSelect = NO;
            
            // show loading indicator
            [curCell startLoading];
            
            // request a product info fetch
            [self loadCoinProductInfoSilentFail:NO];
        }
    }
    
    if(doSelect)
    {
        _selectedRow = indexPath.row;
        _selectedSection = indexPath.section;
    }
    else
    {
        _selectedRow = -1;
        _selectedSection = -1;
    }

    {
        // this causes the rows to animate-adjust when the selected row's height changes
        [tv beginUpdates];
        [tv endUpdates];        
    }
}

- (void) getMoreCoinsPressed:(id)sender
{
    unsigned int numSubrows = 0;

    // clear current selection
    _selectedSection = -1;
    _selectedRow = -1;
    if(!_isVisbleCoinInAppSection)
    {
        numSubrows = [[ProductManager getInstance] getNumCoinProducts] + [[PlayerInventory getInstance] getNumFreeCoinPacksRemaining];
        _isVisbleCoinInAppSection = YES;
        
        NSMutableArray* subRows = [NSMutableArray arrayWithCapacity:numSubrows];
        for(unsigned int i = 0; i < numSubrows; ++i)
        {
            [subRows addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [_tableView beginUpdates];
        
        // insert the expanded rows
        [_tableView insertRowsAtIndexPaths:subRows withRowAnimation:UITableViewRowAnimationRight];
        
        [_tableView endUpdates];        
        [_tableView reloadData];

        [self refreshGetCoinsView];

        // request a product info fetch
        [self loadCoinProductInfoSilentFail:YES];
    }

    // pop to the top of the tableview
    {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
                          atScrollPosition:UITableViewScrollPositionTop 
                                  animated:YES];
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* sectionHeaderView = nil;
    if(STATIC_SECTION_NUM <= section)
    {
        float tableViewWidth = tableView.bounds.size.width;
        sectionHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 
                                                                      tableViewWidth, SECTIONHEADER_HEIGHT)] autorelease];
        [sectionHeaderView setBackgroundColor:[UIColor clearColor]];
        
        // add a container view for the label to set the background color
        // so that label text can be adjusted within the area with background color
        float myFrameHeight = 0.9f * SECTIONHEADER_HEIGHT;
        float myFrameWidth = 0.98f * tableViewWidth;
        CGRect containerFrame = CGRectMake(0.0f, 0.0f, 
                                    myFrameWidth, myFrameHeight);
        UIView* labelContainer = [[[UIView alloc] initWithFrame:containerFrame] autorelease];
        [labelContainer setBackgroundColor:[UIColor colorWithRed:0.31f green:0.48f blue:0.47f alpha:1.0f]];
        [sectionHeaderView addSubview:labelContainer];
        
        // the label itself
        CGRect labelFrame = CGRectMake(5.0f, 0.0f, myFrameWidth, SECTIONHEADER_HEIGHT);
        UILabel* sectionHeaderLabel = [[[UILabel alloc] initWithFrame:labelFrame] autorelease];
        sectionHeaderLabel.autoresizingMask = UIViewAutoresizingNone;
        [sectionHeaderLabel setBackgroundColor:[UIColor clearColor]];
        [sectionHeaderLabel setTextColor:[UIColor colorWithRed:0.1f green:0.16f blue:0.156f alpha:1.0f]];
        [sectionHeaderLabel setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:24.0f]];
        [sectionHeaderLabel setText:[tableView.dataSource tableView:tableView titleForHeaderInSection:section]];
        [sectionHeaderLabel setAdjustsFontSizeToFitWidth:YES];
        [labelContainer addSubview:sectionHeaderLabel];
    }
    return sectionHeaderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.0f;
    if(STATIC_SECTION_NUM <= section)
    {
        height = SECTIONHEADER_HEIGHT;
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat result = 44.0f;
    NSInteger section = [indexPath section];
    
    CGFloat regularHeight = STORECELL_HEIGHT;
    CGFloat disclosedHeight = STORECELL_DISCLOSEDHEIGHT;
    if(STATIC_SECTION_POGCOINS == section)
    {
        if([indexPath row] < [[ProductManager getInstance] getNumCoinProducts])
        {
            regularHeight = POGCOINSCELL_HEIGHT;
            disclosedHeight = POGCOINSCELL_DISCLOSEDHEIGHT;
        }
        else
        {
            regularHeight = FREECOINSCELL_HEIGHT;
            disclosedHeight = FREECOINSCELL_DISCLOSEDHEIGHT;
        }
    }

    if((_selectedRow == [indexPath row]) && (_selectedSection == [indexPath section]))
    {
        result = disclosedHeight;
    }
    else
    {
        result = regularHeight;
    }
    return result;
}

#pragma mark - PlayerInventoryDelegate
- (void) playerInventoryDidChange
{
    [self refreshPogcoinsLabel];
    _selectedSection = -1;
    _selectedRow = -1;
    [_tableView reloadData];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView cancelButtonIndex] == buttonIndex)
    {
        // canceled
        self.alertView = nil;
    }
}


#pragma mark - top view
- (void)refreshPogcoinsLabel
{
    unsigned int amount = [[PlayerInventory getInstance] curPogcoins];
    [pogCoinsLabel setText:[StoreManager pogcoinsStringForAmount:amount]];
    [pogCoinsLabel setNeedsDisplay];
    [_topView setNeedsDisplay];
    [self.view setNeedsDisplay];
}


#pragma mark - button actions
- (IBAction) buttonBackPressed:(id)sender
{
/*
    if(_delegate)
    {
        [_delegate dismissStoreMenu];
    }
 */
    // if we had been pushed by GameViewController, and it had been unloaded because of memory warning
    // then just pop all the way out to the main menu
    UINavigationController* nav = [self navigationController];
    unsigned int stackCount = [[nav viewControllers] count];
    if((stackCount >= 2) && 
       ([[[nav viewControllers] objectAtIndex:(stackCount-2)] isMemberOfClass:[GameViewController class]]) &&
       ([[GameManager getInstance] gameMode] == GAMEMODE_FRONTEND))
    {
        [[AppNavController getInstance] popToRootViewControllerAnimated:YES];
    }
    else 
    {
        [[AppNavController getInstance] popToLeftViewControllerAnimated:YES];
    }
}


#pragma mark -
#pragma mark AppEventDelegate
- (void) appWillResignActive
{
	// do nothing
}

- (void) appDidBecomeActive
{
	// do nothing
}

- (void) appDidEnterBackground
{
    // do nothing
}

- (void) appWillEnterForeground
{
    // do nothing
}

- (void) abortToRootViewControllerNow
{
    [[AppNavController getInstance] popToRootViewControllerAnimated:NO];
}


@end
