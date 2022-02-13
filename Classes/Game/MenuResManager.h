//
//  MenuResManager.h
//
//

#import <Foundation/Foundation.h>

@class IngameMenu;
@protocol MenuResDelegate;


@interface MenuResManager : NSObject 
{
	IngameMenu* igMenu;
    UIButton* buttonPause;
    
    UIImageView* _frontendBackground;
    
    NSMutableDictionary* _frontendImages;
    NSMutableDictionary* _ingameImages;
    NSMutableSet* _unloadDelegates;
    
    UIAlertView* _alertView;
}
@property (nonatomic,retain) UIButton* buttonPause;
@property (nonatomic,retain) UIImageView* frontendBackground;
@property (nonatomic,retain) NSMutableDictionary* frontendImages;
@property (nonatomic,retain) NSMutableDictionary* ingameImages;
@property (nonatomic,retain) NSMutableSet* unloadDelegates;
@property (nonatomic,retain) UIAlertView* alertView;

- (void) initBackgroundImageWithFrame:(CGRect)givenFrame;
- (void) loadFrontendBackgroundImage;
- (void) dismissAlertView;

// accessors
- (void) addDelegate:(NSObject<MenuResDelegate>*)newDelegate;
- (void) removeDelegate:(NSObject<MenuResDelegate>*)toRemove;
- (void) unloadFrontendImages;
- (void) unloadIngameImages;
- (UIImage*) loadImage:(NSString*)name isIngame:(BOOL)ingame;
- (UIImage*) loadImage:(NSString *)name withColor:(UIColor*)color withKey:(NSString*)key isIngame:(BOOL)ingame;

// singleton
+(MenuResManager*) getInstance;
+(void) destroyInstance;

@end

@protocol MenuResDelegate<NSObject>
- (void) didUnloadFrontendImages;
- (void) didUnloadIngameImages;
@end
