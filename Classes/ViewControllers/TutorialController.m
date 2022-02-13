//
//  TutorialController.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "TutorialController.h"
#import "PogUIPageControlDots.h"
#import "SoundManager.h"
#import <QuartzCore/QuartzCore.h>

static const unsigned int TUTORIAL_PAGES_NUM = 6;
static const float TUTORIAL_TIMER_INTERVAL = 0.5f;

@interface TutorialController (PrivateMethods)
- (void) setupScrollView;
- (void) loadPages;
- (void) gotoPage:(unsigned int)pageIndex userScroll:(BOOL)userScroll;
- (void) refreshGuidedButton;
- (void) createTimer:(NSTimeInterval)duration;
- (void) releaseTimer;
- (void) timerTick;
@end

@implementation TutorialController
@synthesize delegate = _delegate;
@synthesize loadedPage = _loadedPage;
@synthesize loadedPageContent = _loadedPageContent;
@synthesize loadedBorder = _border;

- (id)initGuided:(BOOL)guidedTutorial
{
    self = [super initWithNibName:@"TutorialController" bundle:nil];
    if (self) 
    {
        _delegate = nil;
        _pages = [[NSMutableArray array] retain];
        _loadedPage = nil;
        _loadedPageContent = nil;
        _border = nil;
        _currentPage = 0;
        _tutorialTimer = nil;
        _guided = guidedTutorial;
    }
    return self;
}

