//
//  ProductManager.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/12/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "ProductManager.h"
#import "Reachability.h"
#import "PlayerInventoryIds.h"
#import "PlayerInventory.h"
#import "PogAnalytics+PeterPog.h"

NSString* const POGCOINS_STARTERPACK = @"com.geolopigs.peterpog2.pogcoinsstarter";
NSString* const POGCOINS_COURIERPACK = @"com.geolopigs.peterpog2.pogcoinscourier";
NSString* const POGCOINS_100KPACK = @"com.geolopigs.peterpog2.pogcoins100k";
NSString* const FLYER_POGRANG = @"com.geolopigs.peterpog2.pograngflyer";
NSString* const FLYER_POGWING = @"com.geolopigs.peterpog2.pogwingflyer";

static const unsigned int POGCOINS_STARTERPACK_AMOUNT = 20000;
static const unsigned int POGCOINS_COURIERPACK_AMOUNT = 50000;
static const unsigned int POGCOINS_100KPACK_AMOUNT = 100000;

@interface ProductManager ()
@property NSInteger restoreTransactionCount;

- (void) initFlyerLocalInfo;
- (void) initCoinsLocalInfo;
- (void) deliverContentForProductIdentifier:(NSString*)productId;
@end

@implementation ProductManager
@synthesize coinProductsOrder = _coinProductsOrder;
@synthesize coinsLocalInfo = _coinsLocalInfo;
@synthesize flyerProductsOrder = _flyerProductsOrder;
@synthesize flyerImageNames = _flyerImageNames;
@synthesize flyerTypeNames = _flyerTypeNames;
@synthesize flyerLocalInfo = _flyerLocalInfo;
@synthesize imageNameLookup = _imageNameLookup;
@synthesize productsArray = _productsArray;
@synthesize productLookup = _productLookup;

- (id) init
{
    self = [super init];
    if(self)
    {
        // register myself as an observer upon startup
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        _coinProductsOrder = [[NSArray arrayWithObjects:
                           POGCOINS_ID_STARTERPACK,
                           POGCOINS_ID_COURIERPACK,
                           POGCOINS_ID_100KPACK,
                           nil] retain];
        _flyerProductsOrder = [[NSArray arrayWithObjects:
                                FLYER_POGWING,
                                FLYER_POGRANG,
                                nil] retain];
        _flyerImageNames = [[NSDictionary dictionaryWithObjects:
                            [NSArray arrayWithObjects:@"Flyer_0.png", @"Flyer_1.png", @"Flyer_2.png", nil]
                                                        forKeys:
                            [NSArray arrayWithObjects:FLYER_ID_POGWING, FLYER_ID_POGLIDER, FLYER_ID_POGRANG, nil]] retain];
        
        _imageNameLookup = [[NSDictionary dictionaryWithObjects:
                             [NSArray arrayWithObjects:@"Flyer_0.png", @"Flyer_1.png", @"Flyer_2.png",
                              @"Stash1.png", @"Stash2.png", @"Stash3.png", nil]
                                                        forKeys:
                             [NSArray arrayWithObjects:FLYER_ID_POGWING, FLYER_ID_POGLIDER, FLYER_ID_POGRANG,
                              POGCOINS_STARTERPACK, POGCOINS_COURIERPACK, POGCOINS_100KPACK, nil]] retain];
        
        // these are archetype names
        _flyerTypeNames = [[NSDictionary dictionaryWithObjects:
                             [NSArray arrayWithObjects:FLYER_TYPE_POGWING, FLYER_TYPE_POGLIDER, FLYER_TYPE_POGRANG, nil]
                                                        forKeys:
                             [NSArray arrayWithObjects:FLYER_ID_POGWING, FLYER_ID_POGLIDER, FLYER_ID_POGRANG, nil]] retain];
        _productsArray = nil;
        _productLookup = [[NSMutableDictionary dictionary] retain];
        
        [self initFlyerLocalInfo];
        [self initCoinsLocalInfo];
    }
    return self;
}

- (void) dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [_coinsLocalInfo release];
    [_flyerLocalInfo release];
    [_productLookup release];
    self.productsArray = nil;
    [_imageNameLookup release];
    [_flyerTypeNames release];
    [_flyerImageNames release];
    [_flyerProductsOrder release];
    [_coinProductsOrder release];
    [super dealloc];
}

- (void) initFlyerLocalInfo
{    
    NSDictionary* pogwingInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                     @"Pogwing", 
                                                                     @"This slim flying machine is equipped with Peter's homebrew Pogray blue laser, the most advanced known to Pogs today. Small, powerful, perfect for weaving through bullet-hell.", nil]
                                                            forKeys:[NSArray arrayWithObjects:
                                                                     @"title", 
                                                                     @"description", nil]];

    NSDictionary* pograngInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                     @"Pograng", 
                                                                     @"This is a heavy duty flying machine equipped with Boomerang weapon, the latest innovation from Peter's Lab; a close quarter fighter, perfect for the brave ones.", nil]
                                                            forKeys:[NSArray arrayWithObjects:
                                                                     @"title", 
                                                                     @"description", nil]];
    _flyerLocalInfo = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:pogwingInfo, pograngInfo, nil]
                                                  forKeys:[NSArray arrayWithObjects:FLYER_ID_POGWING, FLYER_ID_POGRANG, nil]] retain];
}

