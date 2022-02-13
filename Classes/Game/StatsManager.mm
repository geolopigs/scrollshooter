//
//  StatsManager.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "StatsManager.h"
#import "EnemyRegistryData.h"
#import "LootRegistryData.h"
#import "StatsData.h"
#import "PlayerData.h"
#import "CargoManager.h"
#import "LevelManager.h"
#import "GameCenterManager.h"
#import "DebugOptions.h"
#import "EnvData.h"
#import "RouteInfo.h"
#import "LevelManager.h"
#import "AchievementsManager.h"
#import "GameManager.h"
#import "PlayerInventory.h"
#import "Player.h"
#import "PogAnalytics+PeterPog.h"

static NSString* const STATS_FILENAME = @"stats.pog";
static NSString* const PLAYER_FILENAME = @"player.pog";
static NSString* const DEFAULT_ENVNAME = @"Uncategorized";
static const unsigned int MAX_CONTINUES = 3;
static const unsigned int COINS_JUSTFORPLAYING = 10;

// Notifications
NSString* const kStatsManagerNoteDidChangeCoins = @"CoinsChanged";

// TODO: refactor this into a plist;
// each level requires this much more in devcost
static const unsigned int ROUTE_DEVCOST_INCREMENT = 200;

@interface StatsManager (PrivateMethods)
- (BOOL)curEnvHasLockedLevels;
- (unsigned int)curEnvGetNextToUnlock;
- (void) commitGradeScore;
- (void) commitCargosDelivered;
- (void) commitAddFlightTime:(NSTimeInterval)time;
- (void) commitCoinsCollected;
- (void) commitHighestMultiplier;

- (void) resetMultiplierForLevelRestart;
- (void) refreshSessionMultiplier;
@end

@implementation StatsManager
@synthesize enemyReg;
@synthesize lootReg;
@synthesize delegate;
@synthesize curEnvName;
@synthesize curLevel;
@synthesize gradeScoreLevelComplete;
@synthesize pointsTotal;
@synthesize cargosCollectCount;
@synthesize sessionFlightTime = _sessionFlightTime;
@synthesize sessionCargosDelivered = _sessionCargosDelivered;
@synthesize sessionCashEarned = _sessionCashEarned;
@synthesize sessionScore = _sessionScore;
@synthesize flightTimeCurLevel = _flightTimeCurLevel;
@synthesize continuesRemaining;
@synthesize sessionContinueCount = _sessionContinueCount;
@synthesize statsFilepath;
@synthesize playerFilepath;
@synthesize statsData;
@synthesize playerData;
@synthesize wasLastScoreHighscore;
@synthesize previousHighscore;

#pragma mark - StatsManager
- (id)init
{
    self = [super init];
    if (self) 
    {
        // load the registries
        self.enemyReg = [[EnemyRegistryData alloc] initFromFilename:@"EnemyRegistry"];
        self.lootReg = [[LootRegistryData alloc] initFromFilename:@"LootRegistry"];
        self.delegate = nil;
        self.curEnvName = DEFAULT_ENVNAME;
        self.curLevel = 0;
        self.pointsCurLevel = 0;
        self.gradeScoreLevelComplete = 0;
        self.cargosCurLevel = 0;
        self.pointsTotal = 0;
        _sessionFlightTime = 0.0;
        _flightTimeCurLevel = 0.0;
        _sessionCargosDelivered = 0;
        _sessionCashEarned = 0;
        _sessionScore = 0;
        self.cargosCollectCount = 0;
        self.continuesRemaining = 1;
        curHealth = 0;
        _sessionContinueCount = 0;
        _accCompletedMultiplier = 1;
        _accMultiplier = 1;
        _curLevelMultiplier = 0;
        
        // setup path to data files in the user-domain
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        self.statsFilepath = [documentsDirectory stringByAppendingPathComponent:STATS_FILENAME];
        self.playerFilepath = [documentsDirectory stringByAppendingPathComponent:PLAYER_FILENAME];

        // saved data will be setup in the load functions; init to nil here;
        self.statsData = [[StatsData alloc] init];
        self.playerData = nil;
        
        deliveryCargoNum = 0;
        deliveryCashEarned = 0;
        wasLastScoreHighscore = NO;
        previousHighscore = 0;
        
        lastReportedHighscore = 0;
        lastReportedPiggybank = 0;
        _lastReportedTourneyHigh = 0;
        _lastReportedTourneyWins = 0;
    }
    
    return self;
}

