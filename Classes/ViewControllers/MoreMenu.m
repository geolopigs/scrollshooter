//
//  MoreMenu.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "MoreMenu.h"
#import "AppNavController.h"
#import "StatsManager.h"
#import "SoundManager.h"
#import "PogUIUtility.h"
#import "MovieWebView.h"
#import "PogUITextLabel.h"
#import <QuartzCore/QuartzCore.h>

static NSString* const TITLE_KEY = @"title";
static NSString* const ICON_KEY = @"icon";
static NSString* const APPSTOREID_KEY = @"appStoreId";

@interface MoreMenu ()
{
    NSArray* _moreGames;
}
- (void) initMoreGames;
@end

@implementation MoreMenu

- (void) initMoreGames
{
    NSDictionary* traderpogGame = [NSDictionary dictionaryWithObjectsAndKeys:@"TraderPog", TITLE_KEY,
                                  @"TraderPogAppIcon@64.png", ICON_KEY,
                                  @"569329225", APPSTOREID_KEY,
                                  nil];
    NSDictionary* pogMatchGame = [NSDictionary dictionaryWithObjectsAndKeys:@"PogMatch", TITLE_KEY,
                                    @"PogmatchAppIcon@64.png", ICON_KEY,
                                    @"499622283", APPSTOREID_KEY, 
                                    nil];
    _moreGames = [[NSArray arrayWithObjects:traderpogGame, pogMatchGame, nil] retain];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        [self initMoreGames];
    }
    return self;
}

- (void)dealloc 
{
    [_moreGames release];
    [_tableView release];
    [border release];
    [_contentView release];
    [_movieTopLeft release];
    [_movieTopRight release];
    [_movieBotLeft release];
    [_buttonMoreVideos release];
    [_adBannerContainer release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        const float iPadScale = 0.95f * ([[UIScreen mainScreen] bounds].size.height / _contentView.frame.size.height);
        [_contentView setTransform:CGAffineTransformMakeScale(iPadScale, iPadScale)];
        [[_contentView layer] setCornerRadius:6.0f];
        [[_contentView layer] setMasksToBounds:YES];
        [border setTransform:CGAffineTransformMakeScale(iPadScale, iPadScale)];
        [[border layer] setCornerRadius:8.0f];
        [[border layer] setMasksToBounds:YES];
        [[border layer] setBorderWidth:3.0f];
        [[border layer] setBorderColor:[[UIColor whiteColor] CGColor]];
        
        // disable iAd until we upgrade to using the latest API
        [_adBannerContainer setHidden:YES];
        // also resize the ad container
        /*
        static const float padding = 3.0f;
        CGSize adBannerSize = [ADBannerView sizeFromBannerContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
        float originY = [[UIScreen mainScreen] bounds].size.height - adBannerSize.height - padding;
        CGRect adContainerFrame = CGRectInset(CGRectMake(0.0f, originY, adBannerSize.width, adBannerSize.height), 0.0, -1.0);
        [_adBannerContainer setFrame:adContainerFrame];
        */
        
        // on the iPad, the tableview background color cannot be changed unless the backgroundView
        // is re-allocated; don't know why, but this is how people suggested on stackoverflow
        _tableView.backgroundView = nil;
        _tableView.backgroundView = [[[UIView alloc] initWithFrame:[_tableView frame]] autorelease];
        [_tableView setBackgroundColor:[UIColor clearColor]];
    }
    
    // populate movie views with our top 3 movies
    [_movieTopLeft setDelegate:self];
    [_movieTopLeft setOpaque:NO];
    [_movieTopLeft setBackgroundColor:[UIColor blackColor]];
    [_movieTopLeft.indicator startAnimating];
    [_movieTopRight setDelegate:self];
    [_movieTopRight setOpaque:NO];
    [_movieTopRight setBackgroundColor:[UIColor blackColor]];
    [_movieTopRight.indicator startAnimating];
    [_movieBotLeft setDelegate:self];
    [_movieBotLeft setOpaque:NO];
    [_movieBotLeft setBackgroundColor:[UIColor blackColor]];
    [_movieBotLeft.indicator startAnimating];
    
    // topleft is Pogwing
    [_movieTopLeft loadYouTubeURLString:@"http://www.youtube.com/watch?v=aN0ltEOOX0M"];
    
    // topright Pograng
    [_movieTopRight loadYouTubeURLString:@"http://www.youtube.com/watch?v=1QfkDxvGUGQ"];
    
    // botleft which flyer will you hire
    [_movieBotLeft loadYouTubeURLString:@"http://www.youtube.com/watch?v=V9ERbxT3hwU"];
    
    // start out with the Ad Banner hidden until its delegate informs us that ad has loaded
    [_adBannerContainer setHidden:YES];
}