- (void) initCoinsLocalInfo
{
    NSDictionary* pack20k = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                     @"20,000 Pack", 
                                                                     @"20,000 Pogcoins to kickstart your Pog delivery service.", nil]
                                                            forKeys:[NSArray arrayWithObjects:
                                                                     @"title", 
                                                                     @"description", nil]];
    NSDictionary* pack50k = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                 @"50,000 Pack", 
                                                                 @"50,000 Pogcoins to fully equip yourself as a Pog courier.", nil]
                                                        forKeys:[NSArray arrayWithObjects:
                                                                 @"title", 
                                                                 @"description", nil]];
    NSDictionary* pack100k = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                 @"100,000 Pack", 
                                                                 @"100,000 Pogcoins of solid funding for all the upgrades you need.", nil]
                                                        forKeys:[NSArray arrayWithObjects:
                                                                 @"title", 
                                                                 @"description", nil]];
    _coinsLocalInfo = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:pack20k, pack50k, pack100k, nil]
                                                  forKeys:[NSArray arrayWithObjects:POGCOINS_ID_STARTERPACK, 
                                                           POGCOINS_ID_COURIERPACK,
                                                           POGCOINS_ID_100KPACK, nil]] retain];
}

#pragma mark - transaction methods

- (BOOL)requestProductData
{
    BOOL isInternetReachable = YES;
    Reachability* internetReach = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [internetReach currentReachabilityStatus];
    if(NotReachable == status)
    {
        isInternetReachable = NO;
    }
    
    if(isInternetReachable)
    {
        // only request if no previous request succeeded and no ongoing request
        if((nil == _productsRequest) && (0 == [self getNumProducts]))
        {
            NSSet *productIdentifiers = [NSSet setWithObjects:
                                         POGCOINS_STARTERPACK, POGCOINS_COURIERPACK, POGCOINS_100KPACK,
                                         FLYER_POGWING, FLYER_POGRANG,
                                         nil];
            _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
            _productsRequest.delegate = self;
            [_productsRequest start];
            
            // we will release the request object in the delegate callback
        }
    }
    
    return isInternetReachable;
}

- (void) purchaseUpgradeByProductID:(NSString *)productID
{
	SKProduct* productCurrent = [_productLookup objectForKey:productID];
    if(productCurrent)
    {
        SKPayment *payment = [SKPayment paymentWithProduct:productCurrent];
        [[SKPaymentQueue defaultQueue] addPayment:payment];   
    }
}

- (void) deliverContentForProductIdentifier:(NSString *)productId
{
    if([productId isEqualToString:POGCOINS_STARTERPACK])
    {
        [[PlayerInventory getInstance] addPogcoins:POGCOINS_STARTERPACK_AMOUNT];
    }
    else if([productId isEqualToString:POGCOINS_COURIERPACK])
    {
        [[PlayerInventory getInstance] addPogcoins:POGCOINS_COURIERPACK_AMOUNT];
    }
    else if([productId isEqualToString:POGCOINS_100KPACK])
    {
        [[PlayerInventory getInstance] addPogcoins:POGCOINS_100KPACK_AMOUNT];
    }
    else if([productId isEqualToString:FLYER_POGWING])
    {
        [[PlayerInventory getInstance] buyFlyerWithIdentifier:FLYER_POGWING];
    }
    else if([productId isEqualToString:FLYER_POGRANG])
    {
        [[PlayerInventory getInstance] buyFlyerWithIdentifier:FLYER_POGRANG];
    }
}