- (void) dealloc
{
    self.playerData = nil;
    self.statsData = nil;
    self.curEnvName = nil;
    self.delegate = nil;
    self.lootReg = nil;
    self.enemyReg = nil;
    [super dealloc];
}

#pragma mark - save load
- (void) loadPlayerData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:playerFilepath]) 
	{
		NSData* readData = [NSData dataWithContentsOfFile:playerFilepath];
		self.playerData = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
	}
	else
	{
        self.playerData = [[PlayerData alloc] init];
	}    
}

- (void) savePlayerData
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:playerData];
	[data writeToFile:playerFilepath atomically:YES];
}

- (void) loadStatsData
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:statsFilepath]) 
	{
		NSData* readData = [NSData dataWithContentsOfFile:statsFilepath];
		self.statsData = [NSKeyedUnarchiver unarchiveObjectWithData:readData];
	}
	else
	{
        self.statsData = [[StatsData alloc] init];
	}    
}

- (void) saveStatsData
{
#if defined(DEBUG)
    if([[DebugOptions getInstance] isAllLevelsUnlocked])
    {
        // don't save anything if the unlock all option is On; otherwise, we may end up with non-consecutive 
        // level progression data files
    }
    else
#endif
    {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:statsData];
        [data writeToFile:statsFilepath atomically:YES];
    }
}

#pragma mark - per frame updates
- (void) updateFlightTime:(NSTimeInterval)elapsed
{
    self.flightTimeCurLevel += elapsed;
}


#pragma mark - management

- (void) setupForEnvNamed:(NSString*)envName level:(unsigned int)levelNum
{
    self.curEnvName = envName;
    self.curLevel = levelNum;
    self.pointsCurLevel = 0;
    self.cargosCurLevel = 0;
    self.flightTimeCurLevel = 0.0;
    _curLevelMultiplier = 0;
}

- (void) setupForNewGame
{
    // reset per-game-session stats
    LevelManager* levelMgr = [LevelManager getInstance];
    self.continuesRemaining = [[levelMgr envData] getNumContinuesForEnvNamed:[levelMgr selectedEnvname]];
    [self resetPointsTotal];
    [self resetScoreMultiplier];
    _sessionFlightTime = 0.0;
    _sessionCargosDelivered = 0;
    _sessionCashEarned = 0;
    _sessionScore = 0;
    _sessionContinueCount = 0;
}

- (void) resetCurLevel
{
    [self setCargosCurLevel:0];
    [self resetPointsCur];
    [self setFlightTimeCurLevel:0.0];
    [self resetMultiplierForLevelRestart];
}

- (void) resetPointsCur
{
    self.pointsCurLevel = 0;
    self.gradeScoreLevelComplete = 0;
}

- (void) resetPointsTotal
{
    self.pointsTotal = 0;
}

- (void) resetCargosCur
{
    self.cargosCurLevel = 0;
    self.cargosCollectCount = 0;
}

- (void) resetScoreMultiplier
{
    _accCompletedMultiplier = 1;
    _accMultiplier = 1;
    _curLevelMultiplier = 0;
}

- (void) resetFlightTime
{
    [self setFlightTimeCurLevel:0.0];
    _sessionFlightTime = 0.0;
}

- (void) resetSessionCash
{
    _sessionCashEarned = 0;
}

- (void) accTourneyWins:(unsigned int)num
{
    statsData.numTourneyWins += num;
}

- (unsigned int) getTourneyWins
{
    return [statsData numTourneyWins];
}

