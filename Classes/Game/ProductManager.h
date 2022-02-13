//
//  ProductManager.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/12/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

// Notifications for any observers that specific events have occurred
#define kProductManagerProductsFetchedNotification @"kProductManagerProductsFetchedNotification"
#define kProductManagerFetchFailedNotification @"kProductManagerFetchFailedNotification"
#define kProductManagerTransactionFailedNotification @"kProductManagerTransactionFailedNotification"
#define kProductManagerTransactionCanceledNotification @"kProductManagerTransactionCanceledNotification"
#define kProductManagerTransactionSucceededNotification @"kProductManagerTransactionSucceededNotification"
#define kProductManagerRestoreFinishedNotification @"kProductManagerRestoreFinishedNotification"

@interface ProductManager : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    NSArray* _coinProductsOrder;
    NSDictionary* _coinsLocalInfo;
    NSArray* _flyerProductsOrder;
    NSDictionary* _flyerImageNames;
    NSDictionary* _flyerTypeNames;
    NSDictionary* _flyerLocalInfo;
    NSDictionary* _imageNameLookup;
    NSArray* _productsArray;
    NSMutableDictionary* _productLookup;
    SKProductsRequest* _productsRequest;
}
@property (nonatomic,retain) NSArray* coinProductsOrder;
@property (nonatomic,retain) NSDictionary* coinsLocalInfo;
@property (nonatomic,retain) NSArray* flyerProductsOrder;
@property (nonatomic,retain) NSDictionary* flyerImageNames;
@property (nonatomic,retain) NSDictionary* flyerTypeNames;
@property (nonatomic,retain) NSDictionary* flyerLocalInfo;

@property (nonatomic,retain) NSDictionary* imageNameLookup;
@property (nonatomic,retain) NSArray* productsArray;
@property (nonatomic,retain) NSMutableDictionary* productLookup;

// transaction methods
- (BOOL)requestProductData;
- (void) purchaseUpgradeByProductID:(NSString *)productID;
- (void) restorePurchases;

// accessors
- (BOOL) canMakePurchases;
- (unsigned int) getNumProducts;
- (unsigned int) getNumCoinProducts;
- (unsigned int) getNumFlyerProducts;
- (SKProduct*) getCoinProductAtIndex:(unsigned int)index;
- (NSString*) getCoinIdentifierAtIndex:(unsigned int)index;
- (NSString*) getCoinTitleForProductId:(NSString*)identifier;
- (NSString*) getCoinDescForProductId:(NSString*)identifier;
- (SKProduct*) getFlyerProductAtIndex:(unsigned int)index;
- (SKProduct*) getFlyerProductForProductId:(NSString*)identifier;
- (NSString*) getFlyerImageNameForProductId:(NSString*)identifier;
- (NSString*) getFlyerTypeNameForProductId:(NSString*)identifier;
- (NSString*) getFlyerTitleForProductId:(NSString*)identifier;
- (NSString*) getFlyerDescForProductId:(NSString*)identifier;
- (NSString*) getImageNameForProductId:(NSString*)identifier;

// singleton
+(ProductManager*) getInstance;
+(void) destroyInstance;


@end
