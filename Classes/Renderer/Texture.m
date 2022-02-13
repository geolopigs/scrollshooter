//
//  Texture.m
//

#import "Texture.h"
#import "LevelTileData.h"
#import "AppRendererConfig.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

@interface Texture(TexturePrivate)
- (void) initInternalFromFileName:(NSString *)fileName orientation:(int)givenOrientation;
- (void) createGLTexFromImage:(UIImage*)image;
- (void) loadTexImage:(UIImage*)image toBuffer:(GLubyte*)buffer withIntermediate:(GLubyte*)intermediateBuffer;
@end

@implementation Texture
@synthesize texName;
@synthesize texImage;
@synthesize imageWidth;
@synthesize imageHeight;
@synthesize texWidth;
@synthesize texHeight;
@synthesize isRGB565;


- (void) initInternalFromFileName:(NSString *)fileName orientation:(int)givenOrientation
{
    orientation = givenOrientation;
    _isRGB565 = NO;

    // uncompressed
    texName = 0;
    texImage = [Texture loadTifImageFromFileName:fileName];
    [self createGLTexFromImage:texImage];
    
    imageWidth = CGImageGetWidth(texImage.CGImage);
    imageHeight = CGImageGetHeight(texImage.CGImage);
    texWidth = [Texture toNextPowerOfTwo:imageWidth];
    texHeight = [Texture toNextPowerOfTwo:imageHeight];
    texBuffer = NULL;
}

- (id) initFromFileName:(NSString *)filename orientation:(int)tileOrientation
{
    self = [super init];
    if(self)
    {
        [self initInternalFromFileName:filename orientation:tileOrientation];
    }
    return self;
}

- (id) initFromFileName:(NSString *)fileName
{
	if((self = [super init]))
	{
		[self initInternalFromFileName:fileName orientation:LEVELTILE_ORIENTATION_IDENTITY];
	}
	return self;
}

- (id) initFromFileName:(NSString *)fileName IsYFlipped:(BOOL)isYFlipped
{
	if((self = [super init]))
	{
        if(isYFlipped)
        {
            [self initInternalFromFileName:fileName orientation:LEVELTILE_ORIENTATION_IDENTITY];
        }
        else
        {
            [self initInternalFromFileName:fileName orientation:LEVELTILE_ORIENTATION_FLIPY];
        }
	}
	return self;
}

		
- (id) initFromFileName:(NSString *)fileName orientation:(int)tileOrientation toBuffer:(GLubyte*)buffer withIntermediate:(GLubyte *)intermediateBuffer
{
    self = [super init];
    if(self)
    {
        _isRGB565 = NO;
        orientation = tileOrientation;
        texImage = [Texture loadTifImageFromFileName:fileName];
        [self loadTexImage:texImage toBuffer:buffer withIntermediate:intermediateBuffer];

        imageWidth = CGImageGetWidth(texImage.CGImage);
        imageHeight = CGImageGetHeight(texImage.CGImage);
        texWidth = [Texture toNextPowerOfTwo:imageWidth];
        texHeight = [Texture toNextPowerOfTwo:imageHeight];
    }
    return self;
}

