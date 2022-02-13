//
//  RouteSelectPage.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/25/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuResManager.h"

@protocol RouteSelectPageDelegate <NSObject>
- (void) selectRouteNum:(unsigned int)num;
@end

@interface RouteSelectPage : UIViewController
{
    IBOutlet UIView* route1Placement;
    IBOutlet UIView* route2Placement;
    IBOutlet UIView* route3Placement;
    IBOutlet UIView* route4Placement;
    IBOutlet UIView* route5Placement;
    IBOutlet UIView *route6Placement;
    IBOutlet UIView *route7Placement;
    IBOutlet UIView *route8Placement;
    IBOutlet UIView *route9Placement;
    IBOutlet UIView *route10Placement;

    // container views and buttons (for setting background color purposes)
    IBOutlet UIButton* route1Button;
    IBOutlet UIButton* route2Button;
    IBOutlet UIButton* route3Button;
    IBOutlet UIButton* route4Button;
    IBOutlet UIButton* route5Button;
    IBOutlet UIButton *route6Button;
    IBOutlet UIButton *route7Button;
    IBOutlet UIButton *route8Button;
    IBOutlet UIButton *route9Button;
    IBOutlet UIButton *route10Button;
    IBOutlet UIView *pageView;
    
    unsigned int firstRouteIndex;
    NSArray* routeButtons;
    
    NSObject<RouteSelectPageDelegate>* delegate;
}
@property (nonatomic,retain) NSArray* routeButtons;
@property (nonatomic,retain) NSObject<RouteSelectPageDelegate>* delegate;

- (id) initWithRouteInfosArray:(NSMutableArray*)routeInfos fromIndex:(unsigned int)startIndex;
- (void) updateWithRoutesInfoArray:(NSMutableArray*)routeInfos;
- (void) unloadButtonImages;
- (IBAction)route1Pressed:(id)sender;
- (IBAction)route2Pressed:(id)sender;
- (IBAction)route3Pressed:(id)sender;
- (IBAction)route4Pressed:(id)sender;
- (IBAction)route5Pressed:(id)sender;
- (IBAction)route6Pressed:(id)sender;
- (IBAction)route7Pressed:(id)sender;
- (IBAction)route8Pressed:(id)sender;
- (IBAction)route9Pressed:(id)sender;
- (IBAction)route10Pressed:(id)sender;

@end
