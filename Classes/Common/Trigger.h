//
//  Trigger.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

enum triggerEvent
{
    TRIGGER_STARTSPAWNER = 0,
    TRIGGER_STOPSPAWNER,
    TRIGGER_STARTINSTANCESPAWNER,
    TRIGGER_STARTPLAYER_AUTOFIRE,
    TRIGGER_STOPPLAYER_AUTOFIRE,
    TRIGGER_SHOW_LEVELLABEL,
    TRIGGER_SHOW_MESSAGE,
    TRIGGER_DISMISS_MESSAGE,
    TRIGGER_BLOCK_SCROLL,
    TRIGGER_BLOCK_SCROLLTRIGGERONLY,    // only blocks the Trigger Path, MainPath still keeps going;
                                        // to ensure the game doesn't go beyond the end of the background tiles, this
                                        // trigger only activates when the MainPath is in a loop;
    TRIGGER_START_PICKUPRATION,
    TRIGGER_STOP_PICKUPRATION,
    TRIGGER_ENEMY,
    TRIGGER_QUEUEPICKUP,
    TRIGGER_BASICPICKUP,           // for setting basic pickups that are queued each time player spawns
    TRIGGER_STOP_PATHLOOP,          // for non-Main paths
    TRIGGER_PAUSE_PATH,             // for non-Main paths
    TRIGGER_UNPAUSE_PATH,           // for non-Main paths
    TRIGGER_START_MUSIC,
    TRIGGER_STOP_MUSIC,
    TRIGGER_SETVOLUME_MUSIC,
    TRIGGER_ONESHOTSOUND,
    TRIGGER_BREAKMAINPATHLOOP,
    TRIGGER_CARGOCHECKPOINT,        // this triggers an upfront payment (a fraction of the price) on
                                    // the number of cargos the player has at the checkpoint
    TRIGGER_ACHIEVEMENTSSUMMARY,    // this triggers summary of achievements completed so far on the hud
    TRIGGER_SHOW_ROUTECOMPLETED,    // show the RouteCompleted stats screen
    
    TRIGGER_EVENT_NUM,
    TRIGGER_EVENT_INVALID
};

@interface Trigger : NSObject
{
    float       triggerPoint;
    int         triggerEvent;
    NSString*   label;
    NSNumber*   number;
    NSDictionary* context;
}
@property (nonatomic,assign) float triggerPoint;
@property (nonatomic,assign) int   triggerEvent;
@property (nonatomic,retain) NSString*  label;
@property (nonatomic,retain) NSNumber* number;
@property (nonatomic,retain) NSDictionary* context;
- (id) initWithPoint:(float)point 
               event:(NSString*)event 
               label:(NSString*)labelString 
              number:(NSNumber*)triggerNumber 
             context:(NSDictionary*)contextDictionary;

@end
