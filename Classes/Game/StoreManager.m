//
//  StoreManager.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "StoreManager.h"
#import "StatsManager.h"
#import "NSDictionary+Curry.h"

static const NSString* const POGSTORE_KEY = @"PogStore";
static const NSString* const CATEGORIES_KEY = @"Categories";
static const NSString* const ITEMS_KEY = @"Items";
static const NSString* const IMAGE_LKEY = @"Image";
static const NSString* const TITLE_KEY = @"Title";
static const NSString* const DESC_KEY = @"Description";
static const NSString* const DESCSHORT_KEY = @"DescriptionShort";
static const NSString* const ID_KEY = @"Identifier";
static const NSString* const PRICE_KEY = @"Price";
static const NSString* const ISSINGLEUSE_KEY = @"isSingleUse";
static const NSString* const ACTION_KEY = @"Action";
static const NSString* const IMAGECOLORRED_KEY = @"ImageColorR";
static const NSString* const IMAGECOLORGREEN_KEY = @"ImageColorG";
static const NSString* const IMAGECOLORBLUE_KEY = @"ImageColorB";
static const NSString* const IMAGECOLORALPHA_KEY = @"ImageColorA";
static NSString* const FOLLOWTWITTER_KEY = @"FollowTwitter";
static NSString* const LIKEFACEBOOK_KEY = @"LikeFacebook";

static const unsigned int kStoreManagerPriceContinueGame = 50;
static const unsigned int kStoreManagerPriceContinueGameIncr = 30;
static const unsigned int kStoreManagerPriceContinueGameMax = 500;

@implementation StoreManager

- (id) init
{
    self = [super init];
    if(self)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"PogStore" ofType:@"plist"];
        _fileData = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
        if(_fileData)
        {
            NSDictionary* pogStore = [_fileData objectForKey:POGSTORE_KEY];
            _categories = [[pogStore objectForKey:CATEGORIES_KEY] retain];
            _registry = [[pogStore objectForKey:ITEMS_KEY] retain];
        }
    }
    return self;
}

- (void) dealloc
{
    [_registry release];
    [_categories release];
    [_fileData release];
    [super dealloc];
}

#pragma mark - registry query methods
- (unsigned int) numCategories
{
    unsigned int result = [_categories count];
    return result;
}

- (NSDictionary*) categoryInfoAtIndex:(unsigned int)categoryIndex
{
    NSDictionary* result = nil;
    if(categoryIndex < [_categories count])
    {
        result = [_categories objectAtIndex:categoryIndex];
    }
    return result;
}

- (NSString*) categoryTitleForIndex:(unsigned int)categoryIndex
{
    NSString* result = nil;
    NSDictionary* info = [self categoryInfoAtIndex:categoryIndex];
    if(info)
    {
        result = [info objectForKey:TITLE_KEY];
    }
    return result;
}

- (NSString*) categoryIdForIndex:(unsigned int)categoryIndex
{
    NSString* result = nil;
    NSDictionary* info = [self categoryInfoAtIndex:categoryIndex];
    if(info)
    {
        result = [info objectForKey:ID_KEY];
    }
    return result;
}


- (unsigned int) numItemsForCategory:(const NSString*)categoryId
{
    unsigned int result = 0;
    NSArray* categoryArray = [_registry objectForKey:categoryId];
    if(categoryArray)
    {
        result = [categoryArray count];
    }
    return result;
}

- (NSDictionary*) getItemAtIndex:(unsigned int)index forCategory:(NSString *const)categoryId
{
    NSDictionary* result = nil;
    NSArray* categoryArray = [_registry objectForKey:categoryId];
    if(categoryArray)
    {
        if(index < [categoryArray count])
        {
            result = [categoryArray objectAtIndex:index];
        }
    }
    return result;
}

- (NSDictionary*) getItemForIdentifier:(const NSString* const)identifier category:(const NSString* const)caterogyId
{
    NSDictionary* result = nil;
    NSArray* categoryArray = [_registry objectForKey:caterogyId];
    if(categoryArray)
    {
        for(NSDictionary* cur in categoryArray)
        {
            if([identifier isEqualToString:[self identifierForItem:cur]])
            {
                result = cur;
                break;
            }
        }
    }
    return result;
}

- (BOOL) isSingleUseCategory:(const NSString *const)categoryId
{
    BOOL result = NO;
    NSString* catString = [NSString stringWithFormat:@"%@", categoryId];
    for(NSDictionary* cur in _categories)
    {
        if([catString isEqualToString:[cur objectForKey:ID_KEY]])
        {
            NSNumber* isSingleUse = [cur objectForKey:ISSINGLEUSE_KEY];
            if(isSingleUse)
            {
                result = [isSingleUse boolValue];
            }
        }
    }
    return result;
}


#pragma mark - item query methods
- (NSString*) titleForItem:(NSDictionary *)item
{
    NSString* result = [item objectForKey:TITLE_KEY];
    return result;
}

