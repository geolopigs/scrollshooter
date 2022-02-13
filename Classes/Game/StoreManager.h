//
//  StoreManager.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

enum FreeCoinsAction
{
    FREECOINS_ACTION_FOLLOWTWITTER = 0,
    FREECOINS_ACTION_LIKEFACEBOOK,
    
    FREECOINS_ACTION_NUM
};

@interface StoreManager : NSObject
{
    NSDictionary* _fileData;
    NSArray* _categories;
    NSDictionary* _registry;
}

// registry query methods
- (unsigned int) numCategories;
- (NSDictionary*) categoryInfoAtIndex:(unsigned int)categoryIndex;
- (NSString*) categoryTitleForIndex:(unsigned int)categoryIndex;
- (NSString*) categoryIdForIndex:(unsigned int)categoryIndex;
- (unsigned int) numItemsForCategory:(const NSString*)categoryId;
- (NSDictionary*) getItemAtIndex:(unsigned int)index forCategory:(const NSString*)categoryId;
- (NSDictionary*) getItemForIdentifier:(const NSString* const)identifier category:(const NSString* const)caterogyId;
- (BOOL) isSingleUseCategory:(const NSString* const)categoryId;


// item query methods
- (NSString*) titleForItem:(NSDictionary*)item;
- (NSString*) descForItem:(NSDictionary*)item;
- (NSString*) descShortForItem:(NSDictionary*)item;
- (NSString*) identifierForItem:(NSDictionary*)item;
- (unsigned int) priceForItem:(NSDictionary*)item atTier:(unsigned int)priceTier;
- (unsigned int) numPriceTiersForItem:(NSDictionary*)item;
- (UIColor*) imageColorForItem:(NSDictionary*)item;
- (NSString*) imageNameForItem:(NSDictionary*)item;
- (BOOL) hasImageColorForItem:(NSDictionary*)item;
- (BOOL) isSingleUseItem:(NSDictionary*)item;
- (unsigned int) actionForItem:(NSDictionary*)item;

// non-store items
- (unsigned int) priceForContinueGame;

// helper methods
+ (NSString*) pogcoinsStringForAmount:(unsigned int)amount;

// singleton
+(StoreManager*) getInstance;
+(void) destroyInstance;


@end
