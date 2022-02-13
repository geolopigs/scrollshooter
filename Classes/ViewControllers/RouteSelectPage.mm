//
//  RouteSelectPage.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/25/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "RouteSelectPage.h"
#import "RouteButton.h"
#import "RouteInfo.h"
#import "LevelManager.h"
#import "SoundManager.h"
#import "StatsManager.h"
#import "Texture.h"
#import "MenuResManager.h"
#import "CurryAppDelegate.h"

static const unsigned int NUMROUTEBUTTONS_IN_PAGE = 10;
static float const PAGE_ROTATIONS[10] =
{
    -M_PI * 0.1f,
    M_PI * 0.05f,
    M_PI * 0.1f,
    M_PI * 0.04f,
    -M_PI * 0.07f,
    -M_PI * 0.1f,
    M_PI * 0.05f,
    M_PI * 0.1f,
    M_PI * 0.04f,
    -M_PI * 0.07f
};


@interface RouteSelectPage (PrivateMethods)
- (void) clearColorAllBackgrounds;
- (void) updateRouteInfoToUI;
- (void) selectRouteNum:(unsigned int)num;
- (void) arrangeRouteButtonsWithSpacing:(CGPoint)spacing 
                          topLeftOrigin:(CGPoint)topLeft 
                              numPerRow:(unsigned int)numPerRow 
                     lastRowIndexOffset:(unsigned int)lastRowOffset;
@end

@implementation RouteSelectPage
@synthesize routeButtons;
@synthesize delegate;


- (id) initWithRouteInfosArray:(NSMutableArray*)routeInfos fromIndex:(unsigned int)startIndex
{
    self = [super initWithNibName:@"RouteSelectPage" bundle:nil];
    if (self) 
    {
        firstRouteIndex = startIndex;
        unsigned int index = startIndex;
        unsigned int count = 0;

        // create 5 route buttons
        NSMutableArray* tempArray = [NSMutableArray arrayWithCapacity:NUMROUTEBUTTONS_IN_PAGE];
        while((index - startIndex) < NUMROUTEBUTTONS_IN_PAGE)
        {
            RouteButton* button = nil;
            if(index < [routeInfos count])
            {
                RouteInfo* curInfo = [routeInfos objectAtIndex:index];
                switch([curInfo routeType])
                {
                    case ROUTETYPE_SEA:
                        button = [[RouteButton alloc] initWithNibName:@"RouteButtonSea" bundle:nil];
                        break;
                        
                    case ROUTETYPE_AIR:
                        button = [[RouteButton alloc] initWithNibName:@"RouteButtonAir" bundle:nil];
                        break;
                        
                    case ROUTETYPE_LAND:
                    default:
                        button = [[RouteButton alloc] initWithNibName:@"RouteButtonLand" bundle:nil];
                        break;                        
                }
                [button setRouteName:[curInfo routeName]];
                [button setServiceName:[curInfo serviceName]];
                [button setLevelIndex:[curInfo levelIndex]];
                button.envName = [curInfo envName];
                [button setScoreGrade:[[StatsManager getInstance] gradeForEnv:[button envName] level:[curInfo levelIndex]]];
                if([curInfo selectable])
                {
                    [button setSelectableState:ROUTEBUTTON_STATE_SELECTABLE];
                }
                else
                {
                    [button setSelectableState:ROUTEBUTTON_STATE_NONE];
                }
            }
            else
            {
                // under construction
                button = [[RouteButton alloc] initWithNibName:@"RouteButtonLand" bundle:nil]; 
                [button setSelectableState:ROUTEBUTTON_STATE_NONE];
                [button setUnderConstruction:YES];
            }
            //[button setRotation:PAGE_ROTATIONS[count]];
            [tempArray addObject:button];
            [button release];
            
            ++count;
            if(count >= NUMROUTEBUTTONS_IN_PAGE)
            {
                count = 0;
            }
            ++index;
        }
        self.routeButtons = [NSArray arrayWithArray:tempArray];
        [tempArray removeAllObjects];
        self.delegate = nil;
    }
    return self;
}

