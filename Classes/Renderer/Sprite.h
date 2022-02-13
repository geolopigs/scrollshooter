//
//  Sprite.h
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import "DrawCommand.h"

#if defined(DEBUG)
#define SPRITE_DEBUGDRAW (1)
#endif

@interface SpriteInstance : NSObject
{
    CGPoint localTranslate;
    float rotate;   // radians
    CGPoint pos;
    CGPoint scale;
    CGPoint texcoordScale;
    CGPoint texcoordTranslate;
    GLuint texture;
    GLfloat alpha;
    GLfloat colorR;
    GLfloat colorG;
    GLfloat colorB;
}
@property (nonatomic,assign) CGPoint localTranslate;
@property (nonatomic,assign) float rotate;
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGPoint scale;
@property (nonatomic,assign) CGPoint texcoordScale;
@property (nonatomic,assign) GLuint  texture;
@property (nonatomic,assign) CGPoint texcoordTranslate;
@property (nonatomic,assign) GLfloat alpha;
@property (nonatomic,assign) GLfloat colorR;
@property (nonatomic,assign) GLfloat colorG;
@property (nonatomic,assign) GLfloat colorB;
@end

@interface Sprite : NSObject<DrawDelegate> 
{
    float rotate;   // radians
	CGPoint pos;
    CGPoint scale;
	CGSize	size;
    CGPoint texcoordScale;
    CGPoint texcoordTranslate;
	GLfloat* verts;
	GLfloat* texcoords;
	unsigned int vertCount;
	
    GLfloat alpha;
	GLuint tex;

#if defined(SPRITE_DEBUGDRAW)
    GLfloat* debugVerts;
    GLfloat* debugColVerts;
#endif
}
@property (nonatomic,assign) float rotate;
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) CGPoint scale;
@property (nonatomic,assign) CGSize size;
@property (nonatomic,assign) GLfloat alpha;
@property (nonatomic,assign) GLuint tex;
@property (nonatomic,assign) CGPoint texcoordScale;
@property (nonatomic,assign) CGPoint texcoordTranslate;

- (id) initWithSize:(CGSize)renderSize;
- (id) initWithSize:(CGSize)renderSize colSize:(CGSize)colSize;
- (id) initWithSize:(CGSize)renderSize colRect:(CGRect)colRect;

@end
