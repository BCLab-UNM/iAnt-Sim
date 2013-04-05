#import <Foundation/Foundation.h>

@class Team;
@class Tag;

@interface NSObject(SimulationViewNotifications)
-(void) updateRobots:(NSMutableArray*)robots tags:(NSMutableArray*)tags pheromones:(NSMutableArray*)pheromones;
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
-(void) initDistributionForArray:(Tag* __strong[90][90])tags;
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

@property (nonatomic) float positionalError;
@property (nonatomic) float detectionError;

@property (nonatomic) float tagFractionCutoff;

@property (nonatomic) BOOL randomizeParameters;

@property (nonatomic) NSString* parameterFile;

@property (nonatomic) NSObject* delegate;
@property (nonatomic) NSObject* viewDelegate;

@end