//
//  PogUIPageControlDots.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 2/8/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PogUIPageControlDots : UIView
{
    unsigned int _numPages;
    NSMutableArray* _pageDots;
    
    // image resource
    UIImage* _circle;
    UIImage* _circleRed;
    
    // runtime
    unsigned int _curPage;
}
@property (nonatomic,assign) unsigned int curPage;

- (void) setupWithNumPages:(unsigned int)numPages;
@end
