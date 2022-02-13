//
//  SpawnersData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "SpawnersData.h"

@implementation SpawnersData
@synthesize fileData = _fileData;

- (id)initFromFilename:(NSString *)filename
{
    self = [super init];
    if (self) 
    {
        // load dictionary from file
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"];
        self.fileData = [NSDictionary dictionaryWithContentsOfFile:path];
        
        // internal cache, not retaining
        registry = [_fileData objectForKey:@"spawners"];
        
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
- (unsigned int) numGroups
{
    return [registry count];
}

- (NSString*) getNameAtIndex:(int)index
{
    return [names objectAtIndex:index];
}

#pragma mark - accessor methods specific
- (CGPoint) getOffsetAtIndex:(unsigned int)index forGroup:(NSString *)groupname
{
    CGPoint result = CGPointMake(0.0f, 0.0f);
    NSDictionary* curGroup = [registry objectForKey:groupname];
    if(curGroup)
    {
        NSArray* curGroupPoints = [curGroup objectForKey:@"points"];
        NSDictionary* offsetData = [curGroupPoints objectAtIndex:index];
        result.x = [[offsetData objectForKey:@"offsetX"] floatValue];
        result.y = [[offsetData objectForKey:@"offsetY"] floatValue];
    }
    return result;
}

- (unsigned int) getNumForGroup:(NSString *)groupname
{
    unsigned int result = 0;
    NSDictionary* curGroup = [registry objectForKey:groupname];
    if(curGroup)
    {
        result = [[curGroup objectForKey:@"points"] count];
    }
    return result;
}

- (NSDictionary*) getSpawnAnimInfoForGroup:(NSString *)groupname
{
    // spawn only has one anim; so, return the first entry
    NSDictionary* result = [self getComponentInfoForGroup:groupname atIndex:0];
    return result;
}

- (unsigned int) getNumComponentsForGroup:(NSString *)groupname
{
    unsigned int result = 0;
    NSDictionary* curGroup = [registry objectForKey:groupname];
    if(curGroup)
    {
        NSArray* animArray = [curGroup objectForKey:@"anim"];
        if(animArray)
        {
            result = [animArray count];
        }
    }
    return result;
}

- (NSDictionary*) getComponentInfoForGroup:(NSString *)groupname atIndex:(unsigned int)index
{
    NSDictionary* result = nil;
    NSDictionary* curGroup = [registry objectForKey:groupname];
    if(curGroup)
    {
        // only one spawnAnim per group; so, get the first entry
        NSArray* animArray = [curGroup objectForKey:@"anim"];
        if(animArray && (index < [animArray count]))
        {
            result = [animArray objectAtIndex:index];
        }
    }
    return result;
}

@end
