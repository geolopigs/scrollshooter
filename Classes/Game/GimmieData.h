//
//  GimmieData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//



@interface GimmieData : NSObject<NSCoding>
{
    NSMutableDictionary* _completedEvents;
    BOOL _gimmieActivated;
    NSMutableDictionary* _repeatedEvents;
}
@property (nonatomic,retain) NSMutableDictionary* completedEvents;
@property (nonatomic,assign) BOOL gimmieActivated;
@property (nonatomic,retain) NSMutableDictionary* repeatedEvents;
@end
