//
//  FlyerSelectPage.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/23/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "FlyerSelectPage.h"
#import <QuartzCore/QuartzCore.h>
#import <StoreKit/StoreKit.h>
#import "ProductManager.h"
#import "PlayerInventory.h"
#import "MBProgressHUD.h"
#import "MenuResManager.h"
#import "GameCenterCategories.h"

static NSTimeInterval INFOPANE_DURATION = 3.0f;

@interface FlyerSelectPage (PrivateMethods)
- (void) initBorder;
- (void) initLabels;
- (void) updateInfoPane;
- (void) updateBuyButton;
- (void) startProductLoadingIndicator;
- (void) updateForProductInfoChanged;
- (CGRect) infoPaneCollapsedFrame;
- (CGRect) infoPaneExpandedFrame;
- (void) collapseInfoPaneAfterDelay:(NSTimeInterval)delay;
- (void) expandInfoPaneForDuration:(NSTimeInterval)duration;
- (void) registerSKProductObservers;
- (void) handleProductsFetched:(NSNotification*)note;
- (void) handleProductsFetchFailed:(NSNotification*)note;
- (void) handleSKTransactioCanceled:(NSNotification*)note;
- (void) handleSKTransactionFailed:(NSNotification*)note;
- (void) handleSKTransactionSucceeded:(NSNotification*)note;
- (CGRect) gimmieTipFrame;
@end

@implementation FlyerSelectPage
@synthesize flyerProductId = _flyerProductId;

- (id)initWithFlyerProductId:(NSString *)productId
{
    self = [super initWithNibName:@"FlyerSelectPage" bundle:nil];
    if (self) 
    {
        _flyerProductId = [productId retain];
        _wasUnlockPressed = NO;
        _isInfoPaneCollapsed = NO;
    }
    return self;
}

