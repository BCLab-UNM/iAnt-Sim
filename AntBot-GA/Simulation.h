#import <Foundation/Foundation.h>
#import "Array2D.h"
#import "Pheromone.h"
#import "Team.h"
#import "Robot.h"
#import "Tag.h"
#include "Util.h"

@class Team;
@class Tag;

@interface NSObject(SimulationViewNotifications)
-(void) updateDisplayWindowWithRobots:(NSMutableArray*)_robots team:(Team*)_team tags:(Array2D*)_tags pheromones:(NSMutableArray*)_pheromones;
@end

@interface NSObject(SimulationNotifications)
-(void) finishedGeneration:(int)generation;
@end


@interface Simulation : NSObject {
    NSMutableArray* teams;
}

-(int) start;
-(void) runEvaluation;
-(void) breedTeams;
-(void) initDistributionForArray:(Array2D*)tags;
-(NSPoint) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick withDecayRate:(float)decayRate;

@property (readonly, nonatomic) Team* averageTeam;
@property (readonly, nonatomic) Team* bestTeam;

@property (nonatomic) int teamCount;
@property (nonatomic) int generationCount;
@property (nonatomic) int robotCount;
@property (nonatomic) int tagCount;
@property (nonatomic) int evaluationCount;
@property (nonatomic) int tickCount;
@property (nonatomic) int exploreTime;

@property (nonatomic) float distributionRandom;
@property (nonatomic) float distributionPowerlaw;
@property (nonatomic) float distributionClustered;

@property (nonatomic) int pileRadius;

@property (nonatomic) int crossoverRate;

@property (nonatomic) NSSize gridSize;
@property (nonatomic) NSPoint nest;

@property (nonatomic) BOOL realWorldError;

@property (nonatomic) BOOL variableStepSize;
@property (nonatomic) BOOL uniformDirection;

@property (nonatomic) BOOL decentralizedPheromones;
@property (nonatomic) int wirelessRange;

@property (nonatomic) BOOL adaptiveWalk;

@property (nonatomic) NSString* parameterFile;

@property (nonatomic) NSObject* delegate;
@property (nonatomic) NSObject* viewDelegate;
@property (nonatomic) float tickRate;

@end