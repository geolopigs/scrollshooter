//
//  TopCam.mm
//  Curry
//
//  Created by Shu Chiun Cheah on 6/30/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "TopCam.h"
#import "TopCamRenderer.h"
#import "RenderBucketsManager.h"
#import "CamPath.h"
#import "GameManager.h"
#import "LevelManager.h"
#import "Level.h"
#import "ScrollLayer.h"
#import "SoundManager.h"
#import "Player.h"
#import "LevelConfig.h"
#import "Trigger.h"

static NSString* const FRAME_X = @"frameX";
static NSString* const FRAME_Y = @"frameY";
static NSString* const FRAME_WIDTH = @"frameWidth";
static NSString* const FRAME_HEIGHT = @"frameHeight";
static NSString* const GAMELAYER_DISTANCE = @"gameplayLayerDistance";
static NSString* const MAXLAYER_DISTANCE = @"maxLayerDistance";

static const float BOUNDS_LEFT = 0.0f;
static const float BOUNDS_RIGHT = 125.0f;

@interface TopCam (PrivateMethods)
- (void) stopLoopForScrollPathNamed:(NSString*)name;
- (void) breakMainPathLoop;
@end

@implementation TopCam
@synthesize appFrame;
@synthesize frame;
@synthesize pos;
@synthesize dynamicPos;
@synthesize camPath;
@synthesize triggerPath;
@synthesize scrollPaths;
@synthesize triggersArray;
@synthesize scrollPathRegistry;
@synthesize lastTrigger;
@synthesize paused;
@synthesize renderer;
@synthesize distanceMaxLayer;

- (id) initFromLevelConfig:(LevelConfig*)config forRendererViewFrame:(CGRect)viewFrame
{
    self = [super init];
    if(self)
    {
        NSDictionary* gameCameraConfig = config.gameCameraConfig;
        self.appFrame = [[UIScreen mainScreen] applicationFrame];
        float frameH = [[gameCameraConfig objectForKey:FRAME_HEIGHT] floatValue];
        float frameW = frameH * viewFrame.size.width / viewFrame.size.height;
        self.frame = CGRectMake([[gameCameraConfig objectForKey:FRAME_X] floatValue],
                                [[gameCameraConfig objectForKey:FRAME_Y] floatValue],
                                frameW, frameH);
        self.pos = CGPointMake(0.0f, 0.0f);
        self.dynamicPos = CGPointMake(0.0f, 0.0f);
        float playAreaWidth = BOUNDS_RIGHT - BOUNDS_LEFT;
        float newX = (0.5f * (playAreaWidth - frame.size.width)) - BOUNDS_LEFT;
        dynamicPos.x = newX;

        distanceToGameplayLayer = [[gameCameraConfig objectForKey:GAMELAYER_DISTANCE] floatValue];
        distanceMaxLayer = [[gameCameraConfig objectForKey:MAXLAYER_DISTANCE] floatValue];
        distanceFuncSlope = -1.0f / (distanceMaxLayer - distanceToGameplayLayer);
        
        renderBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Background"];
        dynamicsBucketIndex = [[RenderBucketsManager getInstance] getIndexFromName:@"Dynamics"];
        TopCamRenderer* newRenderer = [[TopCamRenderer alloc] initWithFrame:frame forViewFrame:viewFrame];
        self.renderer = newRenderer;
        [newRenderer release];
        self.camPath = nil;
        self.triggerPath = nil;
        self.scrollPaths = [NSMutableArray array];
        self.triggersArray = nil;
        self.scrollPathRegistry = [NSMutableDictionary dictionary];
        self.lastTrigger = -1;
        self.paused = YES;          // start paused, the game has to explicitly start the main scroll   
        shouldUnpauseAndBreak = NO;
        pauseType = PAUSETYPE_REGULAR;
    }
    return self;
}