- (void)dealloc 
{
    [_flyerProductId release];
    
    [backScrim release];
    [border release];
    [_titleLabel release];
    [_descLabel release];
    [_buyButton release];
    [self setImage:nil];
    [_imageView release];
    [_infoPane release];
    [_loadingIndicator release];
    [_unlockButton release];
    [_buttonsView release];
    [_gimmieTipView release];
    [_gimmieTipBorder release];
    [_gimmieTipLabel release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) initBorder
{
    // init round corners
    [[backScrim layer] setCornerRadius:3.0f];
    [[backScrim layer] setMasksToBounds:YES];
    [[backScrim layer] setBorderWidth:1.0f];
    [[backScrim layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[border layer] setCornerRadius:5.0f];
    [[border layer] setMasksToBounds:YES];
    [[border layer] setBorderWidth:3.0f];
    [[border layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    
    // init round corners for gimmie tip
    [[_gimmieTipBorder layer] setCornerRadius:5.0f];
    [[_gimmieTipBorder layer] setMasksToBounds:YES];
    [[_gimmieTipBorder layer] setBorderWidth:3.0f];
    [[_gimmieTipBorder layer] setBorderColor:[[UIColor whiteColor] CGColor]];
}

- (void) initLabels
{
    [_titleLabel setText:[[ProductManager getInstance] getFlyerTitleForProductId:[self flyerProductId]]];
    [_descLabel setText:[[ProductManager getInstance] getFlyerDescForProductId:[self flyerProductId]]];
}

- (void) registerSKProductObservers
{
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
}

- (void) updateInfoPane
{
    if([[PlayerInventory getInstance] doesHangarHaveFlyer:[self flyerProductId]])
    {
        // if I already have this flyer, don't show info pane
        _isInfoPaneCollapsed = YES;
        [_infoPane setFrame:[self infoPaneCollapsedFrame]];
        [_infoPane setHidden:YES];
        [_buttonsView setHidden:YES];
    }
    else
    {
        [_infoPane setHidden:NO];
        [_buttonsView setHidden:NO];

        _isInfoPaneCollapsed = YES;
        [_infoPane setFrame:[self infoPaneCollapsedFrame]];
        [self expandInfoPaneForDuration:INFOPANE_DURATION];
    }
}


- (void) updateBuyButton
{
    // stop any loading indicator
    [_loadingIndicator stopAnimating];
    [_loadingIndicator setHidden:YES];
    
    if([[PlayerInventory getInstance] doesHangarHaveFlyer:[self flyerProductId]])
    {
        // already purchased, disable all in-app purchase buttons
        [_buyButton setEnabled:NO];
        [_buyButton setHidden:YES];
        [_loadingIndicator setHidden:YES];
    }
    else
    {
        // not yet purchased
        if([[ProductManager getInstance].productLookup objectForKey:[self flyerProductId]])
        {
            // we have product info, show the buy button
            [_buyButton setEnabled:YES];
            [_buyButton setHidden:NO];
            [_unlockButton setEnabled:NO];
            [_unlockButton setHidden:YES];
            
            SKProduct* flyerProduct = [[ProductManager getInstance] getFlyerProductForProductId:[self flyerProductId]];
            if(flyerProduct)
            {
                // set price label with the currency format of the product's locale
                NSNumberFormatter *priceStyle = [[NSNumberFormatter alloc] init];
                [priceStyle setFormatterBehavior:[NSNumberFormatter defaultFormatterBehavior]];
                [priceStyle setNumberStyle:NSNumberFormatterCurrencyStyle];
                [priceStyle setLocale:[flyerProduct priceLocale]];
                NSString* formatted = [priceStyle stringFromNumber:[flyerProduct price]]; 
                [_buyButton setTitle:formatted forState:UIControlStateNormal];
            }
        }
        else
        {
            // otherwise show the unlock button
            [_buyButton setEnabled:NO];
            [_buyButton setHidden:YES];
            [_unlockButton setEnabled:YES];
            [_unlockButton setHidden:NO];
        }
    }
}

- (void) updateForProductInfoChanged
{
    [self updateInfoPane];
    [self updateBuyButton];
    [_infoPane setNeedsDisplay];
    [_buttonsView setNeedsDisplay];
    _wasUnlockPressed = NO;
}

- (void) startProductLoadingIndicator
{
    [_loadingIndicator setHidden:NO];
    [_loadingIndicator startAnimating];
    [_buyButton setEnabled:NO];
    [_buyButton setHidden:YES];
    [_unlockButton setEnabled:NO];
    [_unlockButton setHidden:YES];
}

// load product info from app-store if not yet loaded
- (void) loadFlyerProductInfoSilent:(BOOL)silentFail
{
    if(![[PlayerInventory getInstance] doesHangarHaveFlyer:[self flyerProductId]])
    {
        [_infoPane setHidden:NO];
        [_buttonsView setHidden:NO];
        if(nil == [[[ProductManager getInstance] productLookup] objectForKey:[self flyerProductId]])
        {
            [self startProductLoadingIndicator];
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
                else
                {
                    // if silent-fail, just change to the unlock button
                    [self updateForProductInfoChanged];
                }
            }
        }
        else
        {
            [self updateForProductInfoChanged];
        }
    }
}

- (void) hideFlyerProductInfo
{
    [_infoPane setHidden:YES];
    [_buttonsView setHidden:YES];
}

- (void) alignImageRightAnimated:(BOOL)animated
{
    CGFloat imageX = (self.view.frame.size.width - _imageView.frame.size.width) * 0.5f;
    CGAffineTransform t = CGAffineTransformMakeTranslation(imageX, 0.0f);
    if(animated)
    {
        [UIView animateWithDuration:0.2f 
                              delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [_imageView setTransform:t];
                         }
                         completion:NULL];
    }
    else
    {
        [_imageView setTransform:t];
    }
}

- (void) alignImageLeftAnimated:(BOOL)animated
{
    CGFloat imageX = -(self.view.frame.size.width - _imageView.frame.size.width) * 0.5f;
    CGAffineTransform t = CGAffineTransformMakeTranslation(imageX, 0.0f);
    if(animated)
    {
        [UIView animateWithDuration:0.2f 
                              delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [_imageView setTransform:t];
                         }
                         completion:NULL];
    }
    else
    {
        [_imageView setTransform:t];
    }
}

- (void) alignImageCenterAnimated:(BOOL)animated
{
    CGAffineTransform t = CGAffineTransformMakeTranslation(0.0f, 0.0f);
    if(animated)
    {
        [UIView animateWithDuration:0.2f 
                              delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [_imageView setTransform:t];
                         }
                         completion:NULL];
    }
    else
    {
        [_imageView setTransform:t];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // save off origin of infoPane from nib file
    _infoPaneOrigin = [_infoPane frame].origin;
    
    [self initBorder];
    [self initLabels];
    
    _buyButton.layer.cornerRadius = 4.0;
    _buyButton.layer.borderWidth = 1.0;
    _buyButton.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_flyerProductId release];
    _flyerProductId = nil;
    
    [backScrim release];
    backScrim = nil;
    [border release];
    border = nil;
    [_titleLabel release];
    _titleLabel = nil;
    [_descLabel release];
    _descLabel = nil;
    [_buyButton release];
    _buyButton = nil;
    [self setImage:nil];
    [_imageView release];
    _imageView = nil;
    [_infoPane release];
    _infoPane = nil;
    [_loadingIndicator release];
    _loadingIndicator = nil;
    [_unlockButton release];
    _unlockButton = nil;
    [_buttonsView release];
    _buttonsView = nil;
    [_gimmieTipView release];
    _gimmieTipView = nil;
    [_gimmieTipBorder release];
    _gimmieTipBorder = nil;
    [_gimmieTipLabel release];
    _gimmieTipLabel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerSKProductObservers];
    
    // hide info pane until loadFlyerInfo is called when page is settled
    [_infoPane setFrame:[self infoPaneCollapsedFrame]];
    [_infoPane setHidden:YES];
    [_buttonsView setHidden:YES];
    _isInfoPaneCollapsed = YES;
    _wasUnlockPressed = NO;
}

