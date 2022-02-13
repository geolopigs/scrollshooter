//
//  SineWeaver.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/13/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SineWeaver : NSObject
{
    float range;
    float vel;
    float base;
    float curParam;
}
@property (nonatomic,assign) float base;
@property (nonatomic,assign) float curParam;
- (id) initWithRange:(float)initRange vel:(float)initVel;
- (void) reset;
- (void) resetRandomWithBase:(float)baseline;
- (float) update:(NSTimeInterval)elapsed;
- (float) eval;
- (BOOL) willCrossThreshold:(float)threshold afterElapsed:(NSTimeInterval)elapsed;
@end
