//
//  EnemyRegistryData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "EnemyRegistryData.h"

@implementation EnemyRegistryData
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
        registry = [fileData objectForKey:@"enemyRegistry"];
        
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
- (int) getPointsForEnemyNamed:(NSString *)name
{
    int points = 0;
    NSDictionary* curEnemy = [registry objectForKey:name];
    if(curEnemy)
    {
        points = [[curEnemy objectForKey:@"points"] intValue];
    }
    return points;
}

@end