- (void) viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - in-app purchase

- (void) handleProductsFetched:(NSNotification *)note
{
    [self updateForProductInfoChanged];
}

- (void) handleProductsFetchFailed:(NSNotification *)note
{
    if(_wasUnlockPressed)
    {
        // show alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect to iTunes Store" 
                                                        message:@"Try again later"
                                                       delegate:self 
                                              cancelButtonTitle:@"Ok" 
                                              otherButtonTitles:nil];
        [MenuResManager getInstance].alertView = alert;
        [alert show];
        [alert release];    
    }
    [self updateForProductInfoChanged];
}

- (void) handleSKTransactionCanceled:(NSNotification *)note
{
    [MBProgressHUD hideHUDForView:self.view.window animated:YES];
}

- (void) handleSKTransactionFailed:(NSNotification *)note
{
    [MBProgressHUD hideHUDForView:self.view.window animated:YES];  
    
    if([note userInfo])
    {
        SKPaymentTransaction* noteTransaction = [note.userInfo objectForKey:@"transaction"];
        if([noteTransaction.payment.productIdentifier isEqualToString:[self flyerProductId]])
        {
            // show alert if this pertains to my flyer
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect to iTunes Store" 
                                                            message:@"Try again later"
                                                           delegate:self 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil];
            [MenuResManager getInstance].alertView = alert;
            [alert show];
            [alert release];    
        }
    }
}

- (void) handleSKTransactionSucceeded:(NSNotification *)note
{
    [MBProgressHUD hideHUDForView:self.view.window animated:YES];  
    
    if([note userInfo])
    {
        SKPaymentTransaction* noteTransaction = [note.userInfo objectForKey:@"transaction"];
        if([noteTransaction.payment.productIdentifier isEqualToString:[self flyerProductId]])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Completed"
                                                            message:nil
                                                           delegate:self 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil];
            [MenuResManager getInstance].alertView = alert;
            [alert show];
            [alert release];  
            [self updateForProductInfoChanged];
        }
    }
}



#pragma mark - accessors
- (UIImage*) image
{
    return [_imageView image];
}

- (void) setImage:(UIImage *)image
{
    _imageView.image = image;
}

#pragma mark - button actions
- (void) buyButtonPressed:(id)sender
{
    _wasUnlockPressed = NO;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    hud.labelText = @"Purchase in progress";

    // buy it
    [[ProductManager getInstance] purchaseUpgradeByProductID:[self flyerProductId]];
} 

- (void) unlockButtonPressed:(id)sender
{
    NSLog(@"load product info again");
    _wasUnlockPressed = YES;
    [self loadFlyerProductInfoSilent:NO];
}

- (IBAction)descPressed:(id)sender 
{
    if(_isInfoPaneCollapsed)
    {
        [self expandInfoPaneForDuration:INFOPANE_DURATION];
    }
}

- (CGRect) infoPaneCollapsedFrame
{
    CGRect myFrame = [_infoPane frame];
    myFrame.origin.y = _buttonsView.frame.origin.y;
    myFrame.size.height = _buttonsView.frame.size.height;
    return myFrame;
}

- (CGRect) infoPaneExpandedFrame
{
    CGRect myFrame = [_infoPane frame];
    myFrame.origin.y = _infoPaneOrigin.y;
    myFrame.size.height = (_buttonsView.frame.origin.y - _infoPaneOrigin.y) + _buttonsView.frame.size.height;
    return myFrame;
}

- (CGRect) gimmieTipFrame
{
    CGRect expandedInfoPaneFrame = [self infoPaneExpandedFrame];
    CGRect myFrame = [_gimmieTipView bounds];
    myFrame.origin.x = expandedInfoPaneFrame.origin.x;
    myFrame.origin.y = expandedInfoPaneFrame.origin.y - myFrame.size.height;
    return myFrame;
}

- (void) collapseInfoPaneAfterDelay:(NSTimeInterval)delay
{
    [UIView animateWithDuration:0.1f 
                          delay:delay 
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         CGRect myFrame = [self infoPaneCollapsedFrame];
                         [_infoPane setFrame:myFrame];
                     }
                     completion:^(BOOL finished){
                         _isInfoPaneCollapsed = YES;
                     }];    

    // fade out gimmie tip
    [UIView animateWithDuration:0.5f 
                          delay:delay 
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [_gimmieTipView setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                         [_gimmieTipView removeFromSuperview];
                     }];    
}

- (void) expandInfoPaneForDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:0.1f 
                          delay:0.0f 
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         CGRect myFrame = [self infoPaneExpandedFrame];
                         [_infoPane setFrame:myFrame];
                     }
                     completion:^(BOOL finished){
                         _isInfoPaneCollapsed = NO;
                         [self collapseInfoPaneAfterDelay:duration];
                     }]; 
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if([alertView cancelButtonIndex] == buttonIndex)
    {
        // canceled
        [MenuResManager getInstance].alertView = nil;
    }
}
@end
