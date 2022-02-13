//
//  TutorialTourney.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/9/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppEventDelegate.h"

@class PogUIPageControlDots;
@interface TutorialTourney : UIViewController<UIScrollViewDelegate,AppEventDelegate>
{
    BOOL _guided;
    
    // screen components
    IBOutlet UIView *_contentBorder;
    IBOutlet UIView *_contentView;
    IBOutlet UIView *_scrollViewScrim;
    IBOutlet UILabel *_description;
    IBOutlet UIScrollView *_scrollView;
    IBOutlet PogUIPageControlDots *_pageDots;
    IBOutlet UIButton *_buttonClose;
    IBOutlet UIButton *_buttonNext;
    IBOutlet UIImageView *_checkBox;
    
    // for loading purposes
    IBOutlet UIView *_loadedPage;
    IBOutlet UIView *_loadedPageContent;
    IBOutlet UIView *_border;
    
    // runtime variables
    NSMutableArray* _pages;
    unsigned int _currentPage;
    NSTimer* _tutorialTimer;
    NSTimeInterval _prevTick;
    BOOL _buttonBlink;
}
@property (nonatomic,retain) UIView* loadedPage;
@property (nonatomic,retain) UIView* loadedPageContent;
@property (nonatomic,retain) UIView* loadedBorder;

- (id) initGuided:(BOOL)guidedTutorial;
- (IBAction)buttonClosePressed:(id)sender;
- (IBAction)buttonNextPressed:(id)sender;
- (void) showScrollViewScrim;
- (void) hideScrollViewScrim;
- (IBAction)doNotShow:(id)sender;
@end
