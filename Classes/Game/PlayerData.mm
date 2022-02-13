//
//  PlayerData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "PlayerData.h"
#import "PlayerInventory.h"

static NSString* const POGCOINS = @"pogCoins";
static NSString* const INVENTORY_KEY = @"inventory";
static NSString* const HANGAR_KEY = @"hangar";
static NSString* const APPVERSION_KEY = @"appVersion";
static NSString* const TRANSACTIONRECEIPTS_KEY = @"transactionReceipts";

static unsigned int INITPLAYERCOINS = 100;  // start first-time players out with some coins

@interface PlayerData (PrivateMethods)
- (void) createNewInventory;
- (void) createNewHangar;
@end

@implementation PlayerData
@synthesize pogCoins;
@synthesize inventory = _inventory;
@synthesize hangar = _hangar;
@synthesize transactionReceipts = _transactionReceipts;

- (id)init
{
    self = [super init];
    if (self) 
    {
        pogCoins = INITPLAYERCOINS;
        [self createNewInventory];
        [self createNewHangar];
        _transactionReceipts = [[NSMutableArray arrayWithCapacity:1] retain];
    }
    return self;
}

- (void) dealloc
{
    [_transactionReceipts release];
    [_hangar release];
    [_inventory release];
    [super dealloc];
}

- (void) createNewInventory
{
    _inventory = [[NSMutableDictionary dictionary] retain];
    
    // insert the version from which the player inventory is first created for future references
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    [_inventory setObject:versionString forKey:APPVERSION_KEY];
    
    // init inventory entries
    [[PlayerInventory getInstance] fixupPlayerInventoryForData:self];
}

- (void) createNewHangar
{
    _hangar = [[NSMutableDictionary dictionary] retain];

    // insert the version from which the player inventory is first created for future references
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    [_hangar setObject:versionString forKey:APPVERSION_KEY];
}

#pragma mark -
#pragma mark NSCoding methods

- (void) encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:[NSNumber numberWithUnsignedInt:pogCoins] forKey:POGCOINS];
    [coder encodeObject:[self inventory] forKey:INVENTORY_KEY];
    [coder encodeObject:[self hangar] forKey:HANGAR_KEY];
    [coder encodeObject:[self transactionReceipts] forKey:TRANSACTIONRECEIPTS_KEY];
}

- (id) initWithCoder:(NSCoder *) decoder
{
    NSNumber* coinsNumber = [decoder decodeObjectForKey:POGCOINS];
    self.pogCoins = [coinsNumber unsignedIntValue];
    
    NSMutableDictionary* decodedInventory = [decoder decodeObjectForKey:INVENTORY_KEY];
    if(decodedInventory)
    {
        self.inventory = decodedInventory;
        
        // update inventory structure to match latest structure in the game
        [[PlayerInventory getInstance] fixupPlayerInventoryForData:self];
    }
    else
    {
        [self createNewInventory];
    }
    
    NSMutableDictionary* decodedHangar = [decoder decodeObjectForKey:HANGAR_KEY];
    if(decodedHangar)
    {
        self.hangar = decodedHangar;
    }
    else
    {
        [self createNewHangar];
    }
    
    NSMutableArray* decodedReceipts = [decoder decodeObjectForKey:TRANSACTIONRECEIPTS_KEY];
    if(decodedReceipts)
    {
        self.transactionReceipts = decodedReceipts;
    }
    else
    {
        _transactionReceipts = [[NSMutableArray arrayWithCapacity:1] retain];
    }
    
	return self;
}

@end