- (void) dealloc
{
    self.scrollPathRegistry = nil;
    self.triggersArray = nil;
    self.scrollPaths = nil;
    self.triggerPath = nil;
    self.camPath = nil;
    [renderer release];
    [super dealloc];
}

- (void) restartLevel
{
    // reset all cam paths
    self.pos = CGPointMake(0.0f, 0.0f);
    [self.camPath resetFollow];
    [self.triggerPath resetFollow];
    for(CamPath* cur in scrollPaths)
    {
        [cur resetFollow];
    }

    self.lastTrigger = -1;
    self.paused = NO;
    pauseType = PAUSETYPE_NONE;
}

- (void) restartTriggers
{
    [self.triggerPath resetFollow];
    self.lastTrigger = -1;
}

- (void)addDrawToBucketIndex:(unsigned int)bucketIndex
{
    // add basic camera-to-view transform to the other layers that operate within camera space
    TopCamInstance* dynData = [[TopCamInstance alloc] initWithCamOrigin:dynamicPos];
	DrawCommand* basicCmd = [[DrawCommand alloc] initWithDrawDelegate:renderer DrawData:dynData];
	[[RenderBucketsManager getInstance] addCommand:basicCmd toBucket:bucketIndex];
    [basicCmd release];
    [dynData release];
}

- (void) addScrollPath:(CamPath*)newPath withName:(NSString *)layerName
{
    [scrollPaths addObject:newPath];
    [scrollPathRegistry setObject:newPath forKey:layerName];
}

- (void) stopLoopForScrollPathNamed:(NSString*)name
{
    CamPath* curPath = [scrollPathRegistry objectForKey:name];
    if(curPath)
    {
        [curPath stopLoop];
    }
}

- (void) resetPathNamed:(NSString *)name
{
    CamPath* curPath = [scrollPathRegistry objectForKey:name];
    if(curPath)
    {
        [curPath resetFollow];
    }
}

- (BOOL) isAtEndOfPathNamed:(NSString *)name
{
    BOOL result = NO;
    CamPath* curPath = [scrollPathRegistry objectForKey:name];
    if(curPath)
    {
        result = [curPath isAtEndOfPath];
    }    
    return result;
}

- (void) pausePathNamed:(NSString *)name
{
    CamPath* curPath = [scrollPathRegistry objectForKey:name];
    if(curPath)
    {
        curPath.paused = YES;
    }
}

- (void) unpausePathNamed:(NSString *)name
{
    CamPath* curPath = [scrollPathRegistry objectForKey:name];
    if(curPath)
    {
        curPath.paused = NO;
    }    
}

