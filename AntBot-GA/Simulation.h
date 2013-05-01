#import <Foundation/Foundation.h>
#import "Array2D.h"

@class Team;
@class Tag;

@interface NSObject(SimulationViewNotifications)
-(void) updateDisplayWindowWithRobots:(NSMutableArray*)r team:(Team*)team tags:(Array2D*)tags pheromones:(NSMutableArray*)p;
@end

@interface NSObject(SimulationNotifications)
-(void) finishedGeneration:(int)generation;
@end


@interface Simulation : NSObject {
    NSMutableArray* colonies;
}

-(int) start;
-(void) runEvaluation;
-(void) breedColonies;
-(void) initDistributionForArray:(Array2D*)tags;
-(NSPoint) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick withDecayRate:(float)decayRate;

@property (readonly, nonatomic) Team* averageTeam;
@property (readonly, nonatomic) Team* bestTeam;

@property (nonatomic) int teamCount;
@property (nonatomic) int generationCount;
@property (nonatomic) int robotCount;
@property (nonatomic) int tagCount;
@property (nonatomic) int evaluationCount;

@property (nonatomic) float distributionRandom;
@property (nonatomic) float distributionPowerlaw;
@property (nonatomic) float distributionClustered;

@property (nonatomic) float tickRate;

@property (nonatomic) BOOL realWorldError;

@property (nonatomic) BOOL variableStepSize;
@property (nonatomic) BOOL uniformDirection;

@property (nonatomic) BOOL decentralizedPheromones;

@property (nonatomic) BOOL randomizeParameters;
@property (nonatomic) NSString* parameterFile;

@property (nonatomic) NSObject* delegate;
@property (nonatomic) NSObject* viewDelegate;

@end