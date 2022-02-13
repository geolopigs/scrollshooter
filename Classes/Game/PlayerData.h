//
//  PlayerData.h
//  PeterPog
//
//  Created by Shu Chiun Cheah on 8/26/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//



@interface PlayerData : NSObject<NSCoding>
{
    unsigned int pogCoins;
    NSMutableDictionary* _inventory;
    NSMutableDictionary* _hangar;
    NSMutableArray* _transactionReceipts;       // in-app purchase receipts in case
                                                // we need to recover it in the future
}
@property (nonatomic,assign) unsigned int pogCoins;
@property (nonatomic,retain) NSMutableDictionary* inventory;
@property (nonatomic,retain) NSMutableDictionary* hangar;
@property (nonatomic,retain) NSMutableArray* transactionReceipts;
@end
