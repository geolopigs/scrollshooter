//
//  SpriteLayerData.h
//  Pogditor
//
//  Created by Shu Chiun Cheah on 7/24/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpriteObject : NSObject
{
    CGPoint     pos;
    CGSize      size;
    CGPoint     scale;
    float       rotate;
    NSUInteger  textureId;
    NSString*   textureName;
    
    // editor only data
    CGPoint     screenPos;
    CGPoint     cameraPos;
    CGPoint     cameraScale;    
}
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGSize size;
@property (nonatomic,assign) CGPoint scale;
@property (nonatomic,assign) float rotate;
@property (nonatomic,assign) NSUInteger textureId;
@property (nonatomic,retain) NSString* textureName;
@property (nonatomic,assign) CGPoint screenPos;
@property (nonatomic,assign) CGPoint cameraPos;
@property (nonatomic,assign) CGPoint cameraScale;
- (id) initSpriteObjectAtPos:(CGPoint)position size:(CGSize)spriteSize scale:(CGPoint)spriteScale rotate:(float)spriteRotate texture:(NSUInteger)textureIndex textureName:(NSString*)name screenPos:(CGPoint)screenPoint cameraPos:(CGPoint)cameraOrigin cameraScale:(CGPoint)camScale;
@end

@interface GroundObject : NSObject
{
    CGPoint     pos;
    NSString*   spawnerName;
    NSString*   objectName;
    
    // editor only data
    CGSize      size;
    CGPoint     screenPos;
    CGPoint     cameraPos;
    CGPoint     cameraScale;
}
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) NSString* spawnerName;
@property (nonatomic,assign) NSString* objectName;
@property (nonatomic,assign) CGSize size;
@property (nonatomic,assign) CGPoint screenPos;
@property (nonatomic,assign) CGPoint cameraPos;
@property (nonatomic,assign) CGPoint cameraScale;
- (id) initGroundObjectAtPos:(CGPoint)position
                 spawnerName:(NSString*)spawner
                  objectName:(NSString*)object
                        size:(CGSize)spriteSize
                   screenPos:(CGPoint)screenPoint
                   cameraPos:(CGPoint)cameraPoint
                 cameraScale:(CGPoint)cameraScale;
@end

@interface SpriteLayerData : NSObject
{
    NSString* layerName;
    float layerDistance;
    BOOL isDynamics;
    NSMutableSet* textureNames;
    NSMutableArray* spriteObjects;
    NSMutableArray* gunObjects;
    NSMutableArray* cargoObjects;
}
@property (nonatomic,retain) NSString* layerName;
@property (nonatomic,assign) float layerDistance;
@property (nonatomic,assign) BOOL isDynamics;
@property (nonatomic,retain) NSMutableSet* textureNames;
@property (nonatomic,retain) NSMutableArray* spriteObjects;
@property (nonatomic,retain) NSMutableArray* gunObjects;
@property (nonatomic,retain) NSMutableArray* cargoObjects;
- (id)initLayerNamed:(NSString*)name AtDistance:(float)distance isDynamics:(BOOL)isDynamicsLayer;
- (void) addSpriteObjectAtPos:(CGPoint)pos withSize:(CGSize)size scale:(CGPoint)scale rotate:(float)rotate withTextureName:(NSString*)name screenPos:(CGPoint)screenPos cameraPos:(CGPoint)cameraPos cameraScale:(CGPoint)cameraScale;
- (void) addGunObjectAtPos:(CGPoint)pos 
           withSpawnerName:(NSString*)spawnerName
            withObjectName:(NSString*)objectName
                  withSize:(CGSize)size 
                 screenPos:(CGPoint)screenPos 
                 cameraPos:(CGPoint)cameraPos
               cameraScale:(CGPoint)givenCameraScale;
- (void) addCargoObjectAtPos:(CGPoint)pos
             withSpawnerName:(NSString*)spawnerName
              withObjectName:(NSString*)objectName
                    withSize:(CGSize)size 
                   screenPos:(CGPoint)screenPos 
                   cameraPos:(CGPoint)cameraPos
                 cameraScale:(CGPoint)givenCameraScale;
@end