- (void) completeLevel
{
    // cargos to cash calculation
    unsigned int cash = [[CargoManager getInstance] cashFromCargo:cargosCurLevel];
    
    // save off stats for the level completion screen
    deliveryCargoNum = cargosCurLevel;
    deliveryCashEarned = cash;
    
    // achievements
    [[AchievementsManager getInstance] deliveredCargos:cargosCurLevel];
    [[AchievementsManager getInstance] incrRouteCount];
    [[AchievementsManager getInstance] completeRoute:curLevel];
    [[AchievementsManager getInstance] completeRouteWithFullHealth:[[[GameManager getInstance] playerShip] health]];
    enum ScoreGrades scoreGrade = [self gradeForScore:pointsCurLevel env:curEnvName level:curLevel];
    if(SCOREGRADE_A == scoreGrade)
    {
        [[AchievementsManager getInstance] completeGradeAOnRoute:curLevel];
    }
    
    // commit 
    int newCoinsAmount = [playerData pogCoins] + cash;
    [self commitCoins:newCoinsAmount];
    
    // add up points bonuses
    pointsCurLevel += cash;
    
    // commit progression and highscore
    [self commitAddFlightTime:[self flightTimeCurLevel]];
    [[AchievementsManager getInstance] incrFlightTime:[self flightTimeCurLevel]];
    _sessionFlightTime += [self flightTimeCurLevel];
    self.flightTimeCurLevel = 0.0f;
    _sessionCargosDelivered += cargosCurLevel;
    _sessionCashEarned += deliveryCashEarned;
    [self refreshSessionMultiplier];
    [statsData setHasCompleted:YES forEnv:curEnvName level:curLevel];
    [self commitGradeScore];
    [self commitHighScore];
    [self commitHighestMultiplier];
    
    // tally up the score for the next level
    pointsTotal += pointsCurLevel;
    pointsCurLevel = 0;    
    
    // analytics
    [[PogAnalytics getInstance] logRouteCompletedForRoute:curLevel];
}

- (void) completeTimebasedLevel
{
    // save off stats for the level completion screen
    deliveryCargoNum = cargosCurLevel;

    // commit (timebased does not reward player with coins)
    [self refreshSessionMultiplier];
    [self commitHighScore];
    [self commitAddFlightTime:[self flightTimeCurLevel]];
    _sessionFlightTime += [self flightTimeCurLevel];
    self.flightTimeCurLevel = 0.0f;
    [[AchievementsManager getInstance] incrFlightTime:_sessionFlightTime];
    [self commitHighestMultiplier];

    // tally up the score for the next level
    pointsTotal += pointsCurLevel;
    pointsCurLevel = 0;    
}

- (void) completeGameSessionWithCoins:(BOOL)creditCoins
{
    // accumulate flight time
    [self commitAddFlightTime:[self flightTimeCurLevel]];
    [[AchievementsManager getInstance] incrFlightTime:[self flightTimeCurLevel]];
    _sessionFlightTime += [self flightTimeCurLevel];
    self.flightTimeCurLevel = 0.0;
    
    // commit cargos delivered (don't accumulate here because cargos are only considered delivered if
    // player finishes a route)
    [self commitCargosDelivered];
    
    if(creditCoins)
    {
        // reward one coin per undelivered cargo as consolation
        unsigned int gameOverCoins = (cargosCurLevel + COINS_JUSTFORPLAYING);
        
        // commit coints to piggybank
        unsigned int piggybankCoins = gameOverCoins + [playerData pogCoins];
        [self commitCoins:piggybankCoins];
        
        // then commit the coins earned in this session to the coins-earned stats
        _sessionCashEarned += gameOverCoins;
        [self commitCoinsCollected];
    }
    
    // commit highscore
    _sessionScore = pointsTotal + pointsCurLevel;
    [[StatsManager getInstance] commitHighScore];
    
    // commit multiplier
    [self refreshSessionMultiplier];
    [self commitHighestMultiplier];
}

- (void) resetAllHighscores
{
    [self resetPointsTotal];
    [self resetPointsCur];
    [statsData resetHighscores];
    [self resetScoreMultiplier];
    [statsData setHighMultiplier:1];
}

- (void) commitGradeScore
{
    gradeScoreLevelComplete = pointsCurLevel;
    unsigned int curScore = [statsData getGradeScoreForEnv:curEnvName level:curLevel];
    if(curScore < pointsCurLevel)
    {
        [statsData setGradeScore:pointsCurLevel forEnv:curEnvName level:curLevel];
    }
}

