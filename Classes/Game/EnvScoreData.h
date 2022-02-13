//
//  EnvScoreData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//



@interface EnvScoreData : NSObject<NSCoding>
{
    NSString* envName;
    unsigned int levelIndex;
    unsigned int highscore;
    BOOL hasCompleted;
    unsigned int gradeScore;    // score for computing grades
    NSTimeInterval _flightTime;
    unsigned int _cargosDeliveredHigh;
}
@property (nonatomic,retain) NSString* envName;
@property (nonatomic,assign) unsigned int levelIndex;
@property (nonatomic,assign) unsigned int highscore;
@property (nonatomic,assign) BOOL hasCompleted;
@property (nonatomic,assign) unsigned int gradeScore;
@property (nonatomic,assign) NSTimeInterval flightTime;
@property (nonatomic,assign) unsigned int cargosDeliveredHigh;

- (id)initWithEnv:(NSString*)env level:(unsigned int)level;

@end
