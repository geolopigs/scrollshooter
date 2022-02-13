//
//  ScrollRenderer.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/6/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "ScrollRenderer.h"
#import "Texture.h"
#import "TextureSubImage.h"
#import "LevelTileData.h"

#pragma mark - ScrollRendererTile
@implementation ScrollRendererTile
@synthesize tex;
@synthesize index;

- (id) initWithTexture:(Texture *)texture tileIndex:(unsigned int)tileIndex
{
    self = [super init];
    if(self)
    {
        self.tex = texture;
        self.index = tileIndex;
    }
    return self;
}

- (void) dealloc
{
    self.tex = nil;
    [super dealloc];
}
@end

#pragma mark -
#pragma mark ScrollRendererInstance
@implementation ScrollRendererInstance
@synthesize tiles;

- (id) initWithTiles:(NSArray *)tilesArray
{
    self = [super init];
    if(self)
    {
        self.tiles = tilesArray;
    }
    return self;
}


- (void) dealloc
{
    self.tiles = nil;
    [super dealloc];
}

@end

#pragma mark -
#pragma mark ScrollRenderer

@interface ScrollRenderer (ScrollRendererPrivate)
- (void) applySubImage:(TextureSubImage*)subImage toSector:(unsigned int)index;
- (GLuint) createRefTexWithWidth:(GLint)twidth height:(GLint)theight numSectors:(unsigned int)numSectors;
@end



@implementation ScrollRenderer

- (id) initWithTileSize:(CGSize)size numberOfTiles:(unsigned int)num texSize:(CGSize)tsize
{
    self = [super init];
	if(self)
	{
        numTiles = num;
        tileSize = size;
        
        // all tiles share the same texcoords
        float uMin = 0.0f;
        float vMin = 0.0f;
        float uMax = (tsize.width / [Texture toNextPowerOfTwo:tsize.width]);
        float vMax = (tsize.height / [Texture toNextPowerOfTwo:tsize.height]);
        texcoords = new GLfloat [4 * 2];
        texcoords[0] = uMin;    texcoords[1] = vMin;
        texcoords[2] = uMax;    texcoords[3] = vMin;
        texcoords[4] = uMin;    texcoords[5] = vMax;
        texcoords[6] = uMax;    texcoords[7] = vMax;
        
        // create one poly per tile
        tileVerts = new  GLfloat* [numTiles];
        for(unsigned int i = 0; i < numTiles; ++i)
        {
            tileVerts[i] = new GLfloat [4 * 3];
        }
        
        // init tile polys
        {
            
            const float x = 0.0f;
            float y = 0.0f;
            
            unsigned int vertRow = 0;
            unsigned int tileIndex = 0;
            
            // left of the first poly
            tileVerts[tileIndex][0] = x;
            tileVerts[tileIndex][1] = y + (vertRow * tileSize.height);
            tileVerts[tileIndex][2] = 1.0f;
            
            // right of the first poly
            tileVerts[tileIndex][3]	= x + tileSize.width;
            tileVerts[tileIndex][4]	= y + (vertRow * tileSize.height);
            tileVerts[tileIndex][5]	= 1.0f;

            ++vertRow;
            while(vertRow < numTiles)
            {
                // top edge of current poly
                // left
                tileVerts[tileIndex][6] = x;
                tileVerts[tileIndex][7] = y + (vertRow * tileSize.height);
                tileVerts[tileIndex][8] = 1.0f;
                
                // right
                tileVerts[tileIndex][9]	= x + tileSize.width;
                tileVerts[tileIndex][10]	= y + (vertRow * tileSize.height);
                tileVerts[tileIndex][11]	= 1.0f;
                
                // bot edge of next poly
                // left
                tileVerts[tileIndex+1][0] = tileVerts[tileIndex][6];
                tileVerts[tileIndex+1][1] = tileVerts[tileIndex][7];
                tileVerts[tileIndex+1][2] = tileVerts[tileIndex][8];
                
                // right
                tileVerts[tileIndex+1][3]	= tileVerts[tileIndex][9];
                tileVerts[tileIndex+1][4]	= tileVerts[tileIndex][10];
                tileVerts[tileIndex+1][5]	= tileVerts[tileIndex][11];
                
                ++tileIndex;
                ++vertRow;
            }
            
            // top edge of last poly
            // left
            tileVerts[tileIndex][6] = x;
            tileVerts[tileIndex][7] = y + (vertRow * tileSize.height);
            tileVerts[tileIndex][8] = 1.0f;
            
            // right
            tileVerts[tileIndex][9]	= x + tileSize.width;
            tileVerts[tileIndex][10]	= y + (vertRow * tileSize.height);
            tileVerts[tileIndex][11]	= 1.0f;
        }
    }
	return self;    
}



- (void) dealloc
{
    for(unsigned int i = 0; i < numTiles; ++i)
    {
        delete [] tileVerts[i];
    }
    delete [] tileVerts;
    delete [] texcoords;
    
	[super dealloc];
}


#pragma mark -
#pragma mark Private methods
- (GLuint) createRefTexWithWidth:(GLint)twidth height:(GLint)theight numSectors:(unsigned int)numSectors
{	
    GLuint texName;
    
	// texture dimensions must be power of two; so, round up
	size_t width = [Texture toNextPowerOfTwo:twidth];
	size_t height = [Texture toNextPowerOfTwo:theight] * numSectors;
	
	glEnable(GL_TEXTURE_2D);	
	
	glGenTextures(1, &texName);

	// no need to populate the ref texture with anything useful; so, just load it from an arbitrarily small chunk
    GLubyte* texData = new GLubyte[width * height * 3];
	glBindTexture(GL_TEXTURE_2D, texName);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texData);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    delete [] texData;
    
    texWidth = width;    
    texHeight = height;
    
    return texName;
}

- (void) applySubImage:(TextureSubImage*)subImage toSector:(unsigned int)index
{
    assert(index < numTiles);
    int xoffset = 0;
    int texSectorHeight = texHeight / numSwapSectors;
    int yoffset = index * texSectorHeight;
    [subImage applySubImageAtOffset:CGPointMake(xoffset, yoffset)];
}


#pragma mark -
#pragma mark DrawDelegate
- (void) draw:(ScrollRendererInstance*)instanceInfo
{
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glPushMatrix();
	glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

    if(instanceInfo)
    {
        unsigned int i = 0;
        for(ScrollRendererTile* cur in instanceInfo.tiles)
        {
            glBindTexture(GL_TEXTURE_2D, cur.tex.texName);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glVertexPointer(3, GL_FLOAT, 0, tileVerts[[cur index]]);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);	
            ++i;
        }
    }
    
	glPopMatrix();		
}

@end
