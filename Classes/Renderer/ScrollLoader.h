//
//  ScrollLoader.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/8/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

typedef enum
{
    LOADER_STATE_IDLE = 0,
    LOADER_STATE_LOADING,
    LOADER_STATE_DONE,
    
    LOADER_STATE_NUM
} LoaderStates;

@interface ScrollLoader : NSObject 
{
    NSMutableArray* nameQueue;
    NSMutableArray* orientationQueue;
    NSMutableArray* textures;
    LoaderStates    state;
    BOOL            willAbort;
}
@property (retain) NSMutableArray*  nameQueue;
@property (retain) NSMutableArray*  orientationQueue;
@property (nonatomic,retain) NSMutableArray*  textures;
@property (assign) LoaderStates     state;
@property (assign) BOOL             willAbort;

- (BOOL) queueTexFilename:(NSString*)filename orientation:(int)tileOrientation;
- (void) mainUpdate;
- (void) processBackgroundLoad; // called in background thread to load texture subimages
- (BOOL) hasNewImages;
- (void) consumedLoading;
- (void) abortLoading;
- (BOOL) isLoading;
@end
