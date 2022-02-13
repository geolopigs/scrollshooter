//
//  Trigger.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/4/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "Trigger.h"

@implementation Trigger
@synthesize triggerPoint;
@synthesize triggerEvent;
@synthesize label;
@synthesize number;
@synthesize context;

static NSString* const EVENTNAME_STARTSPAWNER = @"startSpawner";
static NSString* const EVENTNAME_STOPSPAWNER = @"stopSpawner";
static NSString* const EVENTNAME_STARTINSTANCESPAWNER = @"startInstanceSpawner";
static NSString* const EVENTNAME_STARTPLAYER_AUTOFIRE = @"startPlayerAutofire";
static NSString* const EVENTNAME_STOPPLAYER_AUTOFIRE = @"stopPlayerAutofire";
static NSString* const EVENTNAME_SHOW_LEVELLABEL = @"showLevelLabel";
static NSString* const EVENTNAME_SHOW_MESSAGE = @"showMessage";
static NSString* const EVENTNAME_DISMISS_MESSAGE = @"dismissMessage";
static NSString* const EVENTNAME_BLOCK_SCROLL = @"blockScroll";
static NSString* const EVENTNAME_BLOCK_SCROLLTRIGGERONLY = @"blockScrollTriggerPath";
static NSString* const EVENTNAME_START_PICKUPRATION = @"startPickupRation";
static NSString* const EVENTNAME_STOP_PICKUPRATION = @"stopPickupRation";
static NSString* const EVENTNAME_TRIGGER_ENEMY = @"triggerEnemy";
static NSString* const EVENTNAME_QUEUEPICKUP = @"queuePickup";
static NSString* const EVENTNAME_BASICPICKUP = @"basicPickup";
static NSString* const EVENTNAME_STOP_PATHLOOP = @"stopPathLoop";
static NSString* const EVENTNAME_PAUSE_PATH = @"pausePath";
static NSString* const EVENTNAME_UNPAUSE_PATH = @"unpausePath";
static NSString* const EVENTNAME_START_MUSIC = @"startMusic";
static NSString* const EVENTNAME_STOP_MUSIC = @"stopMusic";
static NSString* const EVENTNAME_SETVOLUME_MUSIC = @"volumeMusic";
static NSString* const EVENTNAME_ONESHOTSOUND = @"oneShotSound";
static NSString* const EVENTNAME_BREAKMAINPATHLOOP = @"breakMainPathLoop";
static NSString* const EVENTNAME_CARGOCHECKPOINT = @"cargoCheckpoint";
static NSString* const EVENTNAME_ACHIEVEMENTSSUMMARY = @"achievementsSummary";
static NSString* const EVENTNAME_SHOW_ROUTECOMPLETED = @"showRouteCompleted";

