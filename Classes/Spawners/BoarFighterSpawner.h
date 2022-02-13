//
//  BoarFighterSpawner.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/3/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemyProtocol.h"

@interface BoarFighterSpawnerContext : NSObject<EnemySpawnerContextDelegate> 
{
    float           timeToRock;
    float           nextDirection;    
}
@property (nonatomic,assign) float timeToRock;
@property (nonatomic,assign) float nextDirection;
@end

@interface BoarFighterSpawner : NSObject<EnemySpawnerDelegate>
{
    
}

@end