- (id) initFromString:(NSString*)text withFontNamed:(NSString*)fontName atRes:(unsigned int)numTexelLines
{
    self = [super init];
    if(self)
    {
        float screenScale = [[UIScreen mainScreen] scale];
        float scaledHeight = numTexelLines * screenScale;
        
        UIFont *				font;
        font = [UIFont fontWithName:fontName size:scaledHeight];
        
        size_t height = [Texture toNextPowerOfTwo:scaledHeight];
        size_t width = [Texture toNextPowerOfTwo:([text length] * height)];
        
        
        
        // use the shared texture loading buffer; so, must fit in its size
        BOOL useSharedBuffer = YES;
        GLubyte* texData = [[AppRendererConfig getInstance] getScrollSubimageBuffer];
        if((width * height * 4) > (512 * 512 * 4))
        {
            // if required texture buffer doesn't fit in shared buffer,
            // allocate it (this would happen on higher res devices like the iPad 3)
            texData = (GLubyte*) malloc((width * height * 4) * sizeof(GLubyte));
            useSharedBuffer = NO;
        }

        const char defaultValue[] = {0,0,0,0};
        memset_pattern4(texData, defaultValue, width * height * 4);
        
        CGColorSpaceRef			colorSpace;
        colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef texContext = CGBitmapContextCreate(texData, width, height, 8, width * 4, 
                                                        colorSpace, 
                                                        kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
        
        
        
        // CG coord should be upside down, but somehow this ends up creating an upside-down GL texture
        // TODO: not sure why; may need to figure out the reason in case there is a bug in the Effect code
        //CGContextTranslateCTM(texContext, 0.0, height);
        //CGContextScaleCTM(texContext, 1.0, -1.0); 
        UIGraphicsPushContext(texContext);

        //CGContextSetTextDrawingMode(texContext, kCGTextFillStroke);
        //CGContextSetRGBStrokeColor(texContext, 0.0f, 0.0f, 0.0f, 1.0f);
        CGContextSetRGBFillColor(texContext, 1.0, 1.0, 1.0f, 1.0f);
        CGContextSetShadowWithColor(texContext, CGSizeMake(1.0f,1.0f), 4.0f, [[UIColor blackColor] CGColor]);
        NSMutableParagraphStyle* para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.lineBreakMode = NSLineBreakByWordWrapping;
        para.alignment = NSTextAlignmentCenter;
        NSDictionary* attrs = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: para, NSForegroundColorAttributeName: [UIColor orangeColor]};
        [text drawInRect:CGRectMake(0, 0, width, height) withAttributes:attrs];
        
        UIGraphicsPopContext();
        CGContextRelease(texContext);	

        // create gl texture
        glEnable(GL_TEXTURE_2D);	
        glGenTextures(1, &texName);
        glBindTexture(GL_TEXTURE_2D, texName);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texData);
        
        // imageWidth and Height are unscaled dimensions (before retina scale)
        imageHeight = [Texture toNextPowerOfTwo:numTexelLines];
        imageWidth = [Texture toNextPowerOfTwo:([text length] * imageHeight)];
        
        // these are the actual texture width and height in points
        texWidth = width;
        texHeight = height;
        
        if(!useSharedBuffer)
        {
            // if we had not used the shared buffer, free it
            free(texData);
        }
    }
    return self;
}

- (void) dealloc
{
    if(!texBuffer)
    {
        // if texBuffer not NULL, then texture has been submitted to GL
        glDeleteTextures(1, &texName);
    }
	[texImage release];
	[super dealloc];
}

#pragma mark -
#pragma mark Utility methods

+ (UIImage*) loadTifImageFromFileName:(NSString*)fileName
{
	UIImage* texImage = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"png"]] retain];

	// if png not found, fall back to tif
	if(!texImage)
	{
		texImage = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fileName ofType:@"tif"]] retain];
	}
    if(!texImage)
    {
        texImage = [[UIImage imageNamed:fileName] retain];
    }
	assert(texImage);
	return texImage;
}

- (void) createGLTexFromImage:(UIImage*)image
{	
	size_t imageW = CGImageGetWidth(image.CGImage);
	size_t imageH = CGImageGetHeight(image.CGImage);
	
	// texture dimensions must be power of two; so, round up
	size_t width = [Texture toNextPowerOfTwo:imageW];
	size_t height = [Texture toNextPowerOfTwo:imageH];
	
	glEnable(GL_TEXTURE_2D);	
	
	glGenTextures(1, &texName);

	// use the shared texture loading buffer; so, must fit in its size
    assert((width * height * 4) <= (512 * 512 * 4));
    GLubyte* texData = [[AppRendererConfig getInstance] getScrollSubimageBuffer];
	const char defaultValue[] = {0,0,0,0};
	memset_pattern4(texData, defaultValue, width * height * 4);
	CGContextRef texContext = CGBitmapContextCreate(texData, width, height, 8, width * 4, 
													CGImageGetColorSpace(image.CGImage), 
													kCGImageAlphaPremultipliedLast);
	
    // all orientations have an additional flip-y because openGL origin is at bottom-left while CG origin is top-left;
    // so, IDENTITY needs flip-y
    // FLIPX needs flip-y flip-x
    // FLIPY needs no transform
    // FLIPXY needs flip-x
    // Also note that for flip-y, texHeight is used to translate because the GL uv origin is on the other side of the power-of-two height
    switch(orientation)
    {
        case LEVELTILE_ORIENTATION_FLIPX:
            CGContextTranslateCTM(texContext, imageW, height);
            CGContextScaleCTM(texContext, -1.0f, -1.0f);    
            break;
            
        case LEVELTILE_ORIENTATION_FLIPXY:
            CGContextTranslateCTM(texContext, imageW, 0.0f);
            CGContextScaleCTM(texContext, -1.0f, 1.0f);
            break;
            
        case LEVELTILE_ORIENTATION_FLIPY:
            CGContextScaleCTM(texContext, 1.0f, 1.0f);
            break;
            
        case LEVELTILE_ORIENTATION_IDENTITY:
        default:
            CGContextTranslateCTM(texContext, 0.0, height);
            CGContextScaleCTM(texContext, 1.0, -1.0);
            break;
    }
    
	CGContextDrawImage(texContext, CGRectMake(0.0, 0.0, imageW, imageH), image.CGImage);	
	CGContextRelease(texContext);	
	glBindTexture(GL_TEXTURE_2D, texName);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texData);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