- (void) commitHighScore
{
    // global highscore
    unsigned int score = pointsTotal + pointsCurLevel;
    if(score > statsData.highscore)
    {
        previousHighscore = statsData.highscore;
        statsData.highscore = score;
        wasLastScoreHighscore = YES;
    }
    else
    {
        wasLastScoreHighscore = NO;
    }
    
    // level specific highscore
    unsigned int curScore = [statsData getHighscoreForEnv:curEnvName level:curLevel];
    if(curScore < pointsCurLevel)
    {
        [statsData setHighscore:pointsCurLevel forEnv:curEnvName level:curLevel];
    }

    // save to file
    [[StatsManager getInstance] saveStatsData];
}

- (void) commitCargosDelivered
{
    // accumulate to cargos delivered tally
    unsigned int newCargosTally = deliveryCargoNum + [statsData cargosDelivered];
    statsData.cargosDelivered = newCargosTally;
    
    // update level-specific cargos-delivered watermark
    unsigned int curWatermark = [statsData getCargosDeliveredForEnv:curEnvName level:curLevel];
    if(curWatermark < deliveryCargoNum)
    {
        [statsData setCargosDelivered:deliveryCargoNum forEnv:curEnvName level:curLevel];
    }
}

- (void) commitCoins:(int)newAmount
{
    // update achievements
    unsigned int oldCoins = playerData.pogCoins;
    if(oldCoins < newAmount)
    {
        unsigned int incr = newAmount - oldCoins;
        [[AchievementsManager getInstance] incrCoins:incr];
    }
    
    // update playerdata
    playerData.pogCoins = newAmount;
    [self savePlayerData];
    
    // broadcast coins changed notification
    [[NSNotificationCenter defaultCenter] postNotificationName:kStatsManagerNoteDidChangeCoins object:self];
//    NSLog(@"commitCoins %d", newAmount);
}

- (void) commitAddFlightTime:(NSTimeInterval)time
{
    NSTimeInterval newTime = time + [statsData flightTime];
    [statsData setFlightTime:newTime];
    [[StatsManager getInstance] saveStatsData];
}

- (void) commitCoinsCollected
{
    unsigned int newAmount = _sessionCashEarned + [statsData pogcoinsCollected];
    
    [statsData setPogcoinsCollected:newAmount];
    [[StatsManager getInstance] saveStatsData];
}

- (void) commitAddCoins:(int)addAmount
{
    // commit to stash
    int cur = [self getTotalCash];
    int newAmount = cur + addAmount;
    [self commitCoins:newAmount];
    
    // also commit to the collected coins stats
    int collected = [statsData pogcoinsCollected];
    collected += addAmount;
    [statsData setPogcoinsCollected:collected];
    
    [self saveStatsData];
    
//    NSLog(@"commitAddCoints %d, total became %d", addAmount, newAmount);
}

- (void) reportScoresToGameCenter
{
    // highscore
    if(lastReportedHighscore < statsData.highscore)
    {   
        [[GameCenterManager getInstance] reportScore:statsData.highscore forCategory:GAMECENTER_CATEGORY_HIGHSCORE];
        lastReportedHighscore = statsData.highscore;
    }
    
    // piggybank
    if(lastReportedPiggybank < playerData.pogCoins)
    {
        [[GameCenterManager getInstance] reportScore:playerData.pogCoins forCategory:GAMECENTER_CATEGORY_PIGGYBANK];
        lastReportedPiggybank = playerData.pogCoins;
    }
    
    // tourney highscore
//    unsigned int tourneyHigh = [[StatsManager getInstance] getHighscoreForEnv:@"Tourney" level:0];
//    if(_lastReportedTourneyHigh < tourneyHigh)
//    {
//        [[GameCenterManager getInstance] reportScore:tourneyHigh forCategory:GAMECENTER_CATEGORY_TOURNEYHIGH];
//        _lastReportedTourneyHigh = tourneyHigh;
//    }
//    
//    // tourney wins
//    unsigned int tourneyWins = [[StatsManager getInstance] getTourneyWins];
//    if(_lastReportedTourneyWins < tourneyWins)
//    {
//        [[GameCenterManager getInstance] reportScore:tourneyWins forCategory:GAMECENTER_CATEGORY_TOURNEYWINS];
//        _lastReportedTourneyWins = tourneyWins;
//    }
}

- (unsigned int)curEnvGetNextToUnlock
{
    unsigned int result = [self nextIncompleteLevelForEnv:curEnvName];
    return result;
}

