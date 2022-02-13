//
//  LootRegistryData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LootRegistryData.h"

@implementation LootRegistryData
@synthesize fileData;

- (id)initFromFilename:(NSString *)filename
{
    self = [super init];
    if (self) 
    {
        // load dictionary from file
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"];
        self.fileData = [NSDictionary dictionaryWithContentsOfFile:path];
        
        // internal cache, not retaining
        registry = [fileData objectForKey:@"lootRegistry"];
        
        // cache off the names for easier enumeration by caller 
        names = [NSMutableArray arrayWithCapacity:[registry count]];
        [names retain];
        for(NSString* curName in registry)
        {
            [names addObject:curName];
        }
    }
    
    return self;
}

- (void) dealloc
{
    [names release];
    registry = nil;

    self.fileData = nil;
    [super dealloc];
}

#pragma mark - accessor methods generic
- (unsigned int) numItems
{
    return [registry count];
}

- (NSString*) getNameAtIndex:(int)index
{
    return [names objectAtIndex:index];
}

#pragma mark - accessor methods specific
- (int) getValueForLootNamed:(NSString *)name
{
    int value = 0;
    NSDictionary* curLoot = [registry objectForKey:name];
    if(curLoot)
    {
        value = [[curLoot objectForKey:@"value"] intValue];
    }
    return value;
}

@end
