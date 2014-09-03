#import <Foundation/Foundation.h>
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
#ifdef __cplusplus
-(void) updateDisplayWindowWithRobots:(NSMutableArray*)_robots team:(Team*)_team grid:(std::vector<std::vector<Cell*>>&)_grid pheromones:(NSMutableArray*)_pheromones regions:(NSMutableArray*)_regions clusters:(NSMutableArray*)_clusters;
#endif
@end

@interface NSObject(SimulationNotifications)
-(void) finishedGeneration:(int)generation atEvaluation:(int)evaluation;
@end


@interface Simulation : NSObject <Archivable> {
    GA* ga;
}

-(NSMutableDictionary*) run;

#ifdef __cplusplus
-(void) evaluateTeams:(NSMutableArray*)teams onGrid:(std::vector<std::vector<Cell*>>)grid;
-(NSMutableDictionary*) evaluateTeam:(Team*)team onGrid:(std::vector<std::vector<Cell*>>)grid;
-(int) stateTransition:(NSMutableArray*)robots inTeam:(Team*)team atTick:(int)tick onGrid:(std::vector<std::vector<Cell*>>&)grid withDecomp:(Decomposition*)decomp
        withPheromones:(NSMutableArray*)pheromones
              clusters:(NSMutableArray*)clusters
             foundTags:(NSMutableArray*)foundTags
     unexploredRegions:(NSMutableArray*)unexploredRegions;
-(void) initDistributionForArray:(std::vector<std::vector<Cell*>>&)grid;
#endif

@property (readonly, nonatomic) Team* averageTeam;
@property (readonly, nonatomic) Team* bestTeam;

@property (nonatomic) SensorError* error;
@property (nonatomic) BOOL observedError;

@property (nonatomic) int teamCount;
@property (nonatomic) int generationCount;
@property (nonatomic) int robotCount;
@property (nonatomic) int tagCount;
@property (nonatomic) int evaluationCount;
@property (nonatomic) int evaluationLimit;
@property (nonatomic) int tickCount;
@property (nonatomic) int exploreTime;
@property (nonatomic) float exploredCutoff;

@property (nonatomic) float distributionRandom;
@property (nonatomic) float distributionPowerlaw;
@property (nonatomic) float distributionClustered;

@property (nonatomic) int pileRadius;

@property (nonatomic) float crossoverRate;
@property (nonatomic) float mutationRate;
@property (nonatomic) int selectionOperator;
@property (nonatomic) int mutationOperator;
@property (nonatomic) int crossoverOperator;
@property (nonatomic) bool elitism;

@property (nonatomic) NSSize gridSize;
@property (nonatomic) NSPoint nest;

@property (nonatomic) NSString* parameterFile;

@property (nonatomic) NSObject* delegate;
@property (nonatomic) NSObject* viewDelegate;
@property (nonatomic) float tickRate;

@end