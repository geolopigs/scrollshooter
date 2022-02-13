//
//  TopCamRenderer.h
//  Curry
//
//  Created by Shu Chiun Cheah on 6/30/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>
#import "DrawCommand.h"

@interface TopCamInstance : NSObject 
{
    CGPoint origin;
}
@property (nonatomic,assign) CGPoint origin;
- (id) initWithCamOrigin:(CGPoint)camOrigin;

@end

@interface TopCamRenderer : NSObject<DrawDelegate>
{
    GLfloat* baseModelView;
}
- (id) initWithFrame:(CGRect)frameRect forViewFrame:(CGRect)viewRect;
@end
