//
//  ScrollLoader.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 7/8/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "ScrollLoader.h"
#import "Texture.h"
#import "AppRendererConfig.h"

@interface ScrollLoader (ScrollLoaderPrivate)
- (void) startLoading;
- (void) finishedLoading;
- (void) consumeLoading;
@end

@implementation ScrollLoader
@synthesize nameQueue;
@synthesize orientationQueue;
@synthesize textures;
@synthesize state;
@synthesize willAbort;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.nameQueue = [NSMutableArray arrayWithCapacity:4];
        self.orientationQueue = [NSMutableArray arrayWithCapacity:4];
        self.textures = [NSMutableArray arrayWithCapacity:4];
        self.state = LOADER_STATE_IDLE;
        self.willAbort = NO;
    }
    return self;        
}

- (void) dealloc
{
    self.textures = nil;
    self.orientationQueue = nil;
    self.nameQueue = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Accessor methods
// returns true if filename successfully added to queue; false otherwise, filename needs to be re-queued
- (BOOL) queueTexFilename:(NSString *)filename orientation:(int)tileOrientation
{
    BOOL result = NO;
    
    if((LOADER_STATE_IDLE == state) && ([nameQueue count] < 1))
    {
        [nameQueue addObject:filename];
        [orientationQueue addObject:[NSNumber numberWithInt:tileOrientation]];
        result = YES;
    }
    
    return result;
}

- (BOOL) hasNewImages
{
    BOOL result = (([textures count] > 0) && (LOADER_STATE_DONE == state));
    return result;
}

- (void) consumedLoading
{
    state = LOADER_STATE_IDLE;
    [textures removeAllObjects];
}

- (void) abortLoading
{
    if(LOADER_STATE_LOADING == state)
    {
        self.willAbort = YES;
    }
    else if((LOADER_STATE_IDLE == state) && ([nameQueue count] > 0))
    {
        // clear out queue if load has not started
        [nameQueue removeAllObjects];
    }
}

// main thread update function (called from Game loop)
- (void) mainUpdate
{
    switch(state)
    {
        case LOADER_STATE_LOADING:
            // do nothing, wait for background thread to produce something
            break;
            
        case LOADER_STATE_DONE:
            // done loading, do nothing here, wait for owner of this object to consume it and inform us
            break;
            
        case LOADER_STATE_IDLE:
        default:
            // trigger a background load if queue not empty
            if([nameQueue count] > 0)
            {
                // start loading
                [self startLoading];
            }
            break;
    }
    if(LOADER_STATE_DONE == state)
    {
        // done loading, add them for subImage application
    }
}

- (BOOL) isLoading
{
    BOOL result = NO;
    if(state == LOADER_STATE_LOADING)
    {
        result = YES;
    }
    return result;
}

#pragma mark -
#pragma mark Background Thread
// loading thread process function
- (void) processBackgroundLoad
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    unsigned int index = 0;
    assert(1 >= [nameQueue count]);
    while(index < [nameQueue count])
    {
        NSString* curName = [nameQueue objectAtIndex:index];
        int orientation = [[orientationQueue objectAtIndex:index] intValue];
        
        GLubyte* intermedateBuffer = [[AppRendererConfig getInstance] getScrollSubimageBuffer];
        GLubyte* buffer = [[AppRendererConfig getInstance] getImageBuffer2];
        Texture* loadedImage = [[Texture alloc] initFromFileName:curName orientation:orientation toBuffer:buffer withIntermediate:intermedateBuffer];
        [textures addObject:loadedImage];
        [loadedImage release];
        ++index;
    }
    [self performSelectorOnMainThread:@selector(finishedLoading) withObject:nil waitUntilDone:NO];
    [pool release];
}

#pragma mark -
#pragma mark Private methods
- (void) startLoading
{
    state = LOADER_STATE_LOADING;
    [self performSelectorInBackground:@selector(processBackgroundLoad) withObject:nil];
}

- (void) finishedLoading
{
    state = LOADER_STATE_DONE;
    [nameQueue removeAllObjects];
    [orientationQueue removeAllObjects];
    
    if(willAbort)
    {
        self.willAbort = NO;
        [self consumedLoading];
    }
}


@end
