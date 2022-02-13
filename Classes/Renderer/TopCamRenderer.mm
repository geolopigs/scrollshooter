//
//  TopCamRenderer.mm
//  Curry
//
//  Created by Shu Chiun Cheah on 6/30/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "TopCamRenderer.h"

static const float CAM_TO_PLAYER_DISTANCE = 50.0f;
static const float CAM_ORIGINFUNCTION_SLOPE = -1.0f / 50.0f;

@interface TopCamRenderer (TopCamRendererPrivate)
- (float) camSlopeFromCamDistance:(float)camDistance;
@end

@implementation TopCamInstance
@synthesize origin;

- (id) initWithCamOrigin:(CGPoint)camOrigin
{
    self = [super init];
    if(self)
    {
        self.origin = camOrigin;
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
}


@end

@implementation TopCamRenderer

- (id) initWithFrame:(CGRect)frameRect forViewFrame:(CGRect)viewRect
{
    self = [super init];
    if(self)
    {
        // compute GL matrix from frameRect
        baseModelView = new float[16];

        // column 0 is the x-axis of the view-frame in terms of the camera frame
        baseModelView[0] = viewRect.size.width / frameRect.size.width;
        baseModelView[1] = 0.0f;
        baseModelView[2] = 0.0f;
        baseModelView[3] = 0.0f;
    
        // column 1 is the y-axis of the view-frame in terms of the camera frame
        baseModelView[0+4] = 0.0f;
        baseModelView[1+4] = viewRect.size.height / frameRect.size.height;
        baseModelView[2+4] = 0.0f;
        baseModelView[3+4] = 0.0f;

        // column 2 is (0, 0, 1)
        baseModelView[0+8] = 0.0f;
        baseModelView[1+8] = 0.0f;
        baseModelView[2+8] = 1.0f;
        baseModelView[3+8] = 0.0f;
        
        // column 3 is the displacement from view orign to camera frame origin
        baseModelView[0+12] = frameRect.origin.x - viewRect.origin.x;
        baseModelView[1+12] = frameRect.origin.y - viewRect.origin.y;
        baseModelView[2+12] = 0.0f;
        baseModelView[3+12] = 1.0f;
    }
    return self;
}

- (void) dealloc
{
    delete [] baseModelView;
    [super dealloc];
}

#pragma mark -
#pragma mark Private methods
- (float) camSlopeFromCamDistance:(float)camDistance
{
    float result = (camDistance * CAM_ORIGINFUNCTION_SLOPE) + (1.0f - (CAM_TO_PLAYER_DISTANCE * CAM_ORIGINFUNCTION_SLOPE));
    return result;
}

#pragma mark -
#pragma mark DrawDelegate
- (void) draw:(TopCamInstance*)instanceInfo
{
    // assume an Identity ModelView on the stack
    glMultMatrixf(baseModelView);
    if(instanceInfo)
    {
        // to translate points into view-space, use the opposite of the camera's position
        glTranslatef(-instanceInfo.origin.x, -instanceInfo.origin.y, 0.0f);
    }
}
@end
