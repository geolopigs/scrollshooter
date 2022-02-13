//
//  DynamicProtocols.h
//

#import <Foundation/Foundation.h>


@protocol DynamicDelegate
- (BOOL) isViewConstrained;
- (void) addDraw;
- (void) updateBehavior:(NSTimeInterval)elapsed;

@optional
- (void) updatePhysics:(NSTimeInterval)elapsed;
@end

@protocol ConstraintDelegate
- (CGPoint) getPos;
- (void) setPosX:(float)newX;
- (void) setPosY:(float)newY;
- (void) setPos:(CGPoint)newPos;
- (void) setVel:(CGPoint)newVel;
@end


