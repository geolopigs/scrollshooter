//
//  GameCenterManager.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 10/3/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "GameCenterManager.h"
#import "GameCenterCategories.h"
#import "AchievementsData.h"

static NSString* const GKSCORES_FILENAME = @"toreport.gkscores";
static NSString* const GKACHIEVEMENTS_FILENAME = @"toreport.gkachievements";
NSString* const GKACHIEVEMENTS_UNUSED = @"unused";

@interface GameCenterManager (PrivateMethods)
- (BOOL) isGameCenterAPIAvailable;
- (void) authenticateLocalPlayer;
- (void) checkForScoresToReport;
- (void) checkForAchievementsToReport;
- (GKAchievement*) getAchievementForIdentifier:(NSString*)identifier;
- (void) loadAchievements;
- (void) initAchievementToReportWithDummyEntry;
@end

@implementation GameCenterManager
@synthesize leaderboardCategory;
@synthesize leaderboardTimeScope;
@synthesize enabled;
@synthesize localPlayerAuthenticated;
@synthesize localPlayerID;
@synthesize gkScoresFilepath;
@synthesize gkAchievementsFilepath = _gkAchievementsFilepath;
@synthesize scoresToReport;
@synthesize achievementsToReport = _achievementsToReport;
@synthesize achievementsDict = _achievementsDict;
@synthesize delegate = _delegate;
@synthesize authenticationDelegate = _authenticationDelegate;

#pragma mark - private methods
- (BOOL) isGameCenterAPIAvailable
{
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    // The device must be running iOS 7.0 or later.
    NSString *reqSysVer = @"7.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (localPlayerClassAvailable && osVersionSupported);
}

- (void) authenticateLocalPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        if(viewController != nil) {
            self.enabled = YES;
            // show auth view controller
            [self.authenticationDelegate showAuthenticationDialog:viewController];
        }
        else if(localPlayer.isAuthenticated) {
            self.enabled = YES;
            self.localPlayerAuthenticated = YES;
            self.localPlayerID = [GKLocalPlayer localPlayer].playerID;
            
            // check for scores waiting to be reported from previous session
            [self checkForScoresToReport];
            
            // load achievements from Game Center and report any outstanding achievements
            [self loadAchievements];
            [self checkForAchievementsToReport];
            
            if([self authenticationDelegate])
            {
                [self.authenticationDelegate didSucceedAuthentication];
            }
        }
        else {
            self.enabled = NO;
        }
        // remove authentication delegate upon completion (regardless of error or success)
        self.authenticationDelegate = nil;
    };
/*
//    [localPlayer authenticateWithCompletionHandler:^(NSError *error) {
        
        // assume game center is available except for the following errors
        self.enabled = YES;
        if(error)
        {
            if(GKErrorNotSupported == [error code])
            {
                // local player not supported means this device has 4.1 and yet does not support Game Center
                // disable manager to prevent any further processing
                self.enabled = NO;
            }
#if defined(DEBUG)
            else
            {
                NSLog(@"%@", [error description]);
            }
#endif
        }

        if([self enabled])
        {
            if (localPlayer.isAuthenticated)
            {
                self.localPlayerAuthenticated = YES;
                self.localPlayerID = [GKLocalPlayer localPlayer].playerID;
                
                // check for scores waiting to be reported from previous session
                [self checkForScoresToReport];   
                
                // load achievements from Game Center and report any outstanding achievements
                [self loadAchievements];
                [self checkForAchievementsToReport];
                
                if([self authenticationDelegate])
                {
                    [self.authenticationDelegate didSucceedAuthentication];
                }
            }
        }
        
        // remove authentication delegate upon completion (regardless of error or success)
        self.authenticationDelegate = nil;
    }];
  */
}


#pragma mark - public methods

- (id) init
{
    self = [super init];
    if(self)
    {
        self.leaderboardCategory = nil;
        self.leaderboardTimeScope = GKLeaderboardTimeScopeAllTime;
        
        self.enabled = NO;
        self.localPlayerAuthenticated = NO;
        self.localPlayerID = nil;
        
        // array and file for saving unreported scores
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        self.gkScoresFilepath = [documentsDirectory stringByAppendingPathComponent:GKSCORES_FILENAME];
        self.gkAchievementsFilepath = [documentsDirectory stringByAppendingPathComponent:GKACHIEVEMENTS_FILENAME];
        self.scoresToReport = nil;
        self.achievementsDict = [NSMutableDictionary dictionary];
        self.achievementsToReport = nil;
        
        self.delegate = nil;
        self.authenticationDelegate = nil;
    }
    return self;
}

