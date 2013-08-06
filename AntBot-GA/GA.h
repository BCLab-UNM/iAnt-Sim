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

-(id) initWithElitism:(BOOL)_elitism crossover:(float)_crossoverRate andMutation:(float)_mutationRate :(int)mutationOp :(int)crossoverOp;

-(void) breedTeams:(NSMutableArray *)teams AtGeneration:(int)generation :(int)maxGenerations;

//Selection
-(NSMutableArray*) tournamentSelectionOn:(NSMutableArray*)teams;

//Crossover
-(void) independentAssortmentCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child withFirstParentBias:(float)bias;
-(void) uniformCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child;
-(void) onePointCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child;
-(void) twoPointCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child;

//Mutation
-(void) valueDependentVarianceMutationForParameter:(NSNumber **)parameter atGeneration:(int)generation;
-(void) fixedVarianceMutationForParameter:(NSNumber **)parameter :(float)sigma;
-(void) decreasingVarianceMutationForParameter:(NSNumber **)parameter atGeneration:(int)generation :(int)maxGenerations :(float)maxVariance :(float)minVariance;


@end
