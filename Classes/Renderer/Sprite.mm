//
//  Sprite.mm
//

#import "Sprite.h"
#import "DrawCommand.h"
#import "DebugOptions.h"

@implementation SpriteInstance
@synthesize localTranslate;
@synthesize rotate;
@synthesize pos;
@synthesize scale;
@synthesize texcoordScale;
@synthesize texcoordTranslate;
@synthesize texture;
@synthesize alpha;
@synthesize colorR;
@synthesize colorG;
@synthesize colorB;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.localTranslate = CGPointMake(0.0f, 0.0f);
        self.rotate = 0.0f;
        self.pos = CGPointMake(0.0f, 0.0f);
        self.scale = CGPointMake(1.0f, 1.0f);
        self.texcoordScale = CGPointMake(1.0f, 1.0f);
        self.texcoordTranslate = CGPointMake(0.0f, 0.0f);
        self.texture = 0;
        self.alpha = 1.0f;
        self.colorR = 1.0f;
        self.colorG = 1.0f;
        self.colorB = 1.0f;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}
@end

@interface Sprite(SpritePrivate)
#if defined(SPRITE_DEBUGDRAW)
- (void) initDebugVerts;
- (void) setDebugVertsWithRect:(CGRect)rect;
- (void) initDebugVerts:(GLfloat*)vertArray rect:(CGRect)rect;
#endif
@end


@implementation Sprite
@synthesize rotate;
@synthesize pos;
@synthesize scale;
@synthesize size;
@synthesize alpha;
@synthesize tex;
@synthesize texcoordScale;
@synthesize texcoordTranslate;

- (id) initWithSize:(CGSize)renderSize
{
	if((self = [super init]))
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

        size = renderSize;
        rotate = 0.0f;
		pos = CGPointMake(0.0f, 0.0f);
        scale = CGPointMake(1.0f, 1.0f);
        texcoordScale = CGPointMake(1.0f, 1.0f);
        texcoordTranslate = CGPointMake(0.0f, 0.0f);
        
        alpha = 1.0f;
		tex = 0;	
        
#if defined(SPRITE_DEBUGDRAW)
        debugVerts = nil;
        debugColVerts = nil;
#endif
	}
	return self;
}

- (id) initWithSize:(CGSize)renderSize colSize:(CGSize)colSize
{
  	if((self = [super init]))
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
        
        size = renderSize;
        rotate = 0.0f;
		pos = CGPointMake(0.0f, 0.0f);
        scale = CGPointMake(1.0f, 1.0f);
        texcoordScale = CGPointMake(1.0f, 1.0f);
        texcoordTranslate = CGPointMake(0.0f, 0.0f);
        
        alpha = 1.0f;
		tex = 0;	
        
#if defined(SPRITE_DEBUGDRAW)
        [self initDebugVerts];
        [self setDebugVertsWithRect:CGRectMake(-(0.5f * renderSize.width), -(0.5f * renderSize.height), renderSize.width, renderSize.height)];
        debugColVerts = new GLfloat[3 * 8];
        [self initDebugVerts:debugColVerts rect:CGRectMake(-(0.5f * colSize.width), -(0.5f * colSize.height), colSize.width, colSize.height)];
#endif
	}
	return self;  
}

