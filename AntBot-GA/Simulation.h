#import <Foundation/Foundation.h>
#import "Array2D.h"
#import "Archivable.h"
#import "Cell.h"
#import "Cluster.h"
#import "Decomposition.h"
#import "SensorError.h"
#import "GA.h"
#import "Pheromone.h"
#import "QuadTree.h"
#import "Team.h"
#import "Robot.h"
#import "Tag.h"
#import "Utilities.h"


@class Team;
@class Tag;

@interface NSObject(SimulationViewNotifications)
-(void) updateDisplayWindowWithRobots:(NSMutableArray*)_robots team:(Team*)_team grid:(Array2D*)_grid pheromones:(NSMutableArray*)_pheromones regions:(NSMutableArray*)_regions clusters:(NSMutableArray*)_clusters;
@end

@interface NSObject(SimulationNotifications)
-(void) finishedGeneration:(int)generation atEvaluation:(int)evaluation;
@end


@interface Simulation : NSObject <Archivable> {
    GA* ga;
}

-(NSMutableArray*) run;
-(void) evaluateTeams:(NSMutableArray*)teams onGrid:(Array2D*)grid;
-(void) stateTransition:(NSMutableArray*)robots inTeam:(Team*)team atTick:(int)tick onGrid:(Array2D*)grid
         withPheromones:(NSMutableArray*)pheromones
               clusters:(NSMutableArray*)clusters
                regions:(NSMutableArray*)regions
      unexploredRegions:(NSMutableArray*)unexploredRegions;
-(NSMutableArray*) evaluateTeam:(Team*)team onGrid:(Array2D*)grid;
-(void) initDistributionForArray:(Array2D*)grid;
-(NSPoint) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick withDecayRate:(float)decayRate;

@property (readonly, nonatomic) Team* averageTeam;
@property (readonly, nonatomic) Team* bestTeam;

@property (nonatomic) SensorError* error;

@property (nonatomic) int teamCount;
@property (nonatomic) int generationCount;
@property (nonatomic) int robotCount;
@property (nonatomic) int tagCount;
@property (nonatomic) int evaluationCount;
@property (nonatomic) int evaluationLimit;
@property (nonatomic) int tickCount;
@property (nonatomic) int exploreTime;

@property (nonatomic) float distributionRandom;
@property (nonatomic) float distributionPowerlaw;
@property (nonatomic) float distributionClustered;

@property (nonatomic) int pileRadius;

@property (nonatomic) float crossoverRate;
@property (nonatomic) float mutationRate;
@property (nonatomic) int mutationOperator;
@property (nonatomic) int crossoverOperator;
@property (nonatomic) bool elitism;

@property (nonatomic) NSSize gridSize;
@property (nonatomic) NSPoint nest;

@property (nonatomic) BOOL variableStepSize;
@property (nonatomic) BOOL uniformDirection;
@property (nonatomic) BOOL adaptiveWalk;

@property (nonatomic) BOOL decentralizedPheromones;
@property (nonatomic) int wirelessRange;

@property (nonatomic) NSString* parameterFile;

@property (nonatomic) NSObject* delegate;
@property (nonatomic) NSObject* viewDelegate;
@property (nonatomic) float tickRate;

@end