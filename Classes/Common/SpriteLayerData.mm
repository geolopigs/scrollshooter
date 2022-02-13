//
//  SpriteLayerData.mm
//  Pogditor
//
//  Created by Shu Chiun Cheah on 7/24/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "SpriteLayerData.h"

#pragma mark - SpriteObject
@implementation SpriteObject
@synthesize pos;
@synthesize size;
@synthesize scale;
@synthesize rotate;
@synthesize textureId;
@synthesize textureName;
@synthesize screenPos;
@synthesize cameraPos;
@synthesize cameraScale;

- (id) initSpriteObjectAtPos:(CGPoint)position size:(CGSize)spriteSize scale:(CGPoint)spriteScale rotate:(float)spriteRotate texture:(NSUInteger)textureIndex textureName:(NSString*)name screenPos:(CGPoint)screenPoint cameraPos:(CGPoint)cameraOrigin cameraScale:(CGPoint)camScale
{
    self = [super init];
    if(self)
    {
        self.pos = position;
        self.size = spriteSize;
        self.scale = spriteScale;
        self.rotate = spriteRotate;
        self.textureId = textureIndex;
        self.textureName = name;
        
        self.screenPos = screenPoint;
        self.cameraPos = cameraOrigin;
        self.cameraScale = camScale;
    }
    return self;
}

- (void) dealloc
{
    [textureName release];
    [super dealloc];
}

@end

#pragma mark - GroundObject
@implementation GroundObject
@synthesize pos;
@synthesize spawnerName;
@synthesize objectName;
@synthesize size;
@synthesize screenPos;
@synthesize cameraPos;
@synthesize cameraScale;

- (id) initGroundObjectAtPos:(CGPoint)position
                 spawnerName:(NSString*)spawner
                  objectName:(NSString*)object
                        size:(CGSize)spriteSize
                   screenPos:(CGPoint)screenPoint
                   cameraPos:(CGPoint)cameraPoint
                 cameraScale:(CGPoint)givenCameraScale
{
    self = [super init];
    if(self)
    {
        self.pos = position;
        self.spawnerName = spawner;
        self.objectName = object;
        self.size = spriteSize;
        self.screenPos = screenPoint;
        self.cameraPos = cameraPoint;
        self.cameraScale = givenCameraScale;
    }
    return self;
}

- (void) dealloc
{
    self.objectName = nil;
    self.spawnerName = nil;
    [super dealloc];
}

@end

#pragma mark - SpriteLayerData
@implementation SpriteLayerData
@synthesize layerName;
@synthesize layerDistance;
@synthesize isDynamics;
@synthesize textureNames;
@synthesize spriteObjects;
@synthesize gunObjects;
@synthesize cargoObjects;
- (id)initLayerNamed:(NSString*)name AtDistance:(float)distance isDynamics:(BOOL)isDynamicsLayer
{
    self = [super init];
    if (self) 
    {
        self.layerName = name;
        self.layerDistance = distance;
        self.isDynamics = isDynamicsLayer;
        self.textureNames = [NSMutableSet set];
        self.spriteObjects = [NSMutableArray array];
        self.gunObjects = [NSMutableArray array];
        self.cargoObjects = [NSMutableArray array];
    }
    
    return self;
}

- (void) dealloc
{
    [cargoObjects release];
    [gunObjects release];
    [spriteObjects release];
    [textureNames release];
    [layerName release];
    [super dealloc];
}

- (void) addSpriteObjectAtPos:(CGPoint)pos withSize:(CGSize)size scale:(CGPoint)scale rotate:(float)rotate withTextureName:(NSString*)name screenPos:(CGPoint)screenPos cameraPos:(CGPoint)cameraPos cameraScale:(CGPoint)cameraScale
{
    unsigned int index = 0;
    for(NSString* cur in self.textureNames)
    {
        if([name isEqualToString:cur])
        {
            SpriteObject* newObject = [[SpriteObject alloc] initSpriteObjectAtPos:pos size:size scale:scale rotate:rotate texture:index textureName:name screenPos:screenPos cameraPos:cameraPos cameraScale:cameraScale];
            [self.spriteObjects addObject:newObject];
            [newObject release];
        }
        ++index;
    }
}

- (void) addGunObjectAtPos:(CGPoint)pos 
           withSpawnerName:(NSString*)spawnerName
            withObjectName:(NSString*)objectName
                  withSize:(CGSize)size 
                 screenPos:(CGPoint)screenPos 
                 cameraPos:(CGPoint)cameraPos 
               cameraScale:(CGPoint)givenCameraScale
{
    GroundObject* newObject = [[GroundObject alloc] initGroundObjectAtPos:pos 
                                                              spawnerName:spawnerName 
                                                               objectName:objectName 
                                                                     size:size 
                                                                screenPos:screenPos 
                                                                cameraPos:cameraPos
                                                              cameraScale:givenCameraScale
                               ];
    [self.gunObjects addObject:newObject];
    [newObject release];
}

- (void) addCargoObjectAtPos:(CGPoint)pos 
             withSpawnerName:(NSString*)spawnerName
              withObjectName:(NSString*)objectName
                    withSize:(CGSize)size 
                   screenPos:(CGPoint)screenPos 
                   cameraPos:(CGPoint)cameraPos 
                 cameraScale:(CGPoint)givenCameraScale
{
    GroundObject* newObject = [[GroundObject alloc] initGroundObjectAtPos:pos 
                                                              spawnerName:spawnerName 
                                                               objectName:objectName 
                                                                     size:size 
                                                                screenPos:screenPos 
                                                                cameraPos:cameraPos 
                                                              cameraScale:givenCameraScale
                               ];
    [self.cargoObjects addObject:newObject];
    [newObject release];
}

@end
