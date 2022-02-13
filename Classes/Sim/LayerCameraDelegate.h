//
//  LayerCameraDelegate.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/22/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TopCam;
@protocol LayerCameraDelegate <NSObject>
- (void) addDrawCommandForCamera:(TopCam*)camera;
@end