- (void)viewDidUnload
{
    [_tableView release];
    _tableView = nil;
    [border release];
    border = nil;
    [_contentView release];
    _contentView = nil;
    [_movieTopLeft release];
    _movieTopLeft = nil;
    [_movieTopRight release];
    _movieTopRight = nil;
    [_movieBotLeft release];
    _movieBotLeft = nil;
    [_buttonMoreVideos release];
    _buttonMoreVideos = nil;
    [_adBannerContainer release];
    _adBannerContainer = nil;
    [super viewDidUnload];
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

#pragma mark - buttons

- (IBAction)buttonBackPressed:(id)sender 
{
    [[AppNavController getInstance] popToRightViewControllerAnimated:YES];
}

- (IBAction)buttonFacebookPressed:(id)sender 
{
    NSString *peterpogFacebookLink = @"http://m.facebook.com/geolopigs";  
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:peterpogFacebookLink]];  
}

- (IBAction)buttonTwitterPressed:(id)sender 
{
    [PogUIUtility followUsOnTwitter];
}

- (IBAction)buttonMoreVideosPressed:(id)sender 
{
    NSString *channelLink = @"http://www.youtube.com/user/Geolopigs/videos";  
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:channelLink]];  
}


#pragma mark UITableViewDataSource Methods 

- (UITableViewCell *)tableView:(UITableView *)tv
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"MoreCell";
    UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:cellIdentifier];
    if( nil == cell ) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    if([indexPath row] < [_moreGames count])
    {
        NSDictionary* cur = [_moreGames objectAtIndex:[indexPath row]];
        if(cur)
        {
            [cell.textLabel setText:[cur objectForKey:TITLE_KEY]];
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            UIImage* appIcon = [UIImage imageNamed:[cur objectForKey:ICON_KEY]];
            [cell.imageView setImage:appIcon];
            [[cell.imageView layer] setCornerRadius:12.0f];
            [[cell.imageView layer] setMasksToBounds:YES];
            [[cell.imageView layer] setBorderWidth:1.0f];
            [[cell.imageView layer] setBorderColor:[[UIColor grayColor] CGColor]];
            
            float accessoryHeight = 0.8f * cell.bounds.size.height;
            UIImageView* disclosure = [[[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, accessoryHeight, accessoryHeight)] autorelease];
            [disclosure setImage:[UIImage imageNamed:@"iconStoreDisclosure.png"]];
            cell.accessoryView = disclosure;
        }
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows = [_moreGames count];
    return numRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* result = nil;
    if(0 == section)
    {
        result = @"More Games";
    }
    return result;
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if(0 == [indexPath section])
    {
        if([indexPath row] < [_moreGames count])
        {
            NSDictionary* cur = [_moreGames objectAtIndex:[indexPath row]];
            if(cur)
            {
                [[SoundManager getInstance] playImmediateClip:@"ButtonPressed"];
                NSString* appId = [cur objectForKey:APPSTOREID_KEY];
                NSString *iTunesBase = @"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%@&mt=8";  
                NSString* iTunesLink = [NSString stringWithFormat:iTunesBase, appId];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
            }
        }
    }
    [tv deselectRowAtIndexPath:indexPath animated:YES];
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}


static const float CELL_HEIGHT = 50.0f;
- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat result = CELL_HEIGHT;
    return result;
}

static const float SECTIONHEADER_HEIGHT = 30.0f;
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    float tableViewWidth = tableView.bounds.size.width;
    UILabel* header = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableViewWidth, SECTIONHEADER_HEIGHT)] autorelease];
    [header setFont:[UIFont fontWithName:@"MarkerFelt-Wide" size:20.0f]];
    [header setTextColor:[UIColor whiteColor]];
    [header setBackgroundColor:[UIColor clearColor]];
    [header setText:[tableView.dataSource tableView:tableView titleForHeaderInSection:section]];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTIONHEADER_HEIGHT;
}

#pragma mark - UIWebViewDelegate

- (void) webViewDidStartLoad:(UIWebView *)webView
{
    MovieWebView* movie = (MovieWebView*)webView;
    [movie.indicator startAnimating];
    [movie setOpaque:NO];
    [movie setBackgroundColor:[UIColor blackColor]];
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    MovieWebView* movie = (MovieWebView*)webView;
    [movie.indicator stopAnimating];  
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // do nothing
    // when we come up with a replacement to show the user, add the code here
}

#pragma mark - ADBannerViewDelegate
/*
- (BOOL) bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    // pause the frontend ambient music (on music1)
    [[SoundManager getInstance] pauseMusic];
    return YES;
}

- (void) bannerViewActionDidFinish:(ADBannerView *)banner
{
    // restore frontend ambient music
    [[SoundManager getInstance] resumeMusic];
}

- (void) bannerViewDidLoadAd:(ADBannerView *)banner
{
    // unhide the banner view container
    [_adBannerContainer setHidden:NO];
    [_adBannerContainer setAlpha:0.0f];
    [UIView animateWithDuration:0.2f 
                     animations:^{
                         [_adBannerContainer setAlpha:1.0f];
                     }
                     completion:NULL
     ];
}

- (void) bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"AdBanner error %@", error);
    if(![_adBannerContainer isHidden])
    {
        [UIView animateWithDuration:0.2f 
                         animations:^{
                             [_adBannerContainer setAlpha:0.0f];
                         }
                         completion:^(BOOL finished){
                             [_adBannerContainer setHidden:YES];
                         }
         ];
    }
}
*/
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