- (id) initWithSize:(CGSize)renderSize colRect:(CGRect)colRect
{
  	if((self = [super init]))
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
        
        size = renderSize;
        rotate = 0.0f;
		pos = CGPointMake(0.0f, 0.0f);
        scale = CGPointMake(1.0f, 1.0f);
        texcoordScale = CGPointMake(1.0f, 1.0f);
        texcoordTranslate = CGPointMake(0.0f, 0.0f);
        
        alpha = 1.0f;
		tex = 0;	
        
#if defined(SPRITE_DEBUGDRAW)
        [self initDebugVerts];
        [self setDebugVertsWithRect:CGRectMake(-(0.5f * renderSize.width), -(0.5f * renderSize.height), renderSize.width, renderSize.height)];
        debugColVerts = new GLfloat[3 * 8];
        [self initDebugVerts:debugColVerts rect:colRect];
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

#pragma mark -
#pragma mark debug draw
#if defined(SPRITE_DEBUGDRAW)
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
- (void) draw:(SpriteInstance*)instanceInfo
{
	glEnable(GL_TEXTURE_2D);
	glPushMatrix();
    if(instanceInfo)
    {
        // instance transform
        glTranslatef(instanceInfo.pos.x, instanceInfo.pos.y, 0.0f);
        glRotatef(instanceInfo.rotate, 0.0f, 0.0f, 1.0f);
        glTranslatef(instanceInfo.localTranslate.x, instanceInfo.localTranslate.y, 0.0f);
        glScalef(instanceInfo.scale.x, instanceInfo.scale.y, 1.0f);

        // bind texture
        glBindTexture(GL_TEXTURE_2D, instanceInfo.texture);

        // set texture transform
        glMatrixMode(GL_TEXTURE);
        glPushMatrix();
        glTranslatef(instanceInfo.texcoordTranslate.x, instanceInfo.texcoordTranslate.y, 0.0f);
        glScalef(instanceInfo.texcoordScale.x, instanceInfo.texcoordScale.y, 1.0f);    
        
        // need to premultiply alpha because all textures are premultiplied alpha; so, the alpha-blend state is (one, one-minus-src-alpha)
        float myAlpha = instanceInfo.alpha;
        glColor4f(instanceInfo.colorR * myAlpha, 
                  instanceInfo.colorG * myAlpha, 
                  instanceInfo.colorB * myAlpha, 
                  myAlpha); 
    }
    else
    {
        glBindTexture(GL_TEXTURE_2D, tex);
        glTranslatef(pos.x, pos.y, 0.0f);
        glRotatef(rotate, 0.0f, 0.0f, 1.0f);
        glColor4f(alpha, alpha, alpha, alpha); 
    }
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
	glVertexPointer(3, GL_FLOAT, 0, verts);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);	
	
    glPopMatrix();  // GL_TEXTURE
    
    glMatrixMode(GL_MODELVIEW);
	glPopMatrix();  // GL_MODELVIEW
    
#if defined(SPRITE_DEBUGDRAW)
    if(([[DebugOptions getInstance] isDebugSpriteOutlineOn]) && (debugVerts))
    {
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glPushMatrix();
        if(instanceInfo)
        {
            glTranslatef(instanceInfo.pos.x, instanceInfo.pos.y, 0.0f);
            glRotatef(instanceInfo.rotate, 0.0f, 0.0f, 1.0f);
            glTranslatef(instanceInfo.localTranslate.x, instanceInfo.localTranslate.y, 0.0f);
        }
        else
        {
            glTranslatef(pos.x, pos.y, 0.0f);
            glRotatef(rotate, 0.0f, 0.0f, 1.0f);
        }
        glVertexPointer(3, GL_FLOAT, 0, debugColVerts);
        glColor4f(1.0f, 0.0f, 1.0f, 1.0f);
        glDrawArrays(GL_LINES, 0, 8);
        glPopMatrix();
    }
    
    if(([[DebugOptions getInstance] isDebugColOutlineOn]) && (debugColVerts))
    {
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glPushMatrix();
        if(instanceInfo)
        {
            glTranslatef(instanceInfo.pos.x, instanceInfo.pos.y, 0.0f);
            glRotatef(instanceInfo.rotate, 0.0f, 0.0f, 1.0f);
            glTranslatef(instanceInfo.localTranslate.x, instanceInfo.localTranslate.y, 0.0f);
        }
        else
        {
            glTranslatef(pos.x, pos.y, 0.0f);
            glRotatef(rotate, 0.0f, 0.0f, 1.0f);
        }
        glVertexPointer(3, GL_FLOAT, 0, debugColVerts);
        glColor4f(0.0f, 1.0f, 0.0f, 1.0f);
        glLineWidth(2.0f);
        glDrawArrays(GL_LINES, 0, 8);
        glPopMatrix();
    }
#endif
}

@end
