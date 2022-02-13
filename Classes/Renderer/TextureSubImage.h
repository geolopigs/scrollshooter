//
//  TextureSubImage.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/7/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>


@interface TextureSubImage : NSObject
{
    int         orientation;
	UIImage*	texImage;
    GLubyte*    texData;
    size_t      texWidth;
    size_t      texHeight;
}
@property (nonatomic,retain) UIImage* texImage;
@property (nonatomic,readonly) size_t imageWidth;
@property (nonatomic,readonly) size_t imageHeight;

- (id) initFromFilename:(NSString*)filename orientation:(int)tileOrientation;
- (void) applySubImageAtOffset:(CGPoint)offset;
@end
