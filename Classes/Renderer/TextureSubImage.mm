//
//  TextureSubImage.mm
//  Used for replacing regions within a Texture with glTexSubImage2D
//
//  Created by Shu Chiun Cheah on 7/7/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "TextureSubImage.h"
#import "Texture.h"
#import "LevelTileData.h"
#import "AppRendererConfig.h"

@interface TextureSubImage (TextureSubImagePrivate)
- (void) createGlTexBuffer;
- (void) destroyGlTexBuffer;
@end

@implementation TextureSubImage
@synthesize texImage;

- (id) initFromFilename:(NSString *)filename orientation:(int)tileOrientation
{
    self = [super init];
    if(self)
    {
        orientation = tileOrientation;
        self.texImage = [Texture loadTifImageFromFileName:filename];
        [self createGlTexBuffer];
    }
    return self;
}

- (void) dealloc
{
    [self destroyGlTexBuffer];
    [texImage release];
    [super dealloc];
}

- (size_t) imageWidth
{
    return CGImageGetWidth(texImage.CGImage);
}

- (size_t) imageHeight
{
    return CGImageGetHeight(texImage.CGImage);
}

- (void) applySubImageAtOffset:(CGPoint)offset
{
    glTexSubImage2D(GL_TEXTURE_2D, 0, offset.x, offset.y, texWidth, texHeight, GL_RGBA, GL_UNSIGNED_BYTE, texData);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

#pragma mark -
#pragma mark Private methods


- (void) createGlTexBuffer
{
 	size_t imageW = CGImageGetWidth(texImage.CGImage);
	size_t imageH = CGImageGetHeight(texImage.CGImage);
	
	// texture dimensions must be power of two; so, round up
	texWidth = [Texture toNextPowerOfTwo:imageW];
	texHeight = [Texture toNextPowerOfTwo:imageH];
	
	// use the shared texture loading buffer; so, must fit in its size
    assert((texWidth * texHeight * 4) <= (2048 * 1024));
    texData = [[AppRendererConfig getInstance] getScrollSubimageBuffer];
	const char defaultValue[] = {0,0,0,0};
	memset_pattern4(texData, defaultValue, texWidth * texHeight * 4);
	CGContextRef texContext = CGBitmapContextCreate(texData, texWidth, texHeight, 8, texWidth * 4, 
													CGImageGetColorSpace(texImage.CGImage), 
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
            CGContextTranslateCTM(texContext, imageW, texHeight);
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
            CGContextTranslateCTM(texContext, 0.0, texHeight);
            CGContextScaleCTM(texContext, 1.0, -1.0);
            break;
    }

    CGContextDrawImage(texContext, CGRectMake(0.0, 0.0, imageW, imageH), texImage.CGImage);	
	CGContextRelease(texContext);	    
}

- (void) destroyGlTexBuffer
{
//    free(texData);
}
@end