- (BOOL)curEnvHasLockedLevels
{
    BOOL result = NO;
    unsigned int nextToUnlock = [self curEnvGetNextToUnlock];
    if(nextToUnlock < [[LevelManager getInstance] getNumLevelsForEnv:curEnvName])
    {
        result = YES;
    }
    return result;
}


#pragma mark - accessors
- (void) setPointsCurLevel:(unsigned int)newPoints
{
    pointsCurLevel = newPoints;
    // update UI
    if(delegate)
    {
        [delegate updateScore:(pointsTotal + pointsCurLevel)];
    }
}

- (unsigned int) pointsCurLevel
{
    return pointsCurLevel;
}

- (void) setCargosCurLevel:(unsigned int)amount
{
    cargosCurLevel = amount;
    if(delegate)
    {
        [delegate updateCargo:cargosCurLevel];
    }
}

- (unsigned int) cargosCurLevel
{
    return cargosCurLevel;
}

- (unsigned int) currentHighscore
{
    return statsData.highscore;
}

#pragma mark - multiplier

- (unsigned int) highestMultiplier
{
    return [statsData highMultiplier];
}

- (unsigned int) sessionMultiplier
{
    return _accMultiplier + _curLevelMultiplier;
}

- (unsigned int) curLevelMultiplier
{
    return _curLevelMultiplier;
}

- (void) setCurLevelMultiplier:(unsigned int)curLevelMultiplier
{
    _curLevelMultiplier = curLevelMultiplier;
}

// this function refreshes the multiplier that have absolutely been completed
// (called at level completion and end of game)
- (void) refreshSessionMultiplier
{
    _accMultiplier += _curLevelMultiplier;
    _curLevelMultiplier = 0;
    _accCompletedMultiplier = _accMultiplier;
}

- (void) resetMultiplierForLevelRestart
{
    _curLevelMultiplier = 0;
    _accMultiplier = _accCompletedMultiplier;
}

- (void) commitHighestMultiplier
{
    unsigned int newMultiplier = [self sessionMultiplier];
    if([statsData highMultiplier] < newMultiplier)
    {
        statsData.highMultiplier = newMultiplier;
        [self saveStatsData];
    }
}

- (void) incrementScoreMultiplier
{
    _curLevelMultiplier++;
    
    // achievements
    [[AchievementsManager getInstance] updateMultiplier:[self sessionMultiplier]];
    [delegate didReceiveNewMultiplier:[self sessionMultiplier] hasIncreased:YES];
}

- (void) dropScoreMultiplier
{
    // reset both curlevel and acc multiplier variables
    _accMultiplier = 0;
    _curLevelMultiplier = 1;
    [delegate didReceiveNewMultiplier:[self sessionMultiplier] hasIncreased:NO];
}


#pragma mark - enemies accessors

// points gained from enemy is
//  (base-point + (maxHealth - curHealth)) * number-of-shots-outstanding
- (void) destroyedEnemyNamed:(NSString *)name andNumShots:(unsigned int)numShots
{
    unsigned int newPoints = [enemyReg getPointsForEnemyNamed:name];
    unsigned int multiplier = ([[PlayerInventory getInstance] curHealthSlots] - curHealth) + [self sessionMultiplier];
    if(multiplier == 0)
    {
        multiplier = 1;
    }
    unsigned int bonus = numShots;
    
    newPoints = (newPoints + bonus) * multiplier;
    newPoints += pointsCurLevel;

    self.pointsCurLevel = newPoints;
}

- (void) creditBonusForGroupNamed:(NSString*)groupName
{
    unsigned int newPoints = [enemyReg getPointsForEnemyNamed:groupName] * [self sessionMultiplier];
    newPoints += pointsCurLevel;
    self.pointsCurLevel = newPoints;
}

- (void) creditBulletHits:(unsigned int)num
{
    unsigned int newPoints = (num * [self sessionMultiplier]) + pointsCurLevel;
    self.pointsCurLevel = newPoints;
}

- (void) creditCollection:(unsigned int)num
{
    unsigned int newPoints = (num * [self sessionMultiplier]) + pointsCurLevel;
    self.pointsCurLevel = newPoints;
}