- (void) dealloc
{
    [self releaseTimer];
    [_pages release];
    [_delegate release];
    [_scrollViewScrim release];
    [_description release];
    [_scrollView release];
    [_pageDots release];
    [_border release];
    [_loadedPage release];
    [_loadedPageContent release];
    [_border release];
    [_buttonClose release];
    [_buttonNext release];
    [_contentBorder release];
    [_contentView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) 
    {
        [[_contentView layer] setCornerRadius:6.0f];
        [[_contentView layer] setMasksToBounds:YES];
        [[_contentBorder layer] setCornerRadius:8.0f];
        [[_contentBorder layer] setMasksToBounds:YES];
        [[_contentBorder layer] setBorderWidth:3.0f];
        [[_contentBorder layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    }
    
    [self setupScrollView];
    [self loadPages];
    [self gotoPage:0 userScroll:NO];
    
    if(_guided)
    {
        [_buttonClose setHidden:YES];
        [_buttonNext setHidden:NO];
        _buttonBlink = YES;
        [self createTimer:TUTORIAL_TIMER_INTERVAL];
    }
    else
    {
        [_buttonClose setHidden:NO];
        [_buttonNext setHidden:YES];
    }
}

- (void)viewDidUnload
{
    [self releaseTimer];
    [_pages release];
    _pages = nil;
    [_delegate release];
    _delegate = nil;
    [_scrollViewScrim release];
    _scrollViewScrim = nil;
    [_description release];
    _description = nil;
    _scrollView.delegate = nil;
    [_scrollView release];
    _scrollView = nil;
    [_pageDots release];
    _pageDots = nil;
    [_loadedPage release];
    _loadedPage = nil;
    [_loadedPageContent release];
    _loadedPageContent = nil;
    [_border release];
    _border = nil;
    [_buttonClose release];
    _buttonClose = nil;
    [_buttonNext release];
    _buttonNext = nil;
    [_contentBorder release];
    _contentBorder = nil;
    [_contentView release];
    _contentView = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - timer
- (void) createTimer:(NSTimeInterval)duration
{
    _tutorialTimer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(timerTick) userInfo:nil repeats:YES];  	
    _prevTick = [NSDate timeIntervalSinceReferenceDate];	
}

- (void) releaseTimer
{
    if((_tutorialTimer) && ([_tutorialTimer isValid]))
    {
        [_tutorialTimer invalidate];
        _tutorialTimer = nil;
    }
}

- (NSTimeInterval) advanceTimer
{
	NSTimeInterval curTick = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval elapsed = curTick - _prevTick;
	if(elapsed < TUTORIAL_TIMER_INTERVAL)
	{
		elapsed = TUTORIAL_TIMER_INTERVAL;
	}
	_prevTick = curTick;	
	return elapsed;
}

- (void) timerTick
{
    // blink Next button
    if(![_buttonNext isHidden])
    {
        if(!_buttonBlink)
        {
            _buttonBlink = YES;
            [_buttonNext setAlpha:1.0f];
        }
        else
        {
            _buttonBlink = NO;
            [_buttonNext setAlpha:0.2f];
        }
    }
    else if(![_buttonClose isHidden])
    {
        if(!_buttonBlink)
        {
            _buttonBlink = YES;
            [_buttonClose setAlpha:1.0f];
        }
        else
        {
            _buttonBlink = NO;
            [_buttonClose setAlpha:0.2f];
        }        
    }
}

#pragma mark - tutorial pages

+ (NSString*) descMove
{
    return @"Tap and drag on the screen to move";
}

+ (NSString*) descCargo
{
    return @"Fly near cargos and pickups to pull them in";
}

+ (NSString*) descHit
{
    return @"You only lose health when hit within the red circle (hit zone)";
}

+ (NSString*) descBomb
{
    return @"Tap with two fingers to release bomb";
}

+ (NSString*) descDelivery
{
    return @"Deliver collected cargos at end of each Route";
}

+ (NSString*) descGoodies
{
    return @"Collect these goodies for power-ups.";
}

+ (NSString*) descAtPageIndex:(unsigned int)pageIndex
{
    NSString* result = nil;
    if(TUTORIAL_PAGES_NUM > pageIndex)
    {
        NSArray* pageDescriptions = [NSArray arrayWithObjects:[TutorialController descMove],
                                     [TutorialController descCargo],
                                     [TutorialController descHit],
                                     [TutorialController descBomb],
                                     [TutorialController descDelivery],
                                     [TutorialController descGoodies],
                                     nil];
        result = [pageDescriptions objectAtIndex:pageIndex];
    }
    return result;
}

- (void) setupScrollView
{
    CGRect pageFrame = [_scrollView frame];
    [_pageDots setupWithNumPages:TUTORIAL_PAGES_NUM];
    _scrollView.pagingEnabled = YES;
    _scrollView.scrollEnabled = NO;
    _scrollView.contentSize = CGSizeMake(pageFrame.size.width * TUTORIAL_PAGES_NUM,
                                         pageFrame.size.height);
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
    _scrollView.delaysContentTouches = NO;
    _scrollView.scrollEnabled = YES;
    
    // add myself as delegate to respond to scroll events
    _scrollView.delegate = self;
    
    _currentPage = 0;
}

- (void) loadPages
{
    CGRect pageFrame = [_scrollView frame];
    NSArray* pageNames = [NSArray arrayWithObjects:@"TutorialMove", 
                          @"TutorialCargo",
                          @"TutorialHit",
                          @"TutorialBomb",
                          @"TutorialDelivery",
                          @"TutorialGoodies",
                          nil];
    
    for(unsigned int index = 0; index < TUTORIAL_PAGES_NUM; ++index)
    {
        NSString* cur = [pageNames objectAtIndex:index];
        [[NSBundle mainBundle] loadNibNamed:cur owner:self options:nil];

        // init border for the newly loaded page
        [[self.loadedBorder layer] setCornerRadius:4.0f];
        [[self.loadedBorder layer] setMasksToBounds:YES];
        [[self.loadedBorder layer] setBorderWidth:2.0f];
        [[self.loadedBorder layer] setBorderColor:[[UIColor whiteColor] CGColor]];

        // add page to scrollview
        [_pages addObject:[self loadedPage]];
        CGRect myFrame = pageFrame;
        myFrame.origin.x = (pageFrame.size.width * index);
        myFrame.origin.y = 0.0f;
        self.loadedPage.frame = myFrame;
        [_scrollView addSubview:[self loadedPage]];
        
        self.loadedBorder = nil;
        self.loadedPageContent = nil;
        self.loadedPage = nil;
    }
}

- (void) gotoPage:(unsigned int)pageIndex userScroll:(BOOL)userScroll
{
    if(pageIndex > TUTORIAL_PAGES_NUM)
    {
        pageIndex = TUTORIAL_PAGES_NUM - 1;
    }
    
    _currentPage = pageIndex;
    if(!userScroll)
    {
        // update scrollview
        CGRect myFrame = [_scrollView frame];
        myFrame.origin.x = (myFrame.size.width * _currentPage);
        myFrame.origin.y = 0.0f;
        [_scrollView scrollRectToVisible:myFrame animated:YES];
        
        // refresh guided button (if in guided mode)
        [self refreshGuidedButton];
        
        // play sound
        [[SoundManager getInstance] playClip:@"BackForwardButton"];
    }
    
    // update page-control dots
    [_pageDots setCurPage:_currentPage];
    
    // update description text
    [_description setText:[TutorialController descAtPageIndex:pageIndex]];
}    

- (void) refreshGuidedButton
{
    if(_guided)
    {
        // if guided, show next button when not on last page;
        // otherwise, show the close button
        if((_currentPage+1) < TUTORIAL_PAGES_NUM)
        {
            [_buttonNext setHidden:NO];
            [_buttonClose setHidden:YES];
        }
        else
        {
            [_buttonNext setHidden:YES];
            [_buttonClose setHidden:NO];
        }
    }
}

#pragma mark - ScrollView delegate
- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = _scrollView.frame.size.width;
    int page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [self gotoPage:page userScroll:YES];
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)sender
{
    // do nothing
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
    [[SoundManager getInstance] playClip:@"BackForwardButton"];
    [self refreshGuidedButton];
}

#pragma mark - button actions

- (IBAction) buttonClosePressed:(id)sender 
{
    _scrollView.delegate = nil;
    if(_delegate)
    {
        [[SoundManager getInstance] playClip:@"ButtonPressed"];
        [self releaseTimer];
        [_delegate dismissTutorial];
    }
}

- (IBAction)buttonNextPressed:(id)sender 
{
    unsigned int nextPage = _currentPage+1;
    if(TUTORIAL_PAGES_NUM <= nextPage)
    {
        // that was the last page, close it
        [self buttonClosePressed:nil];
    }
    else
    {
        // go to the next page
        [self gotoPage:nextPage userScroll:NO];
    }
}

#pragma mark - visuals stuff
- (void) showScrollViewScrim
{
    [_scrollViewScrim setHidden:NO];
}

- (void) hideScrollViewScrim
{
    [_scrollViewScrim setHidden:YES];    
}

@end
