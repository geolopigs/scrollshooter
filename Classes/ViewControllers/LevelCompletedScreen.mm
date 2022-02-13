//
//  LevelCompletedScreen.mm
//  PeterPog
//
//  This screen shows up after all the scores and cash have been tallied with the StatsManager
//  It only displays info and does not commit data changes to the StatsManager
//  
//  Created by Shu Chiun Cheah on 8/19/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "LevelCompletedScreen.h"
#import "StatsManager.h"
#import "StoreManager.h"
#import "SoundManager.h"
#import <QuartzCore/QuartzCore.h>


@interface LevelCompletedScreen (PrivateMethods)
- (void) showGradeLabel;
@end

@implementation LevelCompletedScreen

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
    }
    return self;
}

- (void) dealloc
{
    [cargoNum release];
    [gradeLabel release];
    [gradeLabelFade release];
    [currentScore release];
    [backScrim release];
    [border release];
    [_pogcoinsLabel release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - private methods

- (void) showGradeLabel
{
    gradeLabel.hidden = NO;
    gradeLabel.alpha = 0.0f;
    gradeLabel.transform = CGAffineTransformScale(CGAffineTransformIdentity, 3.0f, 3.0f);
    [UIView animateWithDuration:0.5f
                          delay:0.4f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{ 
                         gradeLabel.alpha = 1.0f;
                         gradeLabel.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished){
                         [[SoundManager getInstance] playClip:@"PigSnore"];
                         gradeLabelFade.hidden = NO;
                         gradeLabelFade.alpha = 0.5f;
                         gradeLabelFade.transform = CGAffineTransformIdentity;
                         [UIView animateWithDuration:0.5f
                                               delay:0.0f
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{ 
                                              gradeLabelFade.alpha = 0.0f;
                                              gradeLabelFade.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.3f, 1.3f);
                                          }
                                          completion:^(BOOL finished) {
                                              gradeLabelFade.hidden = YES;
                                          }];
                     }];     
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // position myself in the center of the screen
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGSize curSize = self.view.frame.size;
    CGRect myFrame = CGRectMake((screenSize.width * 0.5f) - (curSize.width * 0.5f),
                                    (screenSize.height * 0.5f) - (curSize.height * 0.5f),
                                   curSize.width, curSize.height);
    self.view.frame = myFrame;
    
    // init round corners
    [[backScrim layer] setCornerRadius:3.0f];
    [[backScrim layer] setMasksToBounds:YES];
    [[backScrim layer] setBorderWidth:2.0f];
    [[backScrim layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[border layer] setCornerRadius:8.0f];
    [[border layer] setMasksToBounds:YES];
    [[border layer] setBorderWidth:5.0f];
    [[border layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    
    // populate stats in screen
    StatsManager* statsMgr = [StatsManager getInstance];
    [cargoNum setText:[NSString stringWithFormat:@"%d", [statsMgr deliveryGetCargoNum]]];
    unsigned int pogcoinsEarnedCurLevel = [[StatsManager getInstance] deliveryGetCashEarned];
    [_pogcoinsLabel setText:[StoreManager pogcoinsStringForAmount:pogcoinsEarnedCurLevel]];
    
    unsigned int lastGradeScore = [statsMgr gradeScoreLevelComplete];
    [currentScore setText:[NSString stringWithFormat:@"%d", lastGradeScore]];
    gradeLabel.hidden = YES;
    gradeLabelFade.hidden = YES;
    [gradeLabel setText:[statsMgr gradeStringForScore:lastGradeScore env:[statsMgr curEnvName] level:[statsMgr curLevel]]];
    [gradeLabelFade setText:[statsMgr gradeStringForScore:lastGradeScore env:[statsMgr curEnvName] level:[statsMgr curLevel]]];
    
    // fade myself in
    self.view.alpha = 0.0f;
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{ 
                         self.view.alpha = 1.0f;
                     }
                     completion:NULL];
    [self showGradeLabel];
}

- (void)viewDidUnload
{
    [cargoNum release];
    cargoNum = nil;
    [gradeLabel release];
    gradeLabel = nil;
    [gradeLabelFade release];
    gradeLabelFade = nil;
    [currentScore release];
    currentScore = nil;
    [backScrim release];
    backScrim = nil;
    [border release];
    border = nil;
    [_pogcoinsLabel release];
    _pogcoinsLabel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
