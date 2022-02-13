//
//  GameObjectSizes.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/1/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameObjectSizes : NSObject
{
    NSMutableDictionary* sizeReg;
}
@property (nonatomic,retain) NSMutableDictionary* sizeReg;

+ (GameObjectSizes*)getInstance;
+ (void) destroyInstance;

- (void) addSizeNamed:(NSString*)name
          renderWidth:(float)renderWidth
         renderHeight:(float)renderHeight
       collisionWidth:(float)collisionWidth
      collisionHeight:(float)collisionHeight;
- (CGSize) renderSizeFor:(NSString*)name;
- (CGSize) colSizeFor:(NSString*)name;

@end
