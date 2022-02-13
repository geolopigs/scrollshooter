//
//  GameGLView.mm
//

#import "GameGLView.h"
#import "RendererGLView.h"

#pragma mark -
#pragma mark GameGLViewConfig

@implementation GameGLViewConfig
@synthesize viewportSize;

- (id) init
{
	if((self = [super init]))
	{
		[self setViewportSize:CGSizeMake(2.0f, 3.0f)];
		[self setClearColorRed:0.0f green:0.0f blue:0.0f];
	}
	return self;
}

- (void) setClearColorRed:(GLfloat)red green:(GLfloat)green blue:(GLfloat)blue
{
    clearColorR = red;
    clearColorG = green;
    clearColorB = blue;
}

- (GLfloat) getClearColorR
{
	return clearColorR;
}

- (GLfloat) getClearColorG
{
	return clearColorG;
}

- (GLfloat) getClearColorB
{
	return clearColorB;
}

@end

#pragma mark -
#pragma mark GameGLView
@implementation GameGLView
@synthesize rendererView;

- (id) initWithConfig:(GameGLViewConfig*)config
{
	if ((self = [super init]))
	{
		self.rendererView = [RendererGLView getInstance];
		
		viewHalfWidth = config.viewportSize.width * 0.5f;
		viewHalfHeight = config.viewportSize.height * 0.5f;
		clearColor[0] = [config getClearColorR];
		clearColor[1] = [config getClearColorG];
		clearColor[2] = [config getClearColorB];
	}
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void)beginFrame
{
	[rendererView beginFrame];
	
	// Make sure that you are drawing to the current context
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Sets up matrices and transforms for OpenGL ES
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(-viewHalfWidth, viewHalfWidth,
			 -viewHalfHeight, viewHalfHeight,
			 -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
    
	// Clears the view with black
	glClearColor(clearColor[0], clearColor[1], clearColor[2], 1.0f);
	glDisable(GL_LIGHTING);
	
    // all our textures have premultiplied alpha; so, no need to multiply the src alpha
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);    
}



- (void) endFrame
{
	[rendererView endFrame];
}


@end
