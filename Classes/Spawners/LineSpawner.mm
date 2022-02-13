//
//  LineSpawner.m
//  PeterPog
//
//  Created by Shu Chiun Cheah on 9/14/11.
//  Copyright (c) 2011 GeoloPigs. All rights reserved.
//

#import "LineSpawner.h"
#import "RenderBucketsManager.h"
#import "EnemySpawner.h"
#import "EnemyFactory.h"
#import "Enemy.h"
#import "GameManager.h"


@implementation LineSpawnerContext
@synthesize timeTillSpawn;
@synthesize spawnCounter;
@synthesize curWave;
@synthesize curWaveNumToSpawn;

@synthesize introOffset;
@synthesize introPos;
@synthesize introVel;
@synthesize launchDelay;
@synthesize launchSplit;
@synthesize launchSpeed;
@synthesize angularSpeed;
@synthesize numToSpawn;
@synthesize timeBetweenSpawns;
@synthesize timeBetweenShots;
@synthesize shotSpeed;
@synthesize introDoneBotLeft;
@synthesize introDoneTopRight;
@synthesize triggerContext;
@synthesize numWaves;
@synthesize timeBetweenWaves;
@synthesize numProgression;

@synthesize dynamicsShadowsIndex;
@synthesize dynamicsBucketIndex;
@synthesize dynamicsAddonsIndex;

- (id) init
{
    self = [super init];
    if(self)
    {
        self.triggerContext = nil;
        
        RenderBucketsManager* bucketsMgr = [RenderBucketsManager getInstance];
        dynamicsShadowsIndex = [bucketsMgr getIndexFromName:@"Shadows"];
        dynamicsBucketIndex = [bucketsMgr getIndexFromName:@"Dynamics"];
        dynamicsAddonsIndex = [bucketsMgr getIndexFromName:@"Addons"];
        
        timeTillSpawn = 0.0f;
        spawnCounter = 0;
    }
    return self;
}

- (void) dealloc
{
    self.triggerContext = nil;
    [super dealloc];
}

- (void) setupFromTriggerContext:(NSDictionary*)context
{
    self.triggerContext = context;
    if(context)
    {
        CGRect playArea = [[GameManager getInstance] getPlayArea];
        float introPosX = [[context objectForKey:@"introPosX"] floatValue] * playArea.size.width;
        float introPosY = [[context objectForKey:@"introPosY"] floatValue] * playArea.size.height;
        float introVelX = [[context objectForKey:@"introVelX"] floatValue];
        float introVelY = [[context objectForKey:@"introVelY"] floatValue];
        introPos = CGPointMake(introPosX, introPosY);
        introVel = CGPointMake(introVelX, introVelY);
        
        angularSpeed = [[context objectForKey:@"angularSpeed"] floatValue] * M_PI; 
        launchDelay = [[context objectForKey:@"launchDelay"] floatValue];
        launchSplit = [[context objectForKey:@"launchSplit"] floatValue];
        launchSpeed = [[context objectForKey:@"launchSpeed"] floatValue];
        numToSpawn = [[context objectForKey:@"numToSpawn"] unsignedIntValue];
        timeBetweenSpawns = [[context objectForKey:@"timeBetweenSpawns"] floatValue];
        
        float doneX = [[context objectForKey:@"introDoneX"] floatValue];
        float doneY = [[context objectForKey:@"introDoneY"] floatValue];
        float doneW = [[context objectForKey:@"introDoneW"] floatValue];
        float doneH = [[context objectForKey:@"introDoneH"] floatValue];
        introDoneBotLeft = CGPointMake((doneX * playArea.size.width) + playArea.origin.x,
                                       (doneY * playArea.size.height) + playArea.origin.y);
        introDoneTopRight = CGPointMake((doneW * playArea.size.width) + introDoneBotLeft.x,
                                        (doneH * playArea.size.height) + introDoneBotLeft.y);
        timeBetweenShots = 1.0f / [[context objectForKey:@"shotFreq"] floatValue];
        shotSpeed = [[context objectForKey:@"shotSpeed"] floatValue];
        NSNumber* introOffsetX = [context objectForKey:@"introOffsetX"];
        NSNumber* introOffsetY = [context objectForKey:@"introOffsetY"];
        if(introOffsetX && introOffsetY)
        {
            introOffset = CGPointMake([introOffsetX floatValue] * playArea.size.width, 
                                      [introOffsetY floatValue] * playArea.size.height);
        }
        else
        {
            introOffset = CGPointMake(0.0f, 0.0f);
        }
        
        self.numWaves = 0;
        NSNumber* numWavesNumber = [context objectForKey:@"numWaves"];
        if(numWavesNumber)
        {
            self.numWaves = [numWavesNumber intValue];
            if([self numWaves] == 0)
            {
                self.numWaves = 1;
            }
        }
        self.timeBetweenWaves = 1.0f;
        NSNumber* timeBtwnWavesNumber = [context objectForKey:@"timeBetweenWaves"];
        if(timeBtwnWavesNumber)
        {
            self.timeBetweenWaves = [timeBtwnWavesNumber floatValue];
        }
        self.numProgression = 1;
        NSNumber* progressionNumber = [context objectForKey:@"numProgression"];
        if(progressionNumber)
        {
            self.numProgression = [progressionNumber unsignedIntValue];
        }
    }
}