- (void) update:(NSTimeInterval)elapsed
{
    // update additional scroll paths for this level
    // do this regardless of whether a pause is in effect
    for(CamPath* cur in scrollPaths)
    {
        if(!([cur paused]))
        {
            [cur updateFollow:elapsed];
        }
    }

    // pause-able section    
    CGPoint newPos = pos;
    if((PAUSETYPE_NONE == pauseType) || 
       ((PAUSETYPE_TRIGGERONLY == pauseType) && ([camPath isInLoop])))
    {
        newPos = [self.camPath updateFollow:elapsed];
        if(newPos.y < pos.y)
        {
            // main path looped back; need to inform scroll-layer to do a jump
            [[[[LevelManager getInstance] curLevel] bgScroll] jumpToPos:newPos];
        }
        
        if((shouldUnpauseAndBreak) && (![camPath isInLoop]))
        {
            // handle the case caller wants to unpause and sync-up with a main-loop break
            // wait until the camPath is out of the loop before actually unpausing the trigger path
            paused = NO;
            shouldUnpauseAndBreak = NO;
            pauseType = PAUSETYPE_NONE;
        }
    }
    
    if(PAUSETYPE_NONE == pauseType)
    {
        // check triggers and fire events
        if(self.triggersArray)
        {
            CGPoint triggerPos = [self.triggerPath updateFollow:elapsed];
            
            GameManager* gameManager = [GameManager getInstance];
            int index = lastTrigger + 1;
            while(index < [triggersArray count])
            {
                Trigger* cur = [triggersArray objectAtIndex:index];
                if(triggerPos.y >= cur.triggerPoint)
                {
                    // triggered, fire event
                    switch([cur triggerEvent])
                    {
                        case TRIGGER_STARTSPAWNER:
                            [gameManager triggerNewSpawnerWithName:[cur label] triggerContext:[cur context]];
                            break;
                            
                        case TRIGGER_STOPSPAWNER:
                            [gameManager stopSpawnerWithName:[cur label]];
                            break;
                            
                        case TRIGGER_STARTINSTANCESPAWNER:
                            [gameManager triggerNewInstanceSpawnerWithName:[cur label] triggerContext:[cur context]];
                            break;
                            
                        case TRIGGER_STARTPLAYER_AUTOFIRE:
                            [gameManager startPlayerAutofire];
                            break;
                            
                        case TRIGGER_STOPPLAYER_AUTOFIRE:
                            [gameManager stopPlayerAutofire];
                            break;
                            
                        case TRIGGER_SHOW_LEVELLABEL:
                            [gameManager showLevelLabel:[cur label]];
                            break;
                            
                        case TRIGGER_SHOW_MESSAGE:
                            [gameManager showMessage:[cur label]];
                            break;
                            
                        case TRIGGER_DISMISS_MESSAGE:
                            [gameManager dismissMessage];
                            break;
                            
                        case TRIGGER_BLOCK_SCROLL:
                            [gameManager blockScrollCamFor:[cur label]];
                            break;
                            
                        case TRIGGER_BLOCK_SCROLLTRIGGERONLY:
                            if([camPath isInLoop])
                            {
                                // only activates if Main path is in a loop
                                BOOL blocked = [gameManager blockScrollTriggerFor:[cur label]];
                                if(!blocked)
                                {
                                    // if block not in effect (because the blocker has already been destroyed), 
                                    // bypass the block, but still sync up the trigger-path and the main-path
                                    pauseType = PAUSETYPE_TRIGGERONLY;
                                    shouldUnpauseAndBreak = YES;
                                    [self breakMainPathLoop];        
                                }
                            }
                            break;
                            
                        case TRIGGER_START_PICKUPRATION:
                            [gameManager startRationingPickups];
                            break;
                            
                        case TRIGGER_STOP_PICKUPRATION:
                            [gameManager stopRationingPickups];
                            break;
                            
                        case TRIGGER_ENEMY:
                            [gameManager triggerEnemy:[cur label]];
                            break;
                          
                        case TRIGGER_QUEUEPICKUP:
                            [gameManager queuePickupNamed:[cur label] number:1];
                            break;
                            
                        case TRIGGER_BASICPICKUP:
                            [gameManager queueBasicPickupNamed:[cur label] number:1];
                            break;
                            
                        case TRIGGER_STOP_PATHLOOP:
                            [self stopLoopForScrollPathNamed:[cur label]];
                            break;
                            
                        case TRIGGER_PAUSE_PATH:
                            [self pausePathNamed:[cur label]];
                            break;
                            
                        case TRIGGER_UNPAUSE_PATH:
                            [self unpausePathNamed:[cur label]];
                            break;
                            
                        case TRIGGER_START_MUSIC:
                            [[SoundManager getInstance] fadeInMusic2:[cur label] doLoop:YES];
                            break;
                            
                        case TRIGGER_STOP_MUSIC:
                            [[SoundManager getInstance] fadeOutMusic2];
                            break;
                            
                        case TRIGGER_SETVOLUME_MUSIC:
                            [[SoundManager getInstance] setVolumeMusic2:[[cur number] floatValue]];
                            break;
                            
                        case TRIGGER_ONESHOTSOUND:
                            [[SoundManager getInstance] playClip:[cur label]];
                            break;
                            
                        case TRIGGER_BREAKMAINPATHLOOP:
                            [self breakMainPathLoop];
                            break;
                            
                        case TRIGGER_SHOW_ROUTECOMPLETED:
                            [[GameManager getInstance] showRouteCompleted];
                            break;
                            
                        default:
                            // do nothing
                            break;
                    }
                    lastTrigger = index;
                    ++index;
                }
                else
                {
                    break;
                }
            }            
        }
    }
    
    // finally, commit the new position
    pos = newPos;
}