- (void) loadTexImage:(UIImage *)image toBuffer:(GLubyte *)buffer withIntermediate:(GLubyte*)intermediateBuffer
{	
    // store off pointer to buffer
    GLubyte* inBuffer = intermediateBuffer;

	size_t imageW = CGImageGetWidth(image.CGImage);
	size_t imageH = CGImageGetHeight(image.CGImage);
	
	// texture dimensions must be power of two; so, round up
	size_t width = [Texture toNextPowerOfTwo:imageW];
	size_t height = [Texture toNextPowerOfTwo:imageH];
	
	// use the shared texture loading buffer; so, must fit in its size
    assert((width * height * 4) <= (512 * 512 * 4));
	const char defaultValue[] = {0,0,0,0};
	memset_pattern4(inBuffer, defaultValue, width * height * 4);
	CGContextRef texContext = CGBitmapContextCreate(inBuffer, width, height, 8, width * 4, 
													CGImageGetColorSpace(image.CGImage), 
													kCGImageAlphaPremultipliedLast);
	
    // all orientations have an additional flip-y because openGL origin is at bottom-left while CG origin is top-left;
    // so, IDENTITY needs flip-y
    // FLIPX needs flip-y flip-x
    // FLIPY needs no transform
    // FLIPXY needs flip-x
    // Also note that for flip-y, texHeight is used to translate because the GL uv origin is on the other side of the power-of-two height
    switch(orientation)
    {
        case LEVELTILE_ORIENTATION_FLIPX:
            CGContextTranslateCTM(texContext, imageW, height);
            CGContextScaleCTM(texContext, -1.0f, -1.0f);    
            break;
            
        case LEVELTILE_ORIENTATION_FLIPXY:
            CGContextTranslateCTM(texContext, imageW, 0.0f);
            CGContextScaleCTM(texContext, -1.0f, 1.0f);
            break;
            
        case LEVELTILE_ORIENTATION_FLIPY:
            CGContextScaleCTM(texContext, 1.0f, 1.0f);
            break;
            
        case LEVELTILE_ORIENTATION_IDENTITY:
        default:
            CGContextTranslateCTM(texContext, 0.0, height);
            CGContextScaleCTM(texContext, 1.0, -1.0);
            break;
    }
    
	CGContextDrawImage(texContext, CGRectMake(0.0, 0.0, imageW, imageH), image.CGImage);	
	CGContextRelease(texContext);	
    
    // convert tiles larger than 256x256 to RGB565
    if(((width >= 256) && (height > 256)) ||
       ((width > 256) && (height >= 256)))
    {
        texBuffer = buffer;
        unsigned int* inPixel32 = (unsigned int*)inBuffer;
        unsigned short* outPixel16 = (unsigned short*)texBuffer;
        for(unsigned int i = 0; i < width * height; ++i, ++inPixel32)
        {
            *outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | ((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) | ((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);
        }
        _isRGB565 = YES;
    }
    else
    {
        texBuffer = intermediateBuffer;
        _isRGB565 = NO;
    }
}

- (void) submitBufferToGL
{
    assert(texBuffer);
    glEnable(GL_TEXTURE_2D);		
	glGenTextures(1, &texName);
	glBindTexture(GL_TEXTURE_2D, texName);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    if(_isRGB565)
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, texWidth, texHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, texBuffer);
    }
    else
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, texBuffer);
    }
    texBuffer = NULL;
}

+ (int) toNextPowerOfTwo:(int) number
{
	int result = number;
	if(number & (number - 1))
	{
		int i = 1;
		while(i < number)
		{
			i <<= 1;
		}
		result = i;
	}
	return result;
}

- (float) getImageWidthTexcoord
{
	float result = ((float) imageWidth) / ((float) texWidth);
	return result;
}

- (float) getImageHeightTexcoord
{
	float result = ((float) imageHeight) / ((float) texHeight);
	return result;
}

@end
