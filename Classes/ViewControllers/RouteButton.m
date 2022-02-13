//
//  RouteButton.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/15/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "RouteButton.h"
#import "MenuResManager.h"

@interface RouteButton (PrivateMethods)
- (void) updateSelectableAlpha;
- (void) updateRotation;
- (void) updateScoreGradeLabel;
@end

@implementation RouteButton
@synthesize envName;
@synthesize levelIndex;
@synthesize serviceName;
@synthesize routeName;
@synthesize selectableState;
@synthesize rotation;
@synthesize scoreGrade;
@synthesize routeSign;
@synthesize iconLocked;
@synthesize routeUnlockedImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        self.envName = nil;
        levelIndex = 0;
        self.routeName = @"";
        self.serviceName = @"Route";
        self.selectableState = ROUTEBUTTON_STATE_SELECTABLE;
        underConstruction = NO;
        self.rotation = 0.0f;
        scoreGrade = SCOREGRADE_NONE;
        routeNameFontSize = 25.0f;
        serviceLabelFontSize = 16.0f;
        businessPendingFontSize = 35.0f;
    }
    return self;
}

- (void) dealloc
{    
    self.serviceName = nil;
    self.routeName = nil;
    self.envName = nil;
    if(routeSign)
    {
        routeSign.image = nil;
    }
    [routeSign release];
    iconLocked.image = nil;
    [iconLocked release];
    [routeUnlockedImage release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) setUnderConstruction:(BOOL)constructionYesNo
{
    underConstruction = constructionYesNo;
    if(constructionYesNo)
    {
        constructionSign.hidden = NO;
    }
}

- (BOOL) underConstruction
{
    return underConstruction;
}

#pragma mark - private methods

- (void) updateSelectableAlpha
{
    if(selectableState == ROUTEBUTTON_STATE_SELECTABLE)
    {
        routeSignView.opaque = NO;
        routeSignView.alpha = 1.0f;
        routeNameLabel.hidden = NO;
        businessPendingSign.hidden = YES;
        iconLocked.hidden = YES;
        routeUnlockedImage.hidden = NO;
        if(scoreGrade != SCOREGRADE_NONE)
        {
            scoreGradeLabel.hidden = NO;
        }
        else
        {
            scoreGradeLabel.hidden = YES;
        }
    }
    else if(selectableState == ROUTEBUTTON_STATE_NONE)
    {
        routeSignView.opaque = NO;
        routeSignView.alpha = 0.35f;
        routeNameLabel.hidden = YES;
        businessPendingSign.hidden = NO;
        iconLocked.hidden = NO;
        routeUnlockedImage.hidden = YES;
        scoreGradeLabel.hidden = YES;
    }
    else if(selectableState == ROUTEBUTTON_STATE_FORSALE)
    {
        // TODO: remove, not used anymore
        routeSignView.opaque = NO;
        routeSignView.alpha = 0.35f;
        routeNameLabel.hidden = NO;
        businessPendingSign.hidden = NO;
        scoreGradeLabel.hidden = YES;
    }
    
    // TODO: remove, not used anymore
    constructionSign.hidden = YES;
    if(underConstruction)
    {
        constructionSign.hidden = NO;
        routeNameLabel.hidden = YES;
        businessPendingSign.hidden = YES;
        scoreGradeLabel.hidden = YES;
    }
}

- (void) updateScoreGradeLabel
{
    switch(scoreGrade)
    {
        case SCOREGRADE_A:
            [scoreGradeLabel setText:@"A"];
            break;

        case SCOREGRADE_AMINUS:
            [scoreGradeLabel setText:@"A-"];
            break;
            
        case SCOREGRADE_B:
            [scoreGradeLabel setText:@"B"];
            break;
            
        case SCOREGRADE_BMINUS:
            [scoreGradeLabel setText:@"B-"];
            break;
            
        case SCOREGRADE_C:
            [scoreGradeLabel setText:@"C"];
            break;
            
        case SCOREGRADE_CMINUS:
            [scoreGradeLabel setText:@"C-"];
            break;
            
        default:
            // do nothing
            break;
    }
}

- (void) updateLabels
{
    [routeNameLabel setText:routeName];
    [self updateSelectableAlpha];
    [self updateRotation];
    [self updateScoreGradeLabel];
}

- (void) updateRotation
{
    CGAffineTransform rt = CGAffineTransformIdentity;
   routeSignView.transform = CGAffineTransformRotate(rt, rotation);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // save off font sizes from xib file for use in scaling fonts in updateLabels
    routeNameFontSize = routeNameLabel.font.pointSize;
    businessPendingFontSize = businessPendingSign.font.pointSize * 2.0f;
    
    // setup fonts
    UIFont* peter1 = [UIFont fontWithName:@"Mister N" size:businessPendingFontSize];
    businessPendingSign.font = peter1;
    
    [self updateLabels];
}

- (void)viewDidUnload
{
    if(routeSign)
    {
        routeSign.image = nil;
    }
    [self setRouteSign:nil];
    iconLocked.image = nil;
    [iconLocked release];
    iconLocked = nil;
    routeUnlockedImage.image = nil;
    [routeUnlockedImage release];
    routeUnlockedImage = nil;
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    iconLocked.image = [[MenuResManager getInstance] loadImage:@"iconLocked" isIngame:NO];
    routeUnlockedImage.image = [[MenuResManager getInstance] loadImage:@"ButtonRouteUnlockBG.png" isIngame:NO];
    [self updateLabels];
}

- (void) viewDidDisappear:(BOOL)animated
{
    iconLocked.image = nil;
    routeUnlockedImage.image = nil;
    self.routeSign.image = nil;
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
