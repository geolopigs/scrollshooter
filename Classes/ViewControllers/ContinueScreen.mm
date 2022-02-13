//
//  ContinueScreen.mm
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/2/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import "ContinueScreen.h"
#import "SoundManager.h"
#import "MenuResManager.h"
#import "CurryAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation ContinueScreen
@synthesize delegate;

- (id) initWithContinuesRemaining:(unsigned int)remaining
{
    self = [super initWithNibName:@"ContinueScreen" bundle:nil];
    if (self) 
    {
        self.delegate = nil;
        continuesRemaining = remaining;
    }
    return self;
}

- (void) dealloc
{
    self.delegate = nil;
    [continuesLabel release];
    [fadeOutLabel release];
    [titleLabel release];
    [backScrim release];
    [border release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction) continueGamePressed:(id)sender
{
    [[SoundManager getInstance] playImmediateClip:@"ButtonPressed"];        
    [continuesLabel setText:[NSString stringWithFormat:@"%d",continuesRemaining-1]];
    fadeOutLabel.hidden = NO;
    fadeOutLabel.alpha = 1.0f;
    CGAffineTransform startTransform = fadeOutLabel.transform;
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{ 
                         fadeOutLabel.alpha = 0.0f;
                         fadeOutLabel.transform = CGAffineTransformTranslate(startTransform, 0.0f, -40.0f);
                     }
                     completion:^(BOOL finished){
                         fadeOutLabel.transform = startTransform;
                         fadeOutLabel.hidden = YES;
                         [delegate continueGame:self];
                     }];
}

- (IBAction) endGamePressed:(id)sender
{
    [[SoundManager getInstance] playImmediateClip:@"ButtonPressed"];        
    [delegate endGame:self];
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
    
    // font
    titleLabel.font = [UIFont fontWithName:@"effigy" size:30.0f];
    UIFont* peter1font50 = [UIFont fontWithName:@"Mister N" size:50.0f];
    continuesLabel.font = peter1font50;
    fadeOutLabel.font = peter1font50;
    
    // update label with continues remaining
    [continuesLabel setText:[NSString stringWithFormat:@"%d",continuesRemaining]];
}

- (void)viewDidUnload
{
    self.delegate = nil;
    [continuesLabel release];
    continuesLabel = nil;
    [fadeOutLabel release];
    fadeOutLabel = nil;
    [titleLabel release];
    titleLabel = nil;
    [backScrim release];
    backScrim = nil;
    [border release];
    border = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
