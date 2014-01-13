#import <Foundation/Foundation.h>
#import "Team.h"
#import "Util.h"

@interface GA : NSObject {
    BOOL elitism;
    float crossoverRate;
    float mutationRate;
    int mutationOperator;
    int crossoverOperator;
}

-(id)initWithElitism:(BOOL)_elitism crossoverRate:(float)_crossoverRate crossoverOperator:(int)crossoverOperator mutationRate:(float)_mutationRate andMutationOperator:(int)mutationOperator;

-(void)breedPopulation:(NSMutableArray *)population AtGeneration:(int)generation andMaxGeneration:(int)maxGenerations;

@end
