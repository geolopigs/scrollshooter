//
//  LevelPathData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LevelPathData.h"
#import "CamPath.h"

@interface LevelPathData (PrivateMethods)
- (void) initCamPathsDictionary;
@end

@implementation LevelPathData
@synthesize fileData;
@synthesize pathsDictionary;

- (id) initFromFilename:(NSString*)filename
{
    self = [super init];
    if(self)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"];
        self.fileData = [NSDictionary dictionaryWithContentsOfFile:path];
        self.pathsDictionary = [NSMutableDictionary dictionary];
        [self initCamPathsDictionary];
    }
    return self;
}

- (void) dealloc
{
    self.pathsDictionary = nil;
    self.fileData = nil;
    [super dealloc];
}

- (CamPath*) getPathForLayername:(NSString*)layerName
{
    CamPath* path = [self.pathsDictionary objectForKey:layerName];
    return path;
}

- (void) duplicatePathNamed:(NSString*)srcName toName:(NSString*)tgtName
{
    NSArray* pathsArray = [self.fileData objectForKey:@"scrollingPaths"];
    for(NSDictionary* curPath in pathsArray)
    {
        NSString* layerName = [curPath objectForKey:@"layerName"];
        if([srcName isEqualToString:layerName])
        {
            NSArray* controlPoints = [curPath objectForKey:@"controlPoints"];
            CamPath* newPath = [[CamPath alloc] initFromPointsArray:controlPoints];
            [self.pathsDictionary setObject:newPath forKey:tgtName];
            [newPath release];
        }
    }    
}


#pragma mark -
#pragma mark Private Methods
- (void) initCamPathsDictionary
{
    NSArray* pathsArray = [self.fileData objectForKey:@"scrollingPaths"];
    for(NSDictionary* curPath in pathsArray)
    {
        NSString* layerName = [curPath objectForKey:@"layerName"];
        NSArray* controlPoints = [curPath objectForKey:@"controlPoints"];
        CamPath* newPath = [[CamPath alloc] initFromPointsArray:controlPoints];
        [self.pathsDictionary setObject:newPath forKey:layerName];
        [newPath release];
    }
}

@end
