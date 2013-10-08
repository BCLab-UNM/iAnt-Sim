#import <Foundation/Foundation.h>
#import "Array2D.h"
#import "GA.h"
#import "Pheromone.h"
#import "Team.h"
#import "Robot.h"
#import "Tag.h"
#import "QuadTree.h"
#include "Util.h"


@class Team;
@class Tag;

@interface NSObject(SimulationViewNotifications)
-(void) updateDisplayWindowWithRobots:(NSMutableArray*)_robots team:(Team*)_team tags:(Array2D*)_tags pheromones:(NSMutableArray*)_pheromones;
@end

@interface NSObject(SimulationNotifications)
-(void) finishedGeneration:(int)generation;
-(void) writeTeamToFile:(NSString*)file :(Team*)team;
-(void) writeHeadersToFile:(NSString*)file;
@end


@interface Simulation : NSObject {
    GA* ga;
}

-(NSMutableArray*) run;
-(void) evaluateTeams:(NSMutableArray*)teams;
-(NSMutableArray*) evaluateTeam:(Team*)team;
-(void) initDistributionForArray:(Array2D*)tags;
-(NSPoint) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick withDecayRate:(float)decayRate;

-(NSMutableDictionary*) getParameters;
-(void) setParameters:(NSMutableDictionary*)parameters;

@property (readonly, nonatomic) Team* averageTeam;
@property (readonly, nonatomic) Team* bestTeam;

@property (nonatomic) int teamCount;
@property (nonatomic) int generationCount;
@property (nonatomic) int robotCount;
@property (nonatomic) int tagCount;
@property (nonatomic) int evaluationCount;
@property (nonatomic) int evaluationLimit;
@property (nonatomic) int evalCount;
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

@property (nonatomic) BOOL realWorldError;

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