#pragma mark - cargo accessors

- (void) collectedLootNamed:(NSString *)name
{
    int valuesGained = [lootReg getValueForLootNamed:name];
    cargosCurLevel += valuesGained;
    cargosCollectCount += valuesGained;
    
    // update UI
    if(delegate)
    {
        [delegate updateCargo:cargosCurLevel];
    }
}

- (void) dropLootNamed:(NSString *)name 
{
    int value = [lootReg getValueForLootNamed:name];
    cargosCurLevel -= value;

    // update UI
    if(delegate)
    {
        [delegate updateCargo:cargosCurLevel];
    }
}

- (void) collectedCargo:(unsigned int)num
{
    cargosCurLevel += num;
    cargosCollectCount += num;

    // update UI
    if(delegate)
    {
        [delegate updateCargo:cargosCurLevel];
    }
}

- (void) droppedCargo:(unsigned int)num 
{
    if(num > cargosCurLevel)
    {
        cargosCurLevel = 0;
    }
    else
    {
        cargosCurLevel -= num;
    }
    
    // update UI
    if(delegate)
    {
        [delegate updateCargo:cargosCurLevel];
    }
}


#pragma mark - health accessors
- (void) updateHealth:(int)newHealth
{
    curHealth = newHealth;
    if(delegate)
    {
        [delegate updateHealthBar:newHealth];
    }
}

#pragma mark - power accessors
- (void) updateNumKillBullets:(unsigned int)newNum
{
    if(delegate)
    {
        [delegate updateNumKillBullets:newNum];
    }
}

#pragma mark - cash accessors
- (unsigned int) getTotalCash
{
    unsigned int result = [playerData pogCoins];
    return result;
}

// as a consolation prize, player gains one coin per cargo collected over the course of the game
- (void) collectCoinsFromGameOver
{
    unsigned int newAmount = cargosCollectCount + [playerData pogCoins];
    
    // commit the coins because we're at the end of the game
    [self commitCoins:newAmount];
}

#pragma mark - delivery screen fields
- (unsigned int) deliveryGetCargoNum
{
    return deliveryCargoNum;
}

- (unsigned int) deliveryGetCashEarned
{
    return deliveryCashEarned;
}

#pragma mark - progression queries
- (unsigned int) nextIncompleteLevelForEnv:(NSString *)envName
{
    unsigned int numLevels = [[LevelManager getInstance] getNumLevelsForEnv:envName];
    unsigned int index = 0;
    while(index < numLevels)
    {
        if(![statsData hasCompletedForEnv:envName level:index])
        {
            break;
        }
        ++index;
    }
    return index;
}

- (ScoreGrades) gradeForEnv:(NSString*)envName level:(unsigned int)levelIndex
{
    ScoreGrades result = SCOREGRADE_NONE;
    if([statsData hasCompletedForEnv:envName level:levelIndex])
    {
        unsigned int levelScore = [statsData getGradeScoreForEnv:envName level:levelIndex];
        result = [self gradeForScore:levelScore env:envName level:levelIndex];
    }    
    return result;
}

/*
- (NSString*) gradeStringForEnv:(NSString *)envName level:(unsigned int)levelIndex
{
    enum ScoreGrades scoreGrade = [self gradeForEnv:envName level:levelIndex];
    NSString* result = @"C-";
    switch(scoreGrade)
    {
        case SCOREGRADE_A:
            result = @"A";
            break;
            
        case SCOREGRADE_AMINUS:
            result = @"A-";
            break;
            
        case SCOREGRADE_B:
            result = @"B";
            break;
            
        case SCOREGRADE_BMINUS:
            result = @"B-";
            break;
            
        case SCOREGRADE_C:
            result = @"C";
            break;
            
        case SCOREGRADE_CMINUS:
            result = @"C-";
            break;
            
        default:
            // do nothing
            break;
    }
    return result;
}
*/
- (ScoreGrades) gradeForScore:(unsigned int)givenScore env:(NSString*)envName level:(unsigned int)levelIndex
{
    ScoreGrades result = SCOREGRADE_NONE;
    NSArray* levels = [[[LevelManager getInstance] envData] getLevelsArrayForEnvNamed:envName];
    EnvLevelData* cur = [levels objectAtIndex:levelIndex];
    if(givenScore >= [cur scoreA])
    {
        result = SCOREGRADE_A;
    }
    else if(givenScore >= (([cur scoreA] * 0.75f) + ([cur scoreB] * 0.25f)))
    {
        // 0.75A + 0.25B comes from (A - (0.25 * (A - B)))
        result = SCOREGRADE_AMINUS;
    }
    else if(givenScore >= [cur scoreB])
    {
        result = SCOREGRADE_B;
    }
    else if(givenScore >= (([cur scoreB] * 0.75f) + ([cur scoreC] * 0.25f)))
    {
        result = SCOREGRADE_BMINUS;
    }
    else if(givenScore >= [cur scoreC])
    {
        result = SCOREGRADE_C;
    }
    else
    {
        result = SCOREGRADE_CMINUS;
    }
    return result;
}

