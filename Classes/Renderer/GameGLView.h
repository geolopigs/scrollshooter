//
//  GameGLView.h
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


// forward declarations
@class RendererGLView;

// GameGLViewConfig interface
@interface GameGLViewConfig : NSObject
{
	CGSize viewportSize;
	GLfloat clearColorR;
	GLfloat clearColorG;
	GLfloat clearColorB;
}
@property (nonatomic,assign) CGSize viewportSize;
- (void) setClearColorRed:(GLfloat)red green:(GLfloat)green blue:(GLfloat)blue;
- (GLfloat) getClearColorR;
- (GLfloat) getClearColorG;
- (GLfloat) getClearColorB;
@end

// GameGLView interface
@interface GameGLView : NSObject 
{
	RendererGLView* rendererView;

	// config
	GLfloat viewHalfWidth;
	GLfloat viewHalfHeight;
	GLfloat clearColor[3];
}
@property (nonatomic,assign) RendererGLView* rendererView;

- (id) initWithConfig:(GameGLViewConfig*)config;
- (void) beginFrame;
- (void) endFrame;
@end
