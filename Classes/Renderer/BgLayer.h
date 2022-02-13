//
//  BgLayer.h
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import "DrawCommand.h"

@class Texture;

@interface BgLayerInstance : NSObject
{
    CGPoint pos;
}
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) GLuint texture;
@end

@interface BgLayer : NSObject<DrawDelegate> 
{
	CGPoint pos;
	CGSize	size;
	GLfloat* verts;
	GLfloat* texcoords;
	unsigned int vertCount;
	
	GLuint tex;
}
@property (nonatomic,assign) CGPoint pos;
@property (nonatomic,assign) GLuint tex;

- (id) initWithFrame:(CGRect)frameRect texture:(Texture*)bgTex;

@end
