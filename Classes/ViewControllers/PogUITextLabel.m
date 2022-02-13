//
//  PogUITextLabel.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/26/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import "PogUITextLabel.h"
#import <CoreText/CoreText.h>

@interface PogUITextLabel()
- (void) drawScaledString:(NSString*)string;
- (NSAttributedString *)generateAttributedString:(NSString *)string;
@end

@implementation PogUITextLabel
@synthesize text = _text;

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        _text = nil;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        _text = nil;
    }
    return self;
}

- (void) dealloc
{
    [_text release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect 
{
    if(_text)
    {
        [self drawScaledString:_text]; 
    }
}

- (void)drawScaledString:(NSString *)string
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    NSAttributedString *attrString = [self generateAttributedString:string];
    
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)attrString, CFRangeMake(0, string.length), 
                                   kCTForegroundColorAttributeName, [UIColor colorWithRed:0.15 green:0.2 blue:0.2 alpha:1.0].CGColor);
    
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef) attrString);
    
    // CTLineGetTypographicBounds doesn't give correct values, 
    // using GetImageBounds instead
    CGRect imageBounds = CTLineGetImageBounds(line, context);
    CGFloat width = imageBounds.size.width;
    CGFloat height = imageBounds.size.height;
    
    CGFloat padding = 2;
    
    width += padding;
    height += padding;
    
    float sx = self.bounds.size.width / width;
    float sy = self.bounds.size.height / height;
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    CGContextTranslateCTM(context, 1, self.bounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextScaleCTM(context, sx, sy);
    
    CGContextSetTextPosition(context, -imageBounds.origin.x + padding/2, -imageBounds.origin.y + padding/2);
    
    CTLineDraw(line, context);
    CFRelease(line);
}

- (NSAttributedString *)generateAttributedString:(NSString *)string
{
    
    CTFontRef helv = CTFontCreateWithName(CFSTR("HelveticaNeue-CondensedBlack"),12, NULL);
    CGColorRef color = [UIColor blackColor].CGColor;
    
    NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)helv, (NSString *)kCTFontAttributeName,
                                    color, (NSString *)kCTForegroundColorAttributeName,
                                    nil];
    
    NSAttributedString *attrString = [[[NSMutableAttributedString alloc]
                                       initWithString:string
                                       attributes:attributesDict] autorelease];
    
    return attrString;
}

@end
