//
//  Texture.h
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface Texture : NSObject 
{
	GLuint		texName;
	UIImage*	texImage;
	
	// dimensions of source image
	size_t		imageWidth;	
	size_t		imageHeight;
	
	// dimensions of gl texture (rounded up to power-of-2)
	size_t		texWidth;
	size_t		texHeight;
	
    int         orientation;            // orientation enum as defined in LevelTileData
    GLubyte*    texBuffer;
    
    BOOL        _isRGB565;               // only used by 256x256 and larger scrollLayer textures
}
@property (nonatomic,readonly) GLuint texName;
@property (nonatomic,readonly) UIImage* texImage;
@property (nonatomic,readonly) size_t imageWidth;
@property (nonatomic,readonly) size_t imageHeight;
@property (nonatomic,readonly) size_t texWidth;
@property (nonatomic,readonly) size_t texHeight;
@property (nonatomic,readonly) BOOL isRGB565;

+ (int) toNextPowerOfTwo:(int)number;
+ (UIImage*) loadTifImageFromFileName:(NSString*)fileName;

- (id) initFromFileName:(NSString*)filename orientation:(int)tileOrientation;
- (id) initFromFileName:(NSString*)fileName;
- (id) initFromFileName:(NSString*)fileName IsYFlipped:(BOOL)isYFlipped;

- (id) initFromFileName:(NSString *)fileName orientation:(int)tileOrientation toBuffer:(GLubyte*)buffer withIntermediate:(GLubyte*)intermediateBuffer;
- (void) submitBufferToGL;

- (id) initFromString:(NSString*)text withFontNamed:(NSString*)fontName atRes:(unsigned int)numTexelLines;

// returns the texcoords that match the bounds of the image
- (float) getImageWidthTexcoord;
- (float) getImageHeightTexcoord;

@end
