//
//  AppRendererConfig.h
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

@class RenderBucketsConfig;

@interface AppRendererConfig : NSObject 
{
	RenderBucketsConfig* bucketsConfig;
	CGSize gameViewportSize;
    GLubyte*    scrollSubimageBuffer;
    GLubyte*    imageBuffer2;
}
@property (nonatomic,readonly) RenderBucketsConfig* bucketsConfig;
@property (nonatomic,readonly) CGSize gameViewportSize;

- (CGRect) getViewportFrame;
- (GLubyte*) getScrollSubimageBuffer;
- (GLubyte*) getImageBuffer2;

+ (AppRendererConfig*) getInstance;
+ (void) destroyInstance;

@end
