//
//  PogUISlotBar.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 1/27/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    PogUISlotBarOrientationHorizontal = 0,
    PogUISlotBarOrientationVertical,
} PogUISlotBarOrientation;

@interface PogUISlotBar : UIView
{
    unsigned int _numSlots;
    unsigned int _numFilled;
    PogUISlotBarOrientation _orientation;
    
    UIColor* _fillColor;
    UIColor* _outlineColor;
    float _slotSpacing;
    float _outFrameInset;
    float _fillFrameInset;
    float _outlineWidth;
}
@property (nonatomic,assign) unsigned int numFilled;
@property (nonatomic,assign) unsigned int numSlots;
@property (nonatomic,retain) UIColor* fillColor;
@property (nonatomic,retain) UIColor* outlineColor;
@property (nonatomic,assign) float slotSpacing;
@property (nonatomic,assign) float outFrameInset;
@property (nonatomic,assign) float fillFrameInset;
@property (nonatomic,assign) float outlineWidth;

- (id) initWithFrame:(CGRect)frame numSlots:(unsigned int)numSlots; // default is horizontal
- (id) initWithFrame:(CGRect)frame numSlots:(unsigned int)numSlots orientation:(PogUISlotBarOrientation)orientation;

- (void) setFillColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;
- (void) setOutlineColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

@end
