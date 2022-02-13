//
//  RendererGLView.mm
//

#import "RendererGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

@interface RendererGLView (RendererGLViewPrivate)

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end

static RendererGLView* singletonInstance = nil;

@implementation RendererGLView

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

#pragma mark -
#pragma mark singleton routines
+ (RendererGLView*)getInstance
{
    @synchronized(self)
    {
        if (singletonInstance == nil)
		{
            CGRect refFrame = [UIScreen mainScreen].applicationFrame;
            refFrame.size.height = MIN(CGRectGetHeight(refFrame), 1.5 * CGRectGetWidth(refFrame));
			singletonInstance = [[RendererGLView alloc] initWithFrame:refFrame];
		}
    }
    return singletonInstance;
}

+ (void) destroyInstance
{
	[singletonInstance dealloc];
	singletonInstance = nil;
}


#pragma mark -
#pragma mark View routines
- (id) initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		// Get our backing layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
		
		// Configure it so that it is opaque, does not retain the contents of the backbuffer when displayed, and uses RGBA8888 color.
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
										kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
										nil];
        
        // scale the EAGLLayer according to the scale of the mainscreen;
        // retina display has a different scale than non-retina display while the frame size is the same
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];		
		if(!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) 
		{
			[self release];
			return nil;
		}		
	}
	return self;
}

- (void)dealloc 
{
	[self destroyFramebuffer];
    [super dealloc];
}


- (BOOL)createFramebuffer
{
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		//NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}


- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (GLint) getWidth
{
	return backingWidth;
}

- (GLint) getHeight
{
	return backingHeight;
}

- (EAGLContext*) getContext
{
	return context;
}

- (void) setAsCurrentContext
{
	[EAGLContext setCurrentContext:context];
}

- (void) beginFrame
{
	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	glViewport(0, 0, backingWidth, backingHeight);
}

- (void) endFrame
{
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];		
}

@end