- (void) dealloc
{
    self.delegate = nil;
    for(RouteButton* cur in routeButtons)
    {
        [cur.view removeFromSuperview];
    }
    self.routeButtons = nil;
    [route1Placement release];
    [route2Placement release];
    [route3Placement release];
    [route4Placement release];
    [route5Placement release];
    [route6Placement release];
    [route7Placement release];
    [route8Placement release];
    [route9Placement release];
    [route10Placement release];
    [route1Button release];
    [route2Button release];
    [route3Button release];
    [route4Button release];
    [route5Button release];
    [route6Button release];
    [route7Button release];
    [route8Button release];
    [route9Button release];
    [route10Button release];
    [pageView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) updateWithRoutesInfoArray:(NSMutableArray *)routeInfos
{
    unsigned int index = firstRouteIndex;
    for(RouteButton* cur in routeButtons)
    {
        if(index < [routeInfos count])
        {
            RouteInfo* curInfo = [routeInfos objectAtIndex:index];
            [cur setRouteName:[curInfo routeName]];
            [cur setServiceName:[curInfo serviceName]];
            if([curInfo selectable])
            {
                [cur setSelectableState:ROUTEBUTTON_STATE_SELECTABLE];
            }
            else
            {
                [cur setSelectableState:ROUTEBUTTON_STATE_NONE];
            }
            
            // load images within button
            switch([curInfo routeType])
            {
                case ROUTETYPE_SEA:
                    cur.routeSign.image = [[MenuResManager getInstance] loadImage:@"RouteSign1" isIngame:NO];
                    break;
                    
                case ROUTETYPE_AIR:
                    cur.routeSign.image = [[MenuResManager getInstance] loadImage:@"RouteSign3" isIngame:NO];
                    break;
                    
                case ROUTETYPE_LAND:
                default:
                    cur.routeSign.image = [[MenuResManager getInstance] loadImage:@"RouteSign2" isIngame:NO];
                    break;                        
            }

        }
        else
        {
            [cur setSelectableState:ROUTEBUTTON_STATE_NONE];
        }
        ++index;
    }
}

- (void) unloadButtonImages
{
    for(RouteButton* cur in routeButtons)
    {
        cur.routeSign.image = nil;
        cur.iconLocked.image = nil;
        cur.routeUnlockedImage.image = nil;
    }
}

#pragma mark - private methods

- (void) clearColorAllBackgrounds
{
    route1Placement.backgroundColor = [UIColor clearColor];
    route2Placement.backgroundColor = [UIColor clearColor];
    route3Placement.backgroundColor = [UIColor clearColor];
    route4Placement.backgroundColor = [UIColor clearColor];
    route5Placement.backgroundColor = [UIColor clearColor];
    route6Placement.backgroundColor = [UIColor clearColor];
    route7Placement.backgroundColor = [UIColor clearColor];
    route8Placement.backgroundColor = [UIColor clearColor];
    route9Placement.backgroundColor = [UIColor clearColor];
    route10Placement.backgroundColor = [UIColor clearColor];
    
    route1Button.backgroundColor = [UIColor clearColor];
    route2Button.backgroundColor = [UIColor clearColor];
    route3Button.backgroundColor = [UIColor clearColor];
    route4Button.backgroundColor = [UIColor clearColor];
    route5Button.backgroundColor = [UIColor clearColor];
    route6Button.backgroundColor = [UIColor clearColor];
    route7Button.backgroundColor = [UIColor clearColor];
    route8Button.backgroundColor = [UIColor clearColor];
    route9Button.backgroundColor = [UIColor clearColor];
    route10Button.backgroundColor = [UIColor clearColor];
}


#pragma mark - View lifecycle

- (void) arrangeRouteButtonsWithSpacing:(CGPoint)spacing 
                          topLeftOrigin:(CGPoint)topLeft 
                              numPerRow:(unsigned int)numPerRow 
                     lastRowIndexOffset:(unsigned int)lastRowOffset
{
    NSArray* routePlacements = [NSArray arrayWithObjects:route1Placement, 
                                route2Placement,
                                route3Placement,
                                route4Placement,
                                route5Placement,
                                route6Placement,
                                route7Placement,
                                route8Placement,
                                route9Placement,
                                route10Placement,
                                nil];
    unsigned int index = 0;
    while(index < NUMROUTEBUTTONS_IN_PAGE)
    {
        UIView* curPlacement = [routePlacements objectAtIndex:index];
        CGRect curFrame = [curPlacement frame];
        float spacingX = spacing.x + curFrame.size.width;
        float spacingY = spacing.y + curFrame.size.height;
        unsigned int curCol = index % numPerRow;
        unsigned int curRow = index / numPerRow;
        if(((NUMROUTEBUTTONS_IN_PAGE-1)/numPerRow) > curRow)
        {
            CGPoint curPos = CGPointMake(topLeft.x + (curCol * spacingX),
                                         topLeft.y + (curRow * spacingY));
            curFrame.origin = curPos;
            curPlacement.frame = curFrame;
        }
        else
        {
            // last row
            curCol += lastRowOffset;
            CGPoint curPos = CGPointMake(topLeft.x + (curCol * spacingX),
                                         topLeft.y + (curRow * spacingY));
            curFrame.origin = curPos;
            curPlacement.frame = curFrame;            
        }
        
        ++index;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self clearColorAllBackgrounds];
    
    // store placements in an array for easier lookup
    NSArray* routePlacements = [NSArray arrayWithObjects:route1Placement, 
                            route2Placement,
                            route3Placement,
                            route4Placement,
                            route5Placement,
                            route6Placement,
                            route7Placement,
                            route8Placement,
                            route9Placement,
                            route10Placement,
                            nil];
    NSArray* routeButtonTriggers = [NSArray arrayWithObjects:route1Button, 
                            route2Button,
                            route3Button,
                            route4Button,
                            route5Button,
                            route6Button,
                            route7Button,
                            route8Button,
                            route9Button,
                            route10Button,
                            nil];
    
    // attach route buttons to their respective placement
    unsigned int index = 0;
    while(index < NUMROUTEBUTTONS_IN_PAGE)
    {
        UIView* curPlacement = [routePlacements objectAtIndex:index];
        RouteButton* curButton = [routeButtons objectAtIndex:index];
        curButton.rotation = PAGE_ROTATIONS[index];
        CGRect buttonFrame = curPlacement.frame;
        buttonFrame.origin.x = 0.0f;
        buttonFrame.origin.y = 0.0f;
        curButton.view.frame = buttonFrame;
        [curPlacement insertSubview:[curButton view] belowSubview:[routeButtonTriggers objectAtIndex:index]];
        
        ++index;
    }

    // set origins of buttons
    // use placement of first button in xib for margins
    CGPoint topLeftOrigin = CGPointMake(10.0f, 10.0f);
    if(0 < [routePlacements count])
    {
        UIView* first = [routePlacements objectAtIndex:0];
        topLeftOrigin = first.frame.origin;
    }

    [self arrangeRouteButtonsWithSpacing:CGPointMake(22.0f,18.0f)
                               topLeftOrigin:topLeftOrigin
                                   numPerRow:3
                          lastRowIndexOffset:1];
}

- (void)viewDidUnload
{
    [route1Placement release];
    route1Placement = nil;
    [route2Placement release];
    route2Placement = nil;
    [route3Placement release];
    route3Placement = nil;
    [route4Placement release];
    route4Placement = nil;
    [route5Placement release];
    route5Placement = nil;
    [route6Placement release];
    route6Placement = nil;
    [route7Placement release];
    route7Placement = nil;
    [route8Placement release];
    route8Placement = nil;
    [route9Placement release];
    route9Placement = nil;
    [route10Placement release];
    route10Placement = nil;

    [route1Button release];
    route1Button = nil;
    [route2Button release];
    route2Button = nil;
    [route3Button release];
    route3Button = nil;
    [route4Button release];
    route4Button = nil;
    [route5Button release];
    route5Button = nil;
    [route6Button release];
    route6Button = nil;
    [route7Button release];
    route7Button = nil;
    [route8Button release];
    route8Button = nil;
    [route9Button release];
    route9Button = nil;
    [route10Button release];
    route10Button = nil;
    [pageView release];
    pageView = nil;
    [super viewDidUnload];

    unsigned int index = 0;
    while(index < NUMROUTEBUTTONS_IN_PAGE)
    {
        RouteButton* curButton = [routeButtons objectAtIndex:index];
        [curButton.view removeFromSuperview];
        ++index;
    }
    self.routeButtons = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    for(RouteButton* cur in routeButtons)
    {
        [cur viewWillAppear:animated];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    for(RouteButton* cur in routeButtons)
    {
        [cur viewDidDisappear:animated];
    }
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - navigation


- (IBAction)route1Pressed:(id)sender
{
    unsigned int index = 0;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}

- (IBAction)route2Pressed:(id)sender
{    
    unsigned int index = 1;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}

- (IBAction)route3Pressed:(id)sender
{    
    unsigned int index = 2;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}

- (IBAction)route4Pressed:(id)sender
{
    unsigned int index = 3;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}
- (IBAction)route5Pressed:(id)sender
{
    unsigned int index = 4;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}

- (IBAction)route6Pressed:(id)sender
{
    unsigned int index = 5;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}

- (IBAction)route7Pressed:(id)sender
{
    unsigned int index = 6;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}

- (IBAction)route8Pressed:(id)sender
{
    unsigned int index = 7;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}

- (IBAction)route9Pressed:(id)sender
{
    unsigned int index = 8;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}

- (IBAction)route10Pressed:(id)sender
{
    unsigned int index = 9;
    if([[routeButtons objectAtIndex:index] selectableState] == ROUTEBUTTON_STATE_SELECTABLE)
    {
        [delegate selectRouteNum:index + firstRouteIndex];
    }
}


@end
