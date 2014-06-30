#import "GA.h"

<<<<<<< HEAD
@implementation GA

-(id) initWithElitism:(BOOL)_elitism crossover:(float)_crossoverRate andMutation:(float)_mutationRate :(int)mutationOp :(int)crossoverOp{
    if (self = ([super init])) {
        elitism = _elitism;
        crossoverRate = _crossoverRate;
        mutationRate = _mutationRate;
        mutationOperator = mutationOp;
        crossoverOperator = crossoverOp;
=======
@interface GA()

//Selection
-(NSMutableArray*)tournamentSelectionOn:(NSMutableArray*)population;
-(NSMutableArray*)rankBasedElististSelectionOn:(NSMutableArray*)population withCutoff:(float)cutoff;

//Crossover
-(void)independentAssortmentCrossoverFromParents:(NSMutableArray*)parents toChild:(Team *)child withFirstParentBias:(float)bias;
-(void)uniformCrossoverFromParents:(NSMutableArray*)parents toChild:(Team *)child;
-(void)onePointCrossoverFromParents:(NSMutableArray*)parents toChild:(Team *)child;
-(void)twoPointCrossoverFromParents:(NSMutableArray*)parents toChild:(Team *)child;

//Mutation
-(float)valueDependentVarianceMutationForParameter:(float)parameter;
-(float)fixedVarianceMutationForParameter:(float)parameter :(float)sigma;
-(float)decreasingVarianceMutationForParameter:(float)parameter atGeneration:(int)generation :(int)maxGenerations :(float)maxVariance :(float)minVariance;

@end

@implementation GA

@synthesize fixedVarianceSigma;

-(id)initWithElitism:(BOOL)_elitism selectionOperator:(int)_selectionOperator crossoverRate:(float)_crossoverRate crossoverOperator:(int)_crossoverOperator mutationRate:(float)_mutationRate andMutationOperator:(int)_mutationOperator {
    if (self = ([super init])) {
        elitism = _elitism;
        selectionOperator = _selectionOperator;
        crossoverRate = _crossoverRate;
        crossoverOperator = _crossoverOperator;
        mutationRate = _mutationRate;
        mutationOperator = _mutationOperator;
        
        fixedVarianceSigma = 0.05;
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
    }
    return self;
}

/*
 * Tournament selection
 */
<<<<<<< HEAD
-(NSMutableArray*) tournamentSelectionOn:(NSMutableArray*)teams {
    NSMutableArray* parents = [[NSMutableArray alloc] init];
    int teamCount = (int)[teams count];
    
    for(int j = 0; j < 2; j++) {
        Team *candidateOne = [teams objectAtIndex:randomInt(teamCount)],
        *candidateTwo = [teams objectAtIndex:randomInt(teamCount)];
        //Make sure candidates are distinct.
        while (([teams count] > 1) && (candidateOne == candidateTwo)) {
            candidateTwo = [teams objectAtIndex:randomInt(teamCount)];
        }
        //parents[j] gets whichever candidate collected more tags
        if([candidateOne tagsCollected] > [candidateTwo tagsCollected]) {
            [parents addObject:candidateOne];
        }
        else {
            [parents addObject:candidateTwo];
=======
-(NSMutableArray*)tournamentSelectionOn:(NSMutableArray*)population {
    NSMutableArray* parents = [[NSMutableArray alloc] init];
    int populationSize = (int)[population count];

    if (populationSize > 1) {
        for(int j = 0; j < 2; j++) {
            id candidateOne = [population objectAtIndex:randomInt(populationSize)],
            candidateTwo = [population objectAtIndex:randomInt(populationSize)];
            //Make sure candidates are distinct.
            while (candidateOne == candidateTwo) {
                candidateTwo = [population objectAtIndex:randomInt(populationSize)];
            }
            //parents[j] gets whichever candidate collected more tags
            if([candidateOne fitness] > [candidateTwo fitness]) {
                [parents addObject:candidateOne];
            }
            else {
                [parents addObject:candidateTwo];
            }
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
        }
    }
    
    return parents;
}

<<<<<<< HEAD
=======
/*
 * Rank-based elitist selection
 */
-(NSMutableArray*)rankBasedElististSelectionOn:(NSMutableArray*)population withCutoff:(float)cutoff {
    NSMutableArray* parents = [[NSMutableArray alloc] init];
    int populationSize = (int)[population count];
    
    int r = randomIntRange(trunc(cutoff * populationSize), populationSize);
    id parent = [population objectAtIndex:r];
    [parents addObject:parent];
    
    return parents;
}

>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09

/*
 * Crossover via independent asssortment
 */
<<<<<<< HEAD
-(void) independentAssortmentCrossoverFromParents:(NSMutableArray*)parents toChild:(Team*)child withFirstParentBias:(float)bias {
=======
-(void)independentAssortmentCrossoverFromParents:(NSMutableArray*)parents toChild:(id)child withFirstParentBias:(float)bias {
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
    NSMutableDictionary* parameters = [child getParameters];
    
    for(NSString* key in [parameters allKeys]) {
        //Booleans can be treated as integers in C, so a boolean is 0 or 1
        //parentNum will be either 0 or 1 for one of the 2 parents
        int parentNum = (randomFloat(1.0) > bias);
        //Getting the parameter specified by key of parent parentNum.
<<<<<<< HEAD
        Team* p = [parents objectAtIndex:parentNum];
=======
        id p = [parents objectAtIndex:parentNum];
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
        id param = [[p getParameters] objectForKey:key];
        //Setting the child's parameter
        [parameters setObject:param forKey:key];
    }
    
    [child setParameters:parameters];
}


/*
 * Uniform crossover
 */
<<<<<<< HEAD
-(void) uniformCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child {
=======
-(void) uniformCrossoverFromParents:(NSMutableArray *)parents toChild:(id)child {
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
    NSMutableDictionary* parameters = [child getParameters];
    int parentNum;
    for(NSString* key in [parameters allKeys]) {
        //parentNum will be either 0 or 1 to decide which of the 2 parents
        //to copy each parameter from.
        parentNum = randomInt(2);
        //Getting the parameter specified by key of parent parentNum.
<<<<<<< HEAD
        Team* p = [parents objectAtIndex:parentNum];
=======
        id p = [parents objectAtIndex:parentNum];
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
        id param = [[p getParameters] objectForKey:key];
        //Setting the child's parameter
        [parameters setObject:param forKey:key];
    }
    
    [child setParameters:parameters];
}

/*
 * One-point crossover
 */
<<<<<<< HEAD
-(void) onePointCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child {
=======
-(void)onePointCrossoverFromParents:(NSMutableArray *)parents toChild:(id)child {
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
    NSMutableDictionary* parameters = [child getParameters];
    
    //Select a point for one-point crossover
    int crossPoint = randomInt((int)[parameters count] + 1);
    int i = 0;
    for(NSString* key in [parameters allKeys]) {
        [parameters setObject:[[parents[(crossPoint > i)] getParameters] objectForKey:key] forKey:key];
        i++;
    }
    [child setParameters:parameters];
}


/*
 * Two-point crossover
 */
<<<<<<< HEAD
-(void) twoPointCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child {
=======
-(void)twoPointCrossoverFromParents:(NSMutableArray *)parents toChild:(id)child {
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
    NSMutableDictionary* parameters = [child getParameters];
    
    //Select two points for two-point crossover
    int crossPoint1 = randomInt((int)[parameters count] + 1);
    int crossPoint2 = randomInt((int)[parameters count] + 1);
    
    //Ensure that point 1 is less than point 2.
    //Allow the points to be equal in which case this is just one point crossover.
    if(crossPoint1 > crossPoint2) {
        int temp = crossPoint2;
        crossPoint2 = crossPoint1;
        crossPoint1 = temp;
    }
    
    int i = 0;
    for(NSString* key in [parameters allKeys]) {
        if(i < crossPoint1) {
            [parameters setObject:[[parents[0] getParameters] objectForKey:key] forKey:key];
        }
        else if(i < crossPoint2) {
            [parameters setObject:[[parents[1] getParameters] objectForKey:key] forKey:key];
        }
        else {
            [parameters setObject:[[parents[0] getParameters] objectForKey:key] forKey:key];
        }
        i++;
    }
    
    [child setParameters:parameters];
}


/*
 * Gaussian mutation with variance based on value to be mutated.
 */
<<<<<<< HEAD
-(void) valueDependentVarianceMutationForParameter:(NSNumber **)parameter atGeneration:(int)generation {
    //calculate the variance. Larger values will have more variance!
    float sigma = fabs([*parameter floatValue]) * .05;    
    //add a random amount sampled from a normal distribution centered at zero.
    float mutatedValue = [*parameter floatValue] + randomNormal(0., sigma);
    if(mutatedValue < 0.0) {
        *parameter = [NSNumber numberWithFloat:0.];
    }
    else {
        *parameter = [NSNumber numberWithFloat:mutatedValue];
    }
=======
-(float)valueDependentVarianceMutationForParameter:(float)parameter {
    //calculate the variance. Larger values will have more variance!
    float sigma = fabs(parameter) * .05;
    //add a random amount sampled from a normal distribution centered at zero.
    float mutatedValue = parameter + randomNormal(0., sigma);
    
    return (mutatedValue < 0. ? 0. : mutatedValue);
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
}


/*
 * Gaussian mutation with variance decreasing uniformly from 
 * maxVariance to minVariance based on the fraction of generations elasped.
 */
<<<<<<< HEAD
-(void) decreasingVarianceMutationForParameter:(NSNumber **)parameter atGeneration:(int)generation :(int)maxGenerations :(float)maxVariance :(float)minVariance{
=======
-(float)decreasingVarianceMutationForParameter:(float)parameter atGeneration:(int)generation :(int)maxGenerations :(float)maxVariance :(float)minVariance{
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
    //calculate the variance using the point-slope form of the line equation.
    float slope = (maxVariance - minVariance) / (float)maxGenerations;
    float sigma = (slope*(float)generation) + maxVariance;
    //add a random amount sampled from a normal distribution centered at zero.
<<<<<<< HEAD
    float mutatedValue = [*parameter floatValue] + randomNormal(0., sigma);
    if(mutatedValue < 0.0) {
        *parameter = [NSNumber numberWithFloat:0.];
    }
    else {
        *parameter = [NSNumber numberWithFloat:mutatedValue];
    }
=======
    float mutatedValue = parameter + randomNormal(0., sigma);
    
    return (mutatedValue < 0. ? 0. : mutatedValue);
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
}


/*
 * Gaussian mutation with fixed variance.
 */
<<<<<<< HEAD
-(void) fixedVarianceMutationForParameter:(NSNumber **)parameter :(float)sigma{
    //add a random amount sampled from a normal distribution centered at zero.
    float mutatedValue = [*parameter floatValue] + randomNormal(0., sigma);
    if(mutatedValue < 0.0) {
        *parameter = [NSNumber numberWithFloat:0.];
    }
    else {
        *parameter = [NSNumber numberWithFloat:mutatedValue];
    }
=======
-(float)fixedVarianceMutationForParameter:(float)parameter :(float)sigma{
    //add a random amount sampled from a normal distribution centered at zero.
    float mutatedValue = parameter + randomNormal(0., sigma);
    
    return (mutatedValue < 0. ? 0. : mutatedValue);
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
}


/*
<<<<<<< HEAD
 * 'Breeds' and mutates teams.
=======
 * 'Breeds' and mutates a popuation.
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
 * There is a slight tradeoff for readability at the cost of efficiency here,
 * which has to do with the use of (and enumeration over) dictionaries.
 * generation is passed because some mutations change as search progresses.
 */
<<<<<<< HEAD
-(void) breedTeams:(NSMutableArray*)teams AtGeneration:(int)generation :(int)maxGenerations{
    int teamCount = (int)[teams count];
    
    if (teamCount) {
        //Elitism
        //Allocate a whole new individual.
        Team* bestIndividual = [[Team alloc] init];
        if(elitism) {
            //Get the best individual in the population and make sure it is preserved in the next generation.
            int mostTags = -1;
            for(Team *t in teams) {
                //If this individual is better than the best so far, then update the elite individual.
                if([t tagsCollected] > mostTags) {
                    mostTags = [t tagsCollected];
                    //Copy the best individual's parameters.
                    [bestIndividual setParameters:[t getParameters]];
                }
            }
        }
        
        //Create new population of children
        Team* children[teamCount];
        
        for(int i = 0; i < teamCount; i++) {
            children[i] = [[Team alloc] init];
            Team* child = children[i];
            
            //Selection
            NSMutableArray* parents = [self tournamentSelectionOn:teams];
=======
-(void) breedPopulation:(NSMutableArray*)population AtGeneration:(int)generation andMaxGeneration:(int)maxGenerations{
    int populationSize = (int)[population count];
    Class populationClass = [[population objectAtIndex:0] class];
    
    if ((populationSize > 1) && [populationClass conformsToProtocol:@protocol(Archivable)]) {
        //Sort array smallest to largest
        population = (NSMutableArray*)[population sortedArrayUsingComparator:^NSComparisonResult(id objA, id objB) {
            NSNumber* fitnessA = [NSNumber numberWithFloat:[objA fitness]];
            NSNumber* fitnessB = [NSNumber numberWithFloat:[objB fitness]];
            return [fitnessA compare:fitnessB];
        }];
        
        //Elitism
        id bestIndividual;
        if(elitism) {
            bestIndividual = [population objectAtIndex:(populationSize - 1)];
        }
        
        //Create new population of children
        NSMutableArray* children = [[NSMutableArray alloc] initWithCapacity:populationSize];
        
        for(int i = 0; i < populationSize; i++) {
            id child = [[populationClass alloc] init];
            [children addObject:child];
            
            //Selection
            NSMutableArray* parents;
            switch (selectionOperator) {
                case TournamentSelectionId:
                    parents = [self tournamentSelectionOn:population];
                    break;
                case RankBasedElitistSelectionId:
                    parents = [self rankBasedElististSelectionOn:population withCutoff:0.5];
                    break;
                default:
                    break;
            }
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
            
            //Crossover
            if(randomFloat(1.0) < crossoverRate) {
                switch (crossoverOperator){
                    case IndependentAssortmentCrossId:
                        [self independentAssortmentCrossoverFromParents:parents toChild:child withFirstParentBias:0.9];
                        break;
                    case UniformPointCrossId:
                        [self uniformCrossoverFromParents:parents toChild:child];
                        break;
                    case OnePointCrossId:
                        [self onePointCrossoverFromParents:parents toChild:child];
                        break;
                    case TwoPointCross:
                        [self twoPointCrossoverFromParents:parents toChild:child];
                        break;
                }
            }
            else {
                //Otherwise the child will just be a copy of one of the parents
<<<<<<< HEAD
                [child setParameters:[[parents objectAtIndex:0] getParameters]];
=======
                id parent = [parents objectAtIndex:randomInt((int)[parents count])];
                [child setParameters:[parent getParameters]];
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
            }
            
            //Random mutations
            NSMutableDictionary* parameters = [child getParameters];
            for(NSString* key in [parameters allKeys]) {
                if(randomFloat(1.0) < mutationRate){
<<<<<<< HEAD
                    NSNumber* parameter = [parameters objectForKey:key];
                    
                    switch (mutationOperator){
                        case ValueDependentVarMutId:
                            [self valueDependentVarianceMutationForParameter:&parameter atGeneration:generation];
                            break;
                        case DecreasingVarMutId: {
                            float maxVariance = 0.1;
                            float minVariance = 0.005;
                            [self decreasingVarianceMutationForParameter:&parameter atGeneration:generation:maxGenerations:maxVariance:minVariance];
                            }
                            break;
                        case FixedVarMutId: {
                            float sigma = 0.05;
                            [self fixedVarianceMutationForParameter:&parameter :sigma];
                            }
                            break;
=======
                    id parameter = [parameters objectForKey:key];
                    
                    float (^mutateParameter)(float) = ^float(float value) {
                        switch (mutationOperator) {
                            case ValueDependentVarMutId: {
                                return [self valueDependentVarianceMutationForParameter:value];
                            }
                            case DecreasingVarMutId: {
                                float maxVariance = 0.1;
                                float minVariance = 0.005;
                                return [self decreasingVarianceMutationForParameter:value atGeneration:generation:maxGenerations:maxVariance:minVariance];
                            }
                            case FixedVarMutId: {
                                return [self fixedVarianceMutationForParameter:value :fixedVarianceSigma];
                            }
                            default: {
                                NSLog(@"Mutation parameter undefined.");
                                return value;
                            }
                        }
                    };
                    
                    if ([parameter isKindOfClass:[NSNumber class]]) {
                        parameter = [NSNumber numberWithFloat:mutateParameter([parameter floatValue])];
                    }
                    else if ([parameter isKindOfClass:[NSValue class]]) {
                        NSPoint p = [parameter pointValue];
                        parameter = [NSValue valueWithPoint:NSMakePoint(mutateParameter(p.x), mutateParameter(p.y))];
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
                    }

                    [parameters setObject:parameter forKey:key];
                }
            }
            
<<<<<<< HEAD
            [children[i] setParameters:parameters];
        }
        
        //Set the children to be the new set of teams for the next generation.
        for(int i = 0; i < teamCount; i++) {
            Team* team = [teams objectAtIndex:i];
            [team setParameters:[children[i] getParameters]];
=======
            [child setParameters:parameters];
        }
        
        //Set the children to be the new population for the next generation.
        for(int i = 0; i < populationSize; i++) {
            id individual = [population objectAtIndex:i];
            [individual setParameters:[[children objectAtIndex:i] getParameters]];
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
        }
        
        //If we are using elitism then the first child is replaced by the best individual from the previous generation.
        if(elitism) {
<<<<<<< HEAD
            Team* team = [teams objectAtIndex:0];
            [team setParameters:[bestIndividual getParameters]];
=======
            id individual = [population objectAtIndex:0];
            [individual setParameters:[bestIndividual getParameters]];
>>>>>>> 8c44715e7fbcb776c3f7855c6aa17bad1cc56e09
        }
    }
}

@end