// call this method in the postUpdate routine; it needs to happen after player position has been updated;
- (void) offsetPosByPlayer:(Player *)player
{
    float playAreaWidth = BOUNDS_RIGHT - BOUNDS_LEFT;
    float newX = (player.pos.x * (playAreaWidth - frame.size.width) / playAreaWidth) - BOUNDS_LEFT;
    if(newX < BOUNDS_LEFT)
    {
        newX = 0.0f;
    }
    else if(newX > (BOUNDS_RIGHT - frame.size.width - frame.origin.x))
    {
        newX = (BOUNDS_RIGHT - frame.size.width - frame.origin.x);
    }
    dynamicPos.x = newX;
    
    // IMPORTANT: the x-coord is not adjusted because in gameplay space, the camera x-axis is the same as the world x-axis;
    // the camera position gets adjusted for the view transform to throw the view left and right, that is a rendering only adjustment
    // as far as the game is concerned (even for camera space objects), the camera x-coord is not changed
    //pos.x = newX;
}

- (CGRect) getPlayArea
{
    CGRect result = CGRectMake(BOUNDS_LEFT, 0.0f,
                               BOUNDS_RIGHT - BOUNDS_LEFT, frame.size.height);
    return result;
}

- (CGRect) getPlayFrame
{
    CGRect result = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
    return result;
}

- (float) translationScaleForLayerDistance:(float)layerDistance
{
    float result = (layerDistance * distanceFuncSlope) + (1.0f - (distanceMaxLayer * distanceFuncSlope));
    return result;
}

- (CGPoint) camWorldPointAtLayerDistance:(float)dist fromWorldPoint:(CGPoint)worldPoint
{
    float scale = [self translationScaleForLayerDistance:dist];
    CGPoint result = CGPointMake(worldPoint.x * scale, worldPoint.y * scale);
    return result;    
}

- (CGPoint) camOriginAtLayerDistance:(float)dist
{
    return [self camWorldPointAtLayerDistance:dist fromWorldPoint:pos];
}

- (CGPoint) camPointFromWorldPoint:(CGPoint)worldPoint atDistance:(float)dist
{
    CGPoint camOriginAtCurDist = [self camOriginAtLayerDistance:dist];
    CGPoint result = worldPoint;
    
    // transform to camera space
    result.x -= camOriginAtCurDist.x;
    result.y -= camOriginAtCurDist.y;
    
    return result;
}

#pragma mark - main path controls
- (void) startMainPath
{
    if((PAUSETYPE_TRIGGERONLY == pauseType) && ([camPath isInLoop]))
    {
        // if trigger-only pause, unpause and break from the main-loop at the same time
        shouldUnpauseAndBreak = YES;
        [self breakMainPathLoop];        
    }
    else
    {
        paused = NO;
        pauseType = PAUSETYPE_NONE;
        shouldUnpauseAndBreak = NO;
    }
}

- (void) stopMainPath:(PAUSETYPE)stopType
{
    if(PAUSETYPE_TRIGGERONLY == stopType)
    {
        // trigger-only pause only make sense when camPath is in a loop
        if([camPath isInLoop])
        {
            pauseType = stopType;
            shouldUnpauseAndBreak = NO;
        }
    }
    else if(PAUSETYPE_NONE < stopType)
    {
        pauseType = stopType;
        shouldUnpauseAndBreak = NO;
    }
}

- (void) breakMainPathLoop
{
    [camPath breakCurrentLoop];
}

@end
