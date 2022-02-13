//
//  AddonData.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "AddonData.h"

@implementation AddonData
@synthesize fileData;
@synthesize numWeaponLayers;

- (id)initFromFilename:(NSString *)filename
{
    self = [super init];
    if (self) 
    {
        // load dictionary from file
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"plist"];
        self.fileData = [NSDictionary dictionaryWithContentsOfFile:path];
        
        // internal cache, not retaining
        registry = [fileData objectForKey:@"addons"];
        
        // cache off the names for easier enumeration by caller 
        names = [NSMutableArray arrayWithCapacity:[registry count]];
        [names retain];
        for(NSString* curName in registry)
        {
            [names addObject:curName];
        }

        // a file has weaponLayers if it contains sets of {BoarSoloGun, TurretSingle, TurretDouble} following Base
        hasWeaponLayers = NO;
        unsigned index = 0;
        unsigned int num = [registry count];
        while(index < num)
        {
            NSString* curName = [self getNameAtIndex:index];
            if(([curName hasPrefix:@"BoarSoloGun"]) ||
               ([curName hasPrefix:@"TurretSingle"]) ||
               ([curName hasPrefix:@"TurretDouble"]))
            {
                if(!hasWeaponLayers)
                {
                    // found first layer
                    hasWeaponLayers = YES;
                    numWeaponLayers = 1;
                }
                else
                {
                    // additional layers
                    NSArray* components = [curName componentsSeparatedByString:@"_"];
                    if([components count] > 1)
                    {
                        unsigned int layerIndex = [[components objectAtIndex:1] intValue];
                        if((layerIndex+1) > numWeaponLayers)
                        {
                            numWeaponLayers = (layerIndex + 1);
                        }
                    }
                }
            }
            ++index;
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
    NSArray* curGroup = [registry objectForKey:groupname];
    if(curGroup)
    {
        NSDictionary* offsetData = [curGroup objectAtIndex:index];
        result.x = [[offsetData objectForKey:@"offsetX"] floatValue];
        result.y = [[offsetData objectForKey:@"offsetY"] floatValue];
    }
    return result;
}

- (unsigned int) getNumForGroup:(NSString *)groupname
{
    NSArray* curGroup = [registry objectForKey:groupname];
    return [curGroup count];
}
@end
