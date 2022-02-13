//
//  FiringPathRenderer.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "FiringPathRenderer.h"
#import "Shot.h"
#import "AnimClip.h"
#import "AnimFrame.h"
#import "Texture.h"
#if defined(DEBUG)
#import "DebugOptions.h"
#endif

@implementation FiringPathInstance
@synthesize shots;
@synthesize isAnimated;
@synthesize isTrail = _isTrail;

- (id) initWithShots:(NSArray *)shotSet isAnimated:(BOOL)shotHasAnimation isTrail:(BOOL)shotIsTrail
{
    self = [super init];
    if(self)
    {
        self.shots = shotSet;
        self.isAnimated = shotHasAnimation;
        _isTrail = shotIsTrail;
    }
    return self;
}

- (void) dealloc
{
    [shots release];
    [super dealloc];
}

@end


@interface FiringPathRenderer (PrivateMethods)
#if defined(DEBUG)
- (void) initDebugVerts;
- (void) setDebugVertsWithRect:(CGRect)rect;
- (void) initDebugVerts:(GLfloat*)vertArray rect:(CGRect)rect;
#endif
@end

@implementation FiringPathRenderer
@synthesize tex;

- (id) initWithSize:(CGSize)renderSize colSize:(CGSize)colSize
{
    self = [super init];
    if(self)
    {
		verts = static_cast<GLfloat*>(malloc(3 * 4 * sizeof(GLfloat)));
		texcoords = static_cast<GLfloat*>(malloc(2 * 4 * sizeof(GLfloat)));
		
		CGFloat halfWidth = renderSize.width * 0.5f;
		CGFloat halfHeight = renderSize.height * 0.5f;
		unsigned int index = 0;
		unsigned int texIndex = 0;
		
		// bot-left
		verts[index]	= -halfWidth;
		verts[index+1]	= -halfHeight;
		verts[index+2]	= 1.0f;
		texcoords[texIndex] = 0.0f;
		texcoords[texIndex+1] = 0.0f;
		index += 3;
		texIndex += 2;
		
		// bot-right
		verts[index]	= halfWidth;
		verts[index+1]	= -halfHeight;
		verts[index+2]	= 1.0f;
		texcoords[texIndex] = 1.0f;
		texcoords[texIndex+1] = 0.0f;
		index += 3;
		texIndex += 2;
		
		// top-left
		verts[index]	= -halfWidth;
		verts[index+1]	= halfHeight;
		verts[index+2]	= 1.0f;
		texcoords[texIndex] = 0.0f;
		texcoords[texIndex+1] = 1.0f;
		index += 3;
		texIndex += 2;
		
		// top-right
		verts[index]	= halfWidth;
		verts[index+1]	= halfHeight;
		verts[index+2]	= 1.0f;
		texcoords[texIndex] = 1.0f;
		texcoords[texIndex+1] = 1.0f;
		index += 3;
		texIndex += 2;
		
		// init texnum
		tex = 0;	       
        
#if defined(DEBUG)
        if([[DebugOptions getInstance] isDebugSpriteOutlineOn])
        {
            [self initDebugVerts];
            [self setDebugVertsWithRect:CGRectMake(-(0.5f * renderSize.width), -(0.5f * renderSize.height), renderSize.width, renderSize.height)];            
        }
        else
        {
            debugVerts = nil;
        }
        if([[DebugOptions getInstance] isDebugColOutlineOn])
        {
            debugColVerts = new GLfloat[3 * 8];
            [self initDebugVerts:debugColVerts rect:CGRectMake(-(0.5f * colSize.width), -(0.5f * colSize.height), colSize.width, colSize.height)];            
        }
        else
        {
            debugColVerts = nil;
        }
#endif
    }
    return self;
}

- (void) dealloc
{
#if defined(SPRITE_DEBUGDRAW)
    delete [] debugColVerts;
    delete [] debugVerts;
#endif
	free(verts);
	free(texcoords);
	[super dealloc];
}

#pragma mark - debug dras
#if defined(DEBUG)
- (void) initDebugVerts
{
    debugVerts = new GLfloat[3 * 8];
}

- (void) setDebugVertsWithRect:(CGRect)rect
{
    assert(debugVerts);
    unsigned int index = 0;
    
    CGPoint topRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
    CGPoint topLeft = CGPointMake(rect.origin.x, rect.origin.y);
    CGPoint botLeft = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
    CGPoint botRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    
    // top edge
    debugVerts[index] = topRight.x;
    debugVerts[index+1] = topRight.y;
    debugVerts[index+2] = 0.0f;
    index += 3;
    debugVerts[index] = topLeft.x;
    debugVerts[index+1] = topLeft.y;
    debugVerts[index+2] = 0.0f;
    index += 3;
    
    // left edge
    debugVerts[index] = topLeft.x;
    debugVerts[index+1] = topLeft.y;
    debugVerts[index+2] = 0.0f;
    index += 3;
    debugVerts[index] = botLeft.x;
    debugVerts[index+1] = botLeft.y;
    debugVerts[index+2] = 0.0f;
    index += 3;
    
    // bot edge
    debugVerts[index] = botLeft.x;
    debugVerts[index+1] = botLeft.y;
    debugVerts[index+2] = 0.0f;
    index += 3;
    debugVerts[index] = botRight.x;
    debugVerts[index+1] = botRight.y;
    debugVerts[index+2] = 0.0f;
    index += 3;
    
    // right edge
    debugVerts[index] = botRight.x;
    debugVerts[index+1] = botRight.y;
    debugVerts[index+2] = 0.0f;
    index += 3;
    debugVerts[index] = topRight.x;
    debugVerts[index+1] = topRight.y;
    debugVerts[index+2] = 0.0f;
}