- (void) restorePurchases {
    self.restoreTransactionCount = 0;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - accessors

//
// call this before making a purchase
//
- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

- (unsigned int) getNumProducts
{
    unsigned int result = 0;
    if([self productsArray])
    {
        result = [[self productsArray] count];
    }
    return result;
}

- (unsigned int) getNumCoinProducts
{
    unsigned int result = [_coinProductsOrder count];
    return result;
}

- (unsigned int) getNumFlyerProducts
{
    unsigned int result = [_flyerProductsOrder count];
    return result;
}

- (NSString*) getImageNameForProductId:(NSString *)identifier
{
    NSString* result = [_imageNameLookup objectForKey:identifier];
    return result;
}

- (SKProduct*) getCoinProductAtIndex:(unsigned int)index
{
    SKProduct* result = nil;
    if(index < [_coinProductsOrder count])
    {
        NSString* const identifier = [_coinProductsOrder objectAtIndex:index];
        result = [_productLookup objectForKey:identifier];
    }
    return result;
}

- (NSString*) getCoinIdentifierAtIndex:(unsigned int)index
{
    NSString* result = nil;
    if(index < [_coinProductsOrder count])
    {
        result = (NSString*)[_coinProductsOrder objectAtIndex:index];
    }
    return result;
}

- (NSString*) getCoinTitleForProductId:(NSString*)identifier
{
    NSString* result = nil;
    NSDictionary* info = [_coinsLocalInfo objectForKey:identifier];
    if(info)
    {
        result = [info objectForKey:@"title"];
    }
    return result;
}

- (NSString*) getCoinDescForProductId:(NSString*)identifier
{
    NSString* result = nil;
    NSDictionary* info = [_coinsLocalInfo objectForKey:identifier];
    if(info)
    {
        result = [info objectForKey:@"description"];
    }
    return result;
}

- (SKProduct*) getFlyerProductAtIndex:(unsigned int)index
{
    SKProduct* result = nil;
    if(index < [_flyerProductsOrder count])
    {
        NSString* const identifier = [_flyerProductsOrder objectAtIndex:index];
        result = [self getFlyerProductForProductId:identifier];
    }
    return result;
}

- (SKProduct*) getFlyerProductForProductId:(NSString *)identifier
{
    SKProduct* result = nil;
    result = [_productLookup objectForKey:identifier];
    return result;
}

- (NSString*) getFlyerImageNameForProductId:(NSString *)identifier
{
    NSString* result = nil;
    result = [_flyerImageNames objectForKey:identifier];
    return result;
}

- (NSString*) getFlyerTypeNameForProductId:(NSString *)identifier
{
    NSString* result = nil;
    result = [_flyerTypeNames objectForKey:identifier];
    return result;
}

- (NSString*) getFlyerTitleForProductId:(NSString*)identifier;
{
    NSString* result = nil;
    NSDictionary* info = [_flyerLocalInfo objectForKey:identifier];
    if(info)
    {
        result = [info objectForKey:@"title"];
    }
    return result;
}

- (NSString*) getFlyerDescForProductId:(NSString*)identifier
{
    NSString* result = nil;
    NSDictionary* info = [_flyerLocalInfo objectForKey:identifier];
    if(info)
    {
        result = [info objectForKey:@"description"];
    }
    return result;
}


#pragma mark - transaction methods


//
// removes the transaction from the queue and posts a notification with the transaction result
//
- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
    if (wasSuccessful)
    {
        // send out a notification that we’ve finished the transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerTransactionSucceededNotification object:self userInfo:userInfo];
    }
    else
    {
        // send out a notification for the failed transaction
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerTransactionFailedNotification object:self userInfo:userInfo];
    }
}


//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    // record receipt
    [[PlayerInventory getInstance] recordReceiptForTransaction:transaction];
    
    // deliver product to PlayerInventory
    NSString* productId = [[transaction payment] productIdentifier];
    [self deliverContentForProductIdentifier:productId];
    
    // finish the transaction
    [self finishTransaction:transaction wasSuccessful:YES];
    
    // analytics
    [[PogAnalytics getInstance] logIAP:productId];
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [[PlayerInventory getInstance] recordReceiptForTransaction:transaction.originalTransaction];
    NSString* productId = [[[transaction originalTransaction] payment] productIdentifier];
    [self deliverContentForProductIdentifier:productId];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    else
    {
        // user just canceled
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

        // send out a notification for the canceled transaction
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerTransactionCanceledNotification object:self userInfo:userInfo];
    }
}



#pragma mark - SKPaymentTransactionObserver methods

//
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    self.restoreTransactionCount += transactions.count;
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                // do nothing
                break;
        }
    }
}

- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerRestoreFinishedNotification object:self userInfo:nil];
    if(error.code != SKErrorPaymentCancelled) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Unable to restore" message:@"Please try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerRestoreFinishedNotification object:self userInfo:nil];
    if(self.restoreTransactionCount > 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Restore Successful" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No purchases found" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    unsigned int numValidProducts = 0;
    unsigned int numInvalidProducts = 0;
    self.productsArray = [NSArray arrayWithArray:[response products]];
    [_productLookup removeAllObjects];
    for(SKProduct* cur in [self productsArray])
    {
        [_productLookup setObject:cur forKey:cur.productIdentifier];
        ++numValidProducts;
    }
    
    
	// Log invalid IDs
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
        ++numInvalidProducts;
    }
    
    // finally release the reqest we alloc/init’ed in requestProductData
    [_productsRequest release];
    _productsRequest = nil;

    if((numValidProducts == 0) && (0 < numInvalidProducts))
    {
        // if all products are invalid, treat it as a failed fetch
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerFetchFailedNotification object:self];
    }
    else
    {
        // Tell anyone who cares that we're done loading
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerProductsFetchedNotification object:self];
    }
}

- (void) request:(SKRequest *)request didFailWithError:(NSError *)error
{
    // release request
    [_productsRequest release];
    _productsRequest = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:kProductManagerFetchFailedNotification object:self];
}

#pragma mark - Singleton
static ProductManager* singleton = nil;
+ (ProductManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[ProductManager alloc] init] retain];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singleton release];
		singleton = nil;
	}
}

@end
