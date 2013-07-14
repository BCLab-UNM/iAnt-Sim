#import "GA.h"

@implementation GA

-(id) initWithElitism:(BOOL)_elitism crossover:(float)_crossoverRate andMutation:(float)_mutationRate {
    if (self = ([super init])) {
        elitism = _elitism;
        crossoverRate = _crossoverRate;
        mutationRate = _mutationRate;
    }
    return self;
}

/*
 * Tournament selection
 */
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
        }
    }
    
    return parents;
}


/*
 * Crossover via independent asssortment
 */
-(void) independentAssortmentCrossoverFromParents:(NSMutableArray*)parents toChild:(Team*)child withFirstParentBias:(float)bias {
    NSMutableDictionary* parameters = [child getParameters];
    
    for(NSString* key in [parameters allKeys]) {
        //Booleans can be treated as integers in C, so a boolean is 0 or 1
        //parentNum will be either 0 or 1 for one of the 2 parents
        int parentNum = (randomFloat(1.0) > bias);
        //Getting the parameter specified by key of parent parentNum.
        Team* p = [parents objectAtIndex:parentNum];
        id param = [[p getParameters] objectForKey:key];
        //Setting the child's parameter
        [parameters setObject:param forKey:key];
    }
    
    [child setParameters:parameters];
}


/*
 * Uniform crossover
 */
-(void) uniformCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child {
    NSMutableDictionary* parameters = [child getParameters];
    int parentNum;
    for(NSString* key in [parameters allKeys]) {
        //parentNum will be either 0 or 1 to decide which of the 2 parents
        //to copy each parameter from.
        parentNum = randomInt(2);
        //Getting the parameter specified by key of parent parentNum.
        Team* p = [parents objectAtIndex:parentNum];
        id param = [[p getParameters] objectForKey:key];
        //Setting the child's parameter
        [parameters setObject:param forKey:key];
    }
    
    [child setParameters:parameters];
}

/*
 * One-point crossover
 */
-(void) onePointCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child {
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
-(void) twoPointCrossoverFromParents:(NSMutableArray *)parents toChild:(Team *)child {
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
}


/*
 * Gaussian mutation with variance decreasing uniformly from 
 * maxVariance to minVariance based on the fraction of generations elasped.
 */
-(void) decreasingVarianceMutationForParameter:(NSNumber **)parameter atGeneration:(int)generation :(int)maxGenerations :(float)maxVariance :(float)minVariance{
    //calculate the variance using the point-slope form of the line equation.
    float slope = (maxVariance - minVariance) / (float)maxGenerations;
    float sigma = (slope*(float)generation) + maxVariance;
    //add a random amount sampled from a normal distribution centered at zero.
    float mutatedValue = [*parameter floatValue] + randomNormal(0., sigma);
    if(mutatedValue < 0.0) {
        *parameter = [NSNumber numberWithFloat:0.];
    }
    else {
        *parameter = [NSNumber numberWithFloat:mutatedValue];
    }
}


/*
 * Gaussian mutation with fixed variance.
 */
-(void) fixedVarianceMutationForParameter:(NSNumber **)parameter atGeneration: (float)sigma{
    //add a random amount sampled from a normal distribution centered at zero.
    float mutatedValue = [*parameter floatValue] + randomNormal(0., sigma);
    if(mutatedValue < 0.0) {
        *parameter = [NSNumber numberWithFloat:0.];
    }
    else {
        *parameter = [NSNumber numberWithFloat:mutatedValue];
    }
}


/*
 * 'Breeds' and mutates teams.
 * There is a slight tradeoff for readability at the cost of efficiency here,
 * which has to do with the use of (and enumeration over) dictionaries.
 * generation is passed because some mutations change as search progresses.
 */
-(void) breedTeams:(NSMutableArray*)teams AtGeneration:(int)generation :(int)maxGenerations{
    int teamCount = (int)[teams count];
    
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
        
        //Crossover
        if(randomFloat(1.0) < crossoverRate) {
            [self independentAssortmentCrossoverFromParents:parents toChild:child withFirstParentBias:0.9];
            //[self uniformCrossoverFromParents:parents toChild:child];
            //[self onePointCrossoverFromParents:parents toChild:child];
            //[self twoPointCrossoverFromParents:parents toChild:child];
        }
        else {
            //Otherwise the child will just be a copy of one of the parents
            [child setParameters:[[parents objectAtIndex:0] getParameters]];
        }
        
        //Random mutations
        NSMutableDictionary* parameters = [child getParameters];
        for(NSString* key in [parameters allKeys]) {
            if(randomFloat(1.0) < mutationRate){
                NSNumber* parameter = [parameters objectForKey:key];
                [self valueDependentVarianceMutationForParameter:&parameter atGeneration:generation];
                
                //float maxVariance = 0.1;
                //float minVariance = 0.005;
                //[self decreasingVarianceMutationForParameter:&parameter atGeneration:generation:maxGenerations:maxVariance:minVariance];

                //float sigma = 0.005
                //[self fixedVarianceMutationForParameter:&parameter atGeneration:generation:sigma];
                [parameters setObject:parameter forKey:key];
            }
        }
        
        [children[i] setParameters:parameters];
    }
    
    //Set the children to be the new set of teams for the next generation.
    for(int i = 0; i < teamCount; i++) {
        Team* team = [teams objectAtIndex:i];
        [team setParameters:[children[i] getParameters]];
    }
    
    //If we are using elitism then the first child is replaced by the best individual from the previous generation.
    if(elitism) {
        Team* team = [teams objectAtIndex:0];
        [team setParameters:[bestIndividual getParameters]];
    }
}

@end
