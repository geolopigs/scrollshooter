//
//  TipsManager.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 3/18/12.
//  Copyright (c) 2012 GeoloPigs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TipsManager : NSObject


// singleton
+(TipsManager*) getInstance;
+(void) destroyInstance;

@end
