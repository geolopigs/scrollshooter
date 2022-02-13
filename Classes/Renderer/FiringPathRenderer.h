//
//  FiringPathRenderer.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/12/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import "DrawCommand.h"

@interface FiringPathInstance : NSObject
{
    NSArray* shots;
    BOOL isAnimated;
}
@property (nonatomic,retain) NSArray* shots;
@property (nonatomic,assign) BOOL isAnimated;
@property (nonatomic,assign) BOOL isTrail;
- (id) initWithShots:(NSArray*)shotSet isAnimated:(BOOL)shotHasAnimation isTrail:(BOOL)shotIsTrail;

@end


@interface FiringPathRenderer : NSObject<DrawDelegate>
{
	GLfloat* verts;
	GLfloat* texcoords;
    GLuint tex;
#if defined(DEBUG)
    GLfloat* debugVerts;
    GLfloat* debugColVerts;
#endif
}
@property (nonatomic,assign) GLuint tex;
- (id) initWithSize:(CGSize)renderSize colSize:(CGSize)colSize;
@end