- (void) initDebugVerts:(GLfloat *)vertArray rect:(CGRect)rect
{
    unsigned int index = 0;
    
    CGPoint topRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
    CGPoint topLeft = CGPointMake(rect.origin.x, rect.origin.y);
    CGPoint botLeft = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
    CGPoint botRight = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    
    // top edge
    vertArray[index] = topRight.x;
    vertArray[index+1] = topRight.y;
    vertArray[index+2] = 0.0f;
    index += 3;
    vertArray[index] = topLeft.x;
    vertArray[index+1] = topLeft.y;
    vertArray[index+2] = 0.0f;
    index += 3;
    
    // left edge
    vertArray[index] = topLeft.x;
    vertArray[index+1] = topLeft.y;
    vertArray[index+2] = 0.0f;
    index += 3;
    vertArray[index] = botLeft.x;
    vertArray[index+1] = botLeft.y;
    vertArray[index+2] = 0.0f;
    index += 3;
    
    // bot edge
    vertArray[index] = botLeft.x;
    vertArray[index+1] = botLeft.y;
    vertArray[index+2] = 0.0f;
    index += 3;
    vertArray[index] = botRight.x;
    vertArray[index+1] = botRight.y;
    vertArray[index+2] = 0.0f;
    index += 3;
    
    // right edge
    vertArray[index] = botRight.x;
    vertArray[index+1] = botRight.y;
    vertArray[index+2] = 0.0f;
    index += 3;
    vertArray[index] = topRight.x;
    vertArray[index+1] = topRight.y;
    vertArray[index+2] = 0.0f;
}
#endif

#pragma mark -
#pragma mark DrawDelegate
- (void) draw:(FiringPathInstance*)instanceInfo
{
    //glDisable(GL_TEXTURE_2D);
	glEnable(GL_TEXTURE_2D);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
	glVertexPointer(3, GL_FLOAT, 0, verts);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);

    if(!instanceInfo.isAnimated)
    {
        glBindTexture(GL_TEXTURE_2D, tex);
    }
    unsigned int shotIndex = 0;
    for(Shot* cur in instanceInfo.shots)
    {
        float rotateDegrees = cur.rotate;
        if(instanceInfo.isAnimated)
        {
            // if animated, each shot animates independently with one another
            AnimFrame* curFrame = [[cur animClip] currentFrame];
            if(instanceInfo.isTrail)
            {
                // if trail, show the remaining anim frames for the end of the trail
                unsigned int frameIndex = 0;
                if([[cur animClip] numFrames] > shotIndex)
                {
                    frameIndex = [[cur animClip] numFrames] - shotIndex - 1;
                }
                curFrame = [[cur animClip] currentFrameAtIndex:frameIndex];
                
                // also set color from animframe
                glColor4f([curFrame colorR], [curFrame colorG], [curFrame colorB], [curFrame colorA]);
            }
            
            glBindTexture(GL_TEXTURE_2D, [[curFrame texture] texName]);
            rotateDegrees += ([curFrame renderRotate] * 180.0f);
        }
        glPushMatrix();
        glTranslatef(cur.pos.x, cur.pos.y, 0.0f);
        glRotatef(rotateDegrees, 0.0f, 0.0f, 1.0f);
        glScalef(cur.scale.x, cur.scale.y, 1.0f);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);		
        glPopMatrix();	
        ++shotIndex;
    }
    
#if defined(DEBUG)
    if(([[DebugOptions getInstance] isDebugSpriteOutlineOn]) && (debugVerts))
    {
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glVertexPointer(3, GL_FLOAT, 0, debugVerts);
        glColor4f(1.0f, 0.0f, 1.0f, 1.0f);
        for(Shot* cur in instanceInfo.shots)
        {
            glPushMatrix();
            glTranslatef(cur.pos.x, cur.pos.y, 0.0f);
            glDrawArrays(GL_LINES, 0, 8);
            glPopMatrix();		
        }
    }
    
    if(([[DebugOptions getInstance] isDebugColOutlineOn]) && (debugColVerts))
    {
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glVertexPointer(3, GL_FLOAT, 0, debugColVerts);
        glColor4f(0.0f, 1.0f, 0.0f, 1.0f);
        glLineWidth(2.0f);
        for(Shot* cur in instanceInfo.shots)
        {
            glPushMatrix();
            glTranslatef(cur.pos.x, cur.pos.y, 0.0f);
            glDrawArrays(GL_LINES, 0, 8);
            glPopMatrix();		
        }
    }
#endif

}



@end
