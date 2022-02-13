//
//  Credits.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/17/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "Credits.h"
#import "AppNavController.h"
#import <QuartzCore/QuartzCore.h>

@interface Credits (PrivateMethods)
- (void) setupContentViewBorder;
- (void) setupVersion;
@end

@implementation Credits

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
    [_contentView release];
    [_version release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

#pragma mark - layout
- (void) setupContentViewBorder
{
    [[_contentView layer] setCornerRadius:4.0f];
    [[_contentView layer] setMasksToBounds:YES];
    [[_contentView layer] setBorderWidth:2.0f];
    [[_contentView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
}

- (void) setupVersion
{
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    [_version setText:[NSString stringWithFormat:@"v %@", versionString]];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupContentViewBorder];
    [self setupVersion];
}

- (void)viewDidUnload
{
    [_contentView release];
    _contentView = nil;
    [_version release];
    _version = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - button actions

- (IBAction)buttonClosePressed:(id)sender 
{
    [[AppNavController getInstance] popToRightViewControllerAnimated:YES];    
}


#pragma mark - AppEventDelegate
- (void) appWillResignActive
{
	// do nothing
}

- (void) appDidBecomeActive
{
	// do nothing
}

- (void) appDidEnterBackground
{
    // do nothing
}

- (void) appWillEnterForeground
{
    // do nothing
}

- (void) abortToRootViewControllerNow
{
    [[AppNavController getInstance] popToRootViewControllerAnimated:NO];
}

@end