- (NSString*) gradeStringForScore:(unsigned int)givenScore env:(NSString*)envName level:(unsigned int)levelIndex
{
    enum ScoreGrades scoreGrade = [self gradeForScore:givenScore env:envName level:levelIndex];
    NSString* result = @"C-";
    switch(scoreGrade)
    {
        case SCOREGRADE_A:
            result = @"A";
            break;
            
        case SCOREGRADE_AMINUS:
            result = @"A-";
            break;
            
        case SCOREGRADE_B:
            result = @"B";
            break;
            
        case SCOREGRADE_BMINUS:
            result = @"B-";
            break;
            
        case SCOREGRADE_C:
            result = @"C";
            break;
            
        case SCOREGRADE_CMINUS:
            result = @"C-";
            break;
            
        default:
            // do nothing
            break;
    }
    return result;
}

#pragma mark - continues
- (void) incrContinueCount
{
    _sessionContinueCount++;
}

#pragma mark - stats queries
- (NSTimeInterval) getTotalFlightTime
{
    return [statsData flightTime];
}

- (unsigned int) getHighscore
{
    return [statsData highscore];
}

- (unsigned int) getCargosDelivered
{
    return [statsData cargosDelivered];
}

- (unsigned int) getHighscoreForEnv:(NSString*)envName level:(unsigned int)levelIndex
{
    unsigned int result = [statsData getHighscoreForEnv:envName level:levelIndex];
    return result;
}

// return the coins earned from in-game (excluding the coins that player bought from in-app)
- (unsigned int) getCoinsCollected
{
    unsigned int result = [statsData pogcoinsCollected];
    return result;
}

#pragma mark - one time flags
- (BOOL) hasCompletedTutorial
{
    BOOL result = NO;
    if(STATS_FLAG_COMPLETEDTUTORIAL == ([statsData flags] & STATS_FLAG_COMPLETEDTUTORIAL))
    {
        result = YES;
    }
    
    return result;
}

- (void) setCompletedTutorial
{
    statsData.flags = (statsData.flags | STATS_FLAG_COMPLETEDTUTORIAL);
    [[StatsManager getInstance] saveStatsData];
}

- (void) clearCompletedTutorial
{
    statsData.flags = statsData.flags & ~(STATS_FLAG_COMPLETEDTUTORIAL);
    [[StatsManager getInstance] saveStatsData];
}

- (BOOL) hasCompletedTutorialTourney
{
    BOOL result = NO;
    if(STATS_FLAG_COMPLETEDTUTORIALTOURNEY == ([statsData flags] & STATS_FLAG_COMPLETEDTUTORIALTOURNEY))
    {
        result = YES;
    }
    return result;    
}

- (void) setCompletedTutorialTourney
{
    statsData.flags = (statsData.flags | STATS_FLAG_COMPLETEDTUTORIALTOURNEY);
    [[StatsManager getInstance] saveStatsData];
}

- (void) clearCompletedTutorialTourney
{
    statsData.flags = statsData.flags & ~(STATS_FLAG_COMPLETEDTUTORIALTOURNEY);
    [[StatsManager getInstance] saveStatsData];
}

#pragma mark -
#pragma mark Singleton
static StatsManager* singleton = nil;
+ (StatsManager*) getInstance
{
	@synchronized(self)
	{
		if (!singleton)
		{
			singleton = [[[StatsManager alloc] init] retain];
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
