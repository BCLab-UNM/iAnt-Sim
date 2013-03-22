#import <Foundation/Foundation.h>

@class Colony;
@class Tag;

@interface NSObject(SimulationViewNotifications)
-(void) updateAnts:(NSMutableArray*)ants tags:(NSMutableArray*)tags pheromones:(NSMutableArray*)pheromones;
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

@property (readonly, nonatomic) Colony* averageColony;
@property (readonly, nonatomic) Colony* bestColony;

@property (nonatomic) int colonyCount;
@property (nonatomic) int generationCount;
@property (nonatomic) int antCount;
@property (nonatomic) int tagCount;

@property (nonatomic) float distributionRandom;
@property (nonatomic) float distributionPowerlaw;
@property (nonatomic) float distributionClustered;

@property (nonatomic) float tickRate;

@property (nonatomic) float localizationError;
@property (nonatomic) float tagReadError;

@property (nonatomic) NSObject* delegate;
@property (nonatomic) NSObject* viewDelegate;

@end