- (void) dealloc
{
    self.authenticationDelegate = nil;
    self.delegate = nil;
    self.localPlayerID = nil;
    self.achievementsToReport = nil;
    self.achievementsDict = nil;
    self.scoresToReport = nil;
    self.gkAchievementsFilepath = nil;
    self.gkScoresFilepath = nil;
    self.leaderboardCategory = nil;
    [super dealloc];
}

- (void) checkAndAuthenticate
{
    if([self isGameCenterAPIAvailable])
    {
        [self authenticateLocalPlayer];
    }
}

- (void) reportScore:(int64_t)score forCategory:(NSString*)category
{
    if(enabled && localPlayerAuthenticated)
    {
        /*
        GKScore *scoreReporter = [[[GKScore alloc] initWithCategory:category] autorelease];
        scoreReporter.value = score;
        
        [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
            if (error != nil)
            {
                // error, save GKScore for later attempts
                NSString* key = [NSString stringWithFormat:@"%@_%@", category, [scoreReporter playerID]];
                [scoresToReport setObject:scoreReporter forKey:key];
            }
        }];
         */
    }
}

- (void) loadAchievements
{
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error)
     {
         if (error == nil)
         {
             for (GKAchievement* achievement in achievements)
             {
                 [_achievementsDict setObject: achievement forKey: achievement.identifier];
             }
             
             if(_delegate)
             {
                 [_delegate finishedLoadingGameCenterAchievements];
             }
         }
     }];
}

- (GKAchievement*) getAchievementForIdentifier:(NSString*)identifier
{
    GKAchievement *achievement = [_achievementsDict objectForKey:identifier];
    if (achievement == nil)
    {
        achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
        [_achievementsDict setObject:achievement forKey:achievement.identifier];
    }
    return [[achievement retain] autorelease];
}

- (void) reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent
{
    if(enabled && localPlayerAuthenticated)
    {
        GKAchievement* achievement = [self getAchievementForIdentifier:identifier];
        if(achievement)
        {
            if(percent > [achievement percentComplete])
            {
                achievement.percentComplete = percent;
                [GKAchievement reportAchievements:@[achievement] withCompletionHandler:^(NSError *error)
                 {
                     if (error != nil)
                     {
                         [_achievementsToReport setObject:achievement forKey:[achievement identifier]];
                     }
                 }];
            }
        }
    }
}

- (void) resetAchievements
{
    // Clear all locally saved achievement objects.
    self.achievementsDict = [[NSMutableDictionary alloc] init];
    [self initAchievementToReportWithDummyEntry];
    
    // Clear all progress saved on Game Center
    [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"failed to clear progress on Game Center, try again later");
         }
    }];
}

- (void) checkForScoresToReport
{
    if(enabled && localPlayerAuthenticated)
    {
        if(![self scoresToReport])
        {
            NSFileManager* fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:gkScoresFilepath]) 
            {
                NSData* readData = [NSData dataWithContentsOfFile:gkScoresFilepath];
                self.scoresToReport = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
            }
        }
        
        if([self scoresToReport])
        {
            // report score for each category
            NSArray* categoryNames = [NSArray arrayWithObjects:GAMECENTER_CATEGORY_HIGHSCORE, 
                                      GAMECENTER_CATEGORY_PIGGYBANK, nil];
//                                      GAMECENTER_CATEGORY_TOURNEYHIGH,
//                                      GAMECENTER_CATEGORY_TOURNEYWINS, nil];
            for(NSString* cur in categoryNames)
            {
                NSString* key = [NSString stringWithFormat:@"%@_%@", cur, localPlayerID];
                GKScore* score = [scoresToReport objectForKey:key];
                if(score)
                {
                    /*
                    [score reportScoreWithCompletionHandler:^(NSError *error) {
                        if (error != nil)
                        {
                            // error, do nothing; we'll just try again later
                        }
                        else
                        {
                            // no error, then clear the entry out of the scoresToReport dictionary
                            [self.scoresToReport removeObjectForKey:[NSString stringWithFormat:@"%@_%@", [score category], [score playerID]]]; 
                        }
                    }];  
                     */
                }
            }
        }
        else
        {
            // create a dictionary with at least one entry so that it is never empty
            self.scoresToReport = [NSMutableDictionary dictionaryWithObject:GAMECENTER_INTERNAL_APPNAME forKey:@"appname"];
        }
    }
}

