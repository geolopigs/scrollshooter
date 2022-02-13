//
//  ScrollRenderer.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/6/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import "DrawCommand.h"

@class Texture;
@interface ScrollRendererTile : NSObject
{
    Texture* tex;
    unsigned int index;
}
@property (nonatomic,retain) Texture* tex;
@property (nonatomic,assign) unsigned int index;
- (id) initWithTexture:(Texture*)texture tileIndex:(unsigned int)tileIndex;
@end

@interface ScrollRendererInstance : NSObject
{
    NSArray*        tiles;
}
@property (nonatomic,retain) NSArray* tiles;

- (id) initWithTiles:(NSArray*)tilesArray;
@end

@interface ScrollRenderer : NSObject<DrawDelegate>
{
    CGSize          tileSize;
    unsigned int    numTiles;
    unsigned int    numSwapSectors;
    
    GLfloat*        verts;
	GLfloat*        texcoords;
	unsigned int    numVerts;
	
 	GLuint          tex;
    size_t          texWidth;
    size_t          texHeight;
    
    GLfloat**       tileVerts;
}

- (id) initWithTileSize:(CGSize)size numberOfTiles:(unsigned int)num texSize:(CGSize)tsize;


@end