- (NSString*) descForItem:(NSDictionary *)item
{
    NSString* result = [item objectForKey:DESC_KEY];
    return result;
}

- (NSString*) descShortForItem:(NSDictionary *)item
{
    NSString* result = [item objectForKey:DESCSHORT_KEY];
    if(!result)
    {
        // fall back to description
        result = [item objectForKey:DESC_KEY];
    }
    return result;
}

- (NSString*) identifierForItem:(NSDictionary *)item
{
    NSString* result = [item objectForKey:ID_KEY];
    return result;
}

- (unsigned int) priceForItem:(NSDictionary*)item atTier:(unsigned int)priceTier
{
    NSArray* prices = [item objectForKey:PRICE_KEY];
    unsigned int index = priceTier;
    if(index >= [prices count])
    {
        index = [prices count] - 1;
    }
    unsigned int result = [[prices objectAtIndex:index] unsignedIntValue];
    return result;
}

- (unsigned int) numPriceTiersForItem:(NSDictionary*)item
{
    unsigned int num = [[item objectForKey:PRICE_KEY] count];
    return num;
}

- (NSString*) imageNameForItem:(NSDictionary*)item
{
    NSString* result = [item objectForKey:IMAGE_LKEY];
    return result;
}

- (UIColor*) imageColorForItem:(NSDictionary*)item
{
    float colorR, colorG, colorB, colorA;
    NSNumber* red = [item objectForKey:IMAGECOLORRED_KEY];
    if(red)
    {
        colorR = [red floatValue];
    }
    else
    {
        colorR = 1.0f;
    }
    NSNumber* green = [item objectForKey:IMAGECOLORGREEN_KEY];
    if(green)
    {
        colorG = [green floatValue];
    }
    else
    {
        colorG = 1.0f;
    }
    NSNumber* blue = [item objectForKey:IMAGECOLORBLUE_KEY];
    if(blue)
    {
        colorB = [blue floatValue];
    }
    else
    {
        colorB = 1.0f;
    }
    NSNumber* alpha = [item objectForKey:IMAGECOLORALPHA_KEY];
    if(alpha)
    {
        colorA = [alpha floatValue];
    }
    else
    {
        colorA = 1.0f;
    }
    
    return [UIColor colorWithRed:colorR green:colorG blue:colorB alpha:colorA];
}

- (BOOL) hasImageColorForItem:(NSDictionary *)item
{
    BOOL result = NO;
    NSNumber* red = [item objectForKey:IMAGECOLORRED_KEY];
    NSNumber* green = [item objectForKey:IMAGECOLORGREEN_KEY];
    NSNumber* blue = [item objectForKey:IMAGECOLORBLUE_KEY];
    NSNumber* alpha = [item objectForKey:IMAGECOLORALPHA_KEY];
    if(red && green && blue && alpha)
    {
        result = YES;
    }
    return result;
}

- (BOOL) isSingleUseItem:(NSDictionary *)item
{
    BOOL result = [item getBoolForKey:(NSString*)ISSINGLEUSE_KEY];
    return result;
}

- (unsigned int) actionForItem:(NSDictionary *)item
{
    unsigned int result = FREECOINS_ACTION_FOLLOWTWITTER;
    NSString* actionString = [item objectForKey:ACTION_KEY];
    if(actionString)
    {
        if([FOLLOWTWITTER_KEY isEqualToString:actionString])
        {
            result = FREECOINS_ACTION_FOLLOWTWITTER;
        }
        else if([LIKEFACEBOOK_KEY isEqualToString:actionString])
        {
            result = FREECOINS_ACTION_LIKEFACEBOOK;
        }
    }
    return result;
}

#pragma mark - non-store items
- (unsigned int) priceForContinueGame
{
    unsigned int priceIncr = ([[StatsManager getInstance] sessionContinueCount] * kStoreManagerPriceContinueGameIncr);
    unsigned int result = kStoreManagerPriceContinueGame + priceIncr;
    if(result > kStoreManagerPriceContinueGameMax)
    {
        result = kStoreManagerPriceContinueGameMax;
    }
    return result;
}

#pragma mark - helper methods
+ (NSString*) pogcoinsStringForAmount:(unsigned int)amount
{
    NSNumberFormatter *priceStyle = [[NSNumberFormatter alloc] init];
    
    // set options.
    [priceStyle setFormatterBehavior:[NSNumberFormatter defaultFormatterBehavior]];
    [priceStyle setNumberStyle:NSNumberFormatterCurrencyStyle];
    [priceStyle setMaximumFractionDigits:0];
    [priceStyle setCurrencySymbol:@""];
    
    // get formatted string
    NSString* formatted = [priceStyle stringFromNumber:[NSNumber numberWithUnsignedInt:amount]]; 
    return formatted;
}



#pragma mark - Singleton
static StoreManager* singleton = nil;
+ (StoreManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[StoreManager alloc] init] retain];
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