- (void) checkForAchievementsToReport
{
    if(enabled && localPlayerAuthenticated)
    {
        if(![self achievementsToReport])
        {
            NSFileManager* fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:_gkAchievementsFilepath]) 
            {
                NSData* readData = [NSData dataWithContentsOfFile:_gkAchievementsFilepath];
                self.achievementsToReport = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
            }
        }
        
        if([self achievementsToReport])
        {
            NSArray* achievementIdsToReport = [_achievementsToReport allKeys];
            for(NSString* cur in achievementIdsToReport)
            {
                // report any outstanding achievements from previous session, skipping over the dummy entry
                if(![cur isEqualToString:GKACHIEVEMENTS_UNUSED])
                {
                    GKAchievement* achievement = [self getAchievementForIdentifier:cur];
                    GKAchievement* toReport = [_achievementsToReport objectForKey:cur];
                    if(achievement && toReport)
                    {
                        float achievementPercent = [achievement percentComplete];
                        float toReportPercent = [toReport percentComplete];
                        if(achievementPercent < toReportPercent)
                        {
                            // report it
                            [_achievementsToReport removeObjectForKey:cur];
                            [self reportAchievementIdentifier:cur percentComplete:toReportPercent];
                        }
                    }
                }
            }
        }
        else
        {
            // create a dummy entry
            [self initAchievementToReportWithDummyEntry];
        }
    }
}

- (void) initAchievementToReportWithDummyEntry
{
    self.achievementsToReport = [NSMutableDictionary dictionary];
    GKAchievement* dummy = [self getAchievementForIdentifier:GKACHIEVEMENTS_UNUSED];
    [self.achievementsToReport setObject:dummy forKey:GKACHIEVEMENTS_UNUSED];    
}

- (BOOL) isGameCenterAvailable
{
    return enabled;
}

- (BOOL) isAuthenticated
{
    return [[GKLocalPlayer localPlayer] isAuthenticated];
}

#pragma mark - App interruptions handling
- (void) appWillTerminate
{
    // do nothing, this doesn't seem to get called when the user explicitly quits the app using double-home-button
}

- (void) appDidEnterBackground
{
    // save scoresToReport to a file
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:scoresToReport];
	[data writeToFile:gkScoresFilepath atomically:YES];
    /*
    /// DO NOT CHECK IN
    /// TEST CASE for achievements-to-report crash
    {
        GKAchievement* achievement = [self getAchievementForIdentifier:GAMECENTER_ACHIEVEMENT_250k];
        if(achievement)
        {
            achievement.percentComplete = 8.0f;
            [_achievementsToReport setObject:achievement forKey:[achievement identifier]];
        }
    }
    {
        GKAchievement* achievement2 = [self getAchievementForIdentifier:GAMECENTER_ACHIEVEMENT_500k];
        if(achievement2)
        {
            achievement2.percentComplete = 4.0f;
            [_achievementsToReport setObject:achievement2 forKey:[achievement2 identifier]];
        }
    }
    {
        GKAchievement* achievement3 = [self getAchievementForIdentifier:GAMECENTER_ACHIEVEMENT_1M];
        if(achievement3)
        {
            achievement3.percentComplete = 2.0f;
            [_achievementsToReport setObject:achievement3 forKey:[achievement3 identifier]];
        }
    }
    /// DO NOT CHECK IN
    */
    
    // save achievementsToReport to a file
    NSData* achievementsData = [NSKeyedArchiver archivedDataWithRootObject:_achievementsToReport];
    [achievementsData writeToFile:_gkAchievementsFilepath atomically:YES];

    // invalidate localplayer; this will be authenticated again when the handler gets called automatically as the app comes back
    localPlayerAuthenticated = NO;
    self.localPlayerID = nil;
}

#pragma mark - Singleton
static GameCenterManager *singleton = nil;

+ (GameCenterManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[GameCenterManager alloc] init] retain];
		}
	}
	return singleton;
}

+ (void) destroyInstance
{
	@synchronized(self)
	{
		[singleton release];
		singleton = nil;
	}
}



@end
