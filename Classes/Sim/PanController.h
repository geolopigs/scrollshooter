//
//  PanController.h
//  Curry
//
//  Created by Shu Chiun Cheah on 6/27/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIGestureRecognizerSubclass.h>


@interface PanController : NSObject 
{
    CGPoint prevPoint;
    CGPoint curPoint;
    CGPoint curTranslation;

    CGPoint panOrigin;
    CGPoint panPosition;
    BOOL    isPanning;
    BOOL    justStartedPan;
    
    UITouch* _panTouch;
    CGSize _frameSize;
    
    BOOL _enabled;
}
@property (nonatomic,readonly) CGPoint curTranslation;
@property (nonatomic,readonly) BOOL isPanning;
@property (nonatomic,readonly) BOOL justStartedPan;
@property (nonatomic,readonly) CGPoint panPosition;
@property (nonatomic,retain) UITouch* panTouch;
@property (nonatomic,readonly) CGSize frameSize;
@property (nonatomic,assign) BOOL enabled;

- (id) initWithFrameSize:(CGSize)initFrameSize target:(id)target action:(SEL)action;

- (void) reset;
- (void) resetPanOrigin;

- (void) view:(UIView*)view touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) view:(UIView*)view touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) view:(UIView*)view touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void) view:(UIView*)view touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end
