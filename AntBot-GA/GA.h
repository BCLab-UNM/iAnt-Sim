#import <Foundation/Foundation.h>
#import "Team.h"
#import "Utilities.h"

@interface GA : NSObject {
    BOOL elitism;
    float crossoverRate;
    float mutationRate;
    int selectionOperator;
    int mutationOperator;
    int crossoverOperator;
}

-(id)initWithElitism:(BOOL)_elitism selectionOperator:(int)_selectionOperator crossoverRate:(float)_crossoverRate crossoverOperator:(int)crossoverOperator mutationRate:(float)_mutationRate andMutationOperator:(int)mutationOperator;

-(void)breedPopulation:(NSMutableArray *)population AtGeneration:(int)generation andMaxGeneration:(int)maxGenerations;

@property (nonatomic) float fixedVarianceSigma;

@end
