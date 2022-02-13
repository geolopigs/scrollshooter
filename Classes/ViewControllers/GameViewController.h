//
//  GameViewController.h
//  CurryFlyer
//
//

#import <UIKit/UIKit.h>
#import "AppEventDelegate.h"
#import "PauseMenu.h"
#import "ContinueScreen.h"
#import "GameOverScreen.h"
#import "TutorialControllerDelegate.h"

typedef enum _GameStates 
{
    GAME_STATE_INGAME = 0,
    GAME_STATE_TIMEBASED_PRESTART,
    GAME_STATE_TIMEBASED_NEXTPEER_DASHBOARD,
    GAME_STATE_TIMEBASED_NEXTPEER_POSTGAME,
    GAME_STATE_TIMEBASED_PRESTART_MENU,
    GAME_STATE_TUTORIAL,
    GAME_STATE_PLAYERDEAD,
    GAME_STATE_LEVELCOMPLETED,
    GAME_STATE_GAMEOVERSEQUENCE,
    GAME_STATE_EXITGAME,
    GAME_STATE_EXITTIMEBASED,
    
    GAME_STATE_NUM
} GameStates;

enum PostGameOverFlags
{
    POSTGAMEOVER_FLAG_NONE = 0x00,
    POSTGAMEOVER_FLAG_STORE = 0x01,
    POSTGAMEOVER_FLAG_STATS = 0x02,
    POSTGAMEOVER_FLAG_GOALS = 0x04
};

@class GameGLView;
@class PauseMenu;
@class LevelCompletedScreen;
@class ContinueScreen;
@class ScoreHud;
@class GameOverScreen;
@class PanController;
@class TutorialController;
@interface GameViewController : UIViewController<AppEventDelegate,PauseMenuDelegate,
                                                 ContinueScreenDelegate,
                                                 GameOverScreenDelegate,
                                                 TutorialControllerDelegate>
{
	GameGLView* gameView;
	UIButton* buttonPause;
    PauseMenu* pauseMenu;
    LevelCompletedScreen* levelCompletedScreen;
    BOOL doneWithCompletedScreen;
    float _levelStatsTimer;
    BOOL _statsCompletedCurLevel;
    
    // sub views
	ScoreHud* scoreHud;
    
    GameOverScreen* gameOverScreen;
    BOOL    _shouldExitFromGameOver;
    unsigned int _postGameOverFlags;
    float   gameOverTimer;              // timer for showing the screen
    float   gameOverStopSimTimer;       // time till we should stop the sim after gameOver screen is up

    ContinueScreen* continueScreen;
    BOOL    willContinue;
    
    TutorialController* _tutorial;
    
	NSTimer*	gameLoopTimer;
	NSTimeInterval prevTick;
    
    BOOL        _shouldUpdateSim;
    BOOL        shouldUpdateDraw;
    
    GameStates gameState;
    
    // controls
    PanController* _flightController;
    
    // for pausing the timer
	NSDate* pauseStart;
	NSDate* previousFiringDate;
    
    // time-based mode
    BOOL _startTimebasedGame;
    BOOL _isMultiplayerTourney;
    BOOL _npDashboardDidExit;
    BOOL _shouldRelaunchNPDashboard;
}
@property (nonatomic,retain) PauseMenu* pauseMenu;
@property (nonatomic,retain) LevelCompletedScreen* levelCompletedScreen;
@property (nonatomic,retain) ContinueScreen* continueScreen;
@property (nonatomic,retain) TutorialController* tutorial;
@property (nonatomic,retain) ScoreHud* scoreHud;
@property (nonatomic,retain) GameOverScreen* gameOverScreen;
@property (nonatomic,assign) BOOL shouldUpdateSim;
@property (nonatomic,assign) GameStates gameState;
@property (nonatomic,retain) PanController* flightController;

- (BOOL) isLevelCompletedScreenVisible;
- (BOOL) isGameOverScreenVisible;
- (void) buttonPausePressed;

@end