- (id)initWithPoint:(float)point 
              event:(NSString*)event 
              label:(NSString*)labelString 
             number:(NSNumber*)triggerNumber 
            context:(NSDictionary *)contextDictionary
{
    self = [super init];
    if (self) 
    {
        self.triggerPoint = point;
        self.label = labelString;
        self.number = triggerNumber;
        self.context = contextDictionary;
        
        if([event isEqualToString:EVENTNAME_STARTSPAWNER])
        {
            self.triggerEvent = TRIGGER_STARTSPAWNER;
        }
        else if([event isEqualToString:EVENTNAME_STOPSPAWNER])
        {
            self.triggerEvent = TRIGGER_STOPSPAWNER;
        }
        else if([event isEqualToString:EVENTNAME_STARTINSTANCESPAWNER])
        {
            self.triggerEvent = TRIGGER_STARTINSTANCESPAWNER;
        }
        else if([event isEqualToString:EVENTNAME_STARTPLAYER_AUTOFIRE])
        {
            self.triggerEvent = TRIGGER_STARTPLAYER_AUTOFIRE;
        }
        else if([event isEqualToString:EVENTNAME_STOPPLAYER_AUTOFIRE])
        {
            self.triggerEvent = TRIGGER_STOPPLAYER_AUTOFIRE;
        }
        else if([event isEqualToString:EVENTNAME_SHOW_LEVELLABEL])
        {
            self.triggerEvent = TRIGGER_SHOW_LEVELLABEL;
        }
        else if([event isEqualToString:EVENTNAME_SHOW_MESSAGE])
        {
            self.triggerEvent = TRIGGER_SHOW_MESSAGE;
        }
        else if([event isEqualToString:EVENTNAME_DISMISS_MESSAGE])
        {
            self.triggerEvent = TRIGGER_DISMISS_MESSAGE;
        }
        else if([event isEqualToString:EVENTNAME_BLOCK_SCROLL])
        {
            self.triggerEvent = TRIGGER_BLOCK_SCROLL;
        }
        else if([event isEqualToString:EVENTNAME_BLOCK_SCROLLTRIGGERONLY])
        {
            self.triggerEvent = TRIGGER_BLOCK_SCROLLTRIGGERONLY;
        }
        else if([event isEqualToString:EVENTNAME_START_PICKUPRATION])
        {
            self.triggerEvent = TRIGGER_START_PICKUPRATION;
        }
        else if([event isEqualToString:EVENTNAME_STOP_PICKUPRATION])
        {
            self.triggerEvent = TRIGGER_STOP_PICKUPRATION;
        }
        else if([event isEqualToString:EVENTNAME_TRIGGER_ENEMY])
        {
            self.triggerEvent = TRIGGER_ENEMY;
        }
        else if([event isEqualToString:EVENTNAME_QUEUEPICKUP])
        {
            self.triggerEvent = TRIGGER_QUEUEPICKUP;
        }
        else if([event isEqualToString:EVENTNAME_BASICPICKUP])
        {
            self.triggerEvent = TRIGGER_BASICPICKUP;
        }
        else if([event isEqualToString:EVENTNAME_STOP_PATHLOOP])
        {
            self.triggerEvent = TRIGGER_STOP_PATHLOOP;
        }
        else if([event isEqualToString:EVENTNAME_START_MUSIC])
        {
            self.triggerEvent = TRIGGER_START_MUSIC;
        }
        else if([event isEqualToString:EVENTNAME_STOP_MUSIC])
        {
            self.triggerEvent = TRIGGER_STOP_MUSIC;
        }
        else if([event isEqualToString:EVENTNAME_SETVOLUME_MUSIC])
        {
            self.triggerEvent = TRIGGER_SETVOLUME_MUSIC;
        }
        else if([event isEqualToString:EVENTNAME_ONESHOTSOUND])
        {
            self.triggerEvent = TRIGGER_ONESHOTSOUND;
        }
        else if([event isEqualToString:EVENTNAME_PAUSE_PATH])
        {
            self.triggerEvent = TRIGGER_PAUSE_PATH;
        }
        else if([event isEqualToString:EVENTNAME_UNPAUSE_PATH])
        {
            self.triggerEvent = TRIGGER_UNPAUSE_PATH;
        }
        else if([event isEqualToString:EVENTNAME_BREAKMAINPATHLOOP])
        {
            self.triggerEvent = TRIGGER_BREAKMAINPATHLOOP;
        }
        else if([event isEqualToString:EVENTNAME_CARGOCHECKPOINT])
        {
            self.triggerEvent = TRIGGER_CARGOCHECKPOINT;
        }
        else if([event isEqualToString:EVENTNAME_ACHIEVEMENTSSUMMARY])
        {
            self.triggerEvent = TRIGGER_ACHIEVEMENTSSUMMARY;
        }
        else if([event isEqualToString:EVENTNAME_SHOW_ROUTECOMPLETED])
        {
            self.triggerEvent = TRIGGER_SHOW_ROUTECOMPLETED;
        }
        else
        {
            self.triggerEvent = TRIGGER_EVENT_INVALID;            
        }
    }
    return self;
}

- (void) dealloc
{
    self.context = nil;
    self.label = nil;
    [super dealloc];
}

@end
