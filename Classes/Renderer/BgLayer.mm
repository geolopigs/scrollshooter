//
//  BgLayer.mm
//

#import "BgLayer.h"
#import "DrawCommand.h"
#import "Texture.h"

@implementation BgLayerInstance
@synthesize pos;
@synthesize texture;
@end

@implementation BgLayer
@synthesize pos;
@synthesize tex;

- (id) initWithFrame:(CGRect)frameRect texture:(Texture*)bgTex
{
	if((self = [super init]))
	{
		verts = static_cast<GLfloat*>(malloc(3 * 4 * sizeof(GLfloat)));
		texcoords = static_cast<GLfloat*>(malloc(2 * 4 * sizeof(GLfloat)));
		
		unsigned int index = 0;
		unsigned int texIndex = 0;
		float x = frameRect.origin.x;
        float y = frameRect.origin.y;
        float w = frameRect.size.width;
        float h = frameRect.size.height;
        float uMax = [bgTex getImageWidthTexcoord];
        float vMax = [bgTex getImageHeightTexcoord];
        
		// bot-left
		verts[index]	= x;
		verts[index+1]	= y;
		verts[index+2]	= 1.0f;
		texcoords[texIndex] = 0.0f;
		texcoords[texIndex+1] = 0.0f;
		index += 3;
		texIndex += 2;
		
		// bot-right
		verts[index]	= x + w;
		verts[index+1]	= y;
		verts[index+2]	= 1.0f;
		texcoords[texIndex] = uMax;
		texcoords[texIndex+1] = 0.0f;
		index += 3;
		texIndex += 2;
		
		// top-left
		verts[index]	= x;
		verts[index+1]	= y + h;
		verts[index+2]	= 1.0f;
		texcoords[texIndex] = 0.0f;
		texcoords[texIndex+1] = vMax;
		index += 3;
		texIndex += 2;
		
		// top-right
		verts[index]	= x + w;
		verts[index+1]	= y + h;
		verts[index+2]	= 1.0f;
		texcoords[texIndex] = uMax;
		texcoords[texIndex+1] = vMax;
		index += 3;
		texIndex += 2;
		
		// init texnum
		tex = bgTex.texName;
	}
	return self;
}

- (void) dealloc
{
	free(verts);
	free(texcoords);
	[super dealloc];
}

#pragma mark -
#pragma mark DrawDelegate
- (void) draw:(BgLayerInstance*)instanceInfo
{
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, tex);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glPushMatrix();
	glTranslatef(instanceInfo.pos.x, instanceInfo.pos.y, 0.0f);
	glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
	glVertexPointer(3, GL_FLOAT, 0, verts);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);		
	glPopMatrix();		
}

@end