#pragma mark - EnemySpawnerContextDelegate
- (NSDictionary*) spawnerTriggerContext
{
    return triggerContext;
}

- (float) spawnerLayerDistance
{
    return 100.0f;
}


@end

@implementation LineSpawner
#pragma mark -
#pragma mark EnemySpawnerDelegate

- (void) initEnemySpawner:(EnemySpawner*)spawner withContextInfo:(NSMutableDictionary *)info
{
    LineSpawnerContext* newContext = [[LineSpawnerContext alloc] init];
    spawner.spawnerContext = newContext;
    [newContext release];
}

- (void) restartEnemySpawner:(EnemySpawner *)spawner
{
    LineSpawnerContext* spawnerContext = [spawner spawnerContext];
    spawnerContext.timeTillSpawn = 0.0f;
    spawnerContext.spawnCounter = 0;
    spawnerContext.curWave = 0;
    if(0 != [spawnerContext numWaves])
    {
        // if a non-zero numWaves is specified, this is a progressive spawner
        // so, start with spawning one step of progression number of enemies
        // numWaveNumToSpawn will cycle back to zero when it exceeds the max specified by numToSpawn;
        spawnerContext.curWaveNumToSpawn = [spawnerContext numProgression];
        
        // init incap array with 0's
        unsigned int i = 0;
        unsigned int num = [spawnerContext numProgression];
        while(i < [spawnerContext numWaves])
        {
            [spawner.incapsPerWave addObject:[NSNumber numberWithUnsignedInt:num]];
            num += [spawnerContext numProgression];
            ++i;
        }
    }
    else
    {
        // set curWave to -1 to get at least one wave of numToSpawn in the case when no numWaves is specified
        spawnerContext.curWave = -1;
        spawnerContext.curWaveNumToSpawn = [spawnerContext numToSpawn];
        [spawner.incapsPerWave addObject:[NSNumber numberWithUnsignedInt:[spawnerContext numToSpawn]]];
    }
}

- (Enemy*) updateEnemySpawner:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    Enemy* newEnemy = nil;
    LineSpawnerContext* spawnerContext = [spawner spawnerContext];
    
    // spawn one at a time
    if([spawnerContext curWave] < [spawnerContext numWaves])
    {
        if([spawnerContext curWaveNumToSpawn] > [spawnerContext spawnCounter])
        {
            CGPoint spawnPos = [spawnerContext introPos];
            spawnPos.x += ([spawnerContext introOffset].x * [spawnerContext spawnCounter]);
            spawnPos.y += ([spawnerContext introOffset].y * [spawnerContext spawnCounter]);
            spawnerContext.timeTillSpawn -= elapsed;
            if(0.0f >= spawnerContext.timeTillSpawn)
            {
                newEnemy = [[EnemyFactory getInstance] createEnemyFromKey:@"BoarFighterBasic" 
                                                                    AtPos:spawnPos
                                                       withSpawnerContext:spawnerContext];
                
                // note this enemy's waveIndex
                int waveIndex = [spawnerContext curWave];
                if(0 > waveIndex)
                {
                    waveIndex = 0;
                }
                newEnemy.waveIndex = waveIndex;
                spawnerContext.timeTillSpawn = spawnerContext.timeBetweenSpawns;
                spawnerContext.spawnCounter++;
            }
        }
        else
        {
            // next wave
            spawnerContext.curWave++;
            if([spawnerContext curWave] < [spawnerContext numWaves])
            {
                spawnerContext.curWaveNumToSpawn += [spawnerContext numProgression];
                if([spawnerContext curWaveNumToSpawn] > [spawnerContext numToSpawn])
                {
                    // cycle back to first progression when hit max
                    spawnerContext.curWaveNumToSpawn = [spawnerContext numProgression];
                }
                spawnerContext.spawnCounter = 0;
                spawnerContext.timeTillSpawn = [spawnerContext timeBetweenWaves];
                
                // reset the incapsPerWave for this waveIndex
                [spawner setIncapsForWave:[spawnerContext curWave] toValue:[spawnerContext curWaveNumToSpawn]];
            }
        }
    }
    
    return newEnemy;
}

- (void) retireEnemies:(EnemySpawner *)spawner elapsed:(NSTimeInterval)elapsed
{
    for(Enemy* cur in spawner.spawnedEnemies)
    {
        if([cur willRetire])
        {
            [cur kill];
        }
    }
}

- (void) activateEnemySpawner:(EnemySpawner*)spawner withTriggerContext:(NSDictionary*)context
{
    [spawner setActivated:YES]; 
    LineSpawnerContext * spawnerContext = [spawner spawnerContext];
    [spawnerContext setupFromTriggerContext:context];
    
    // restart enemy spawner
    [self restartEnemySpawner:spawner];
}

@end
