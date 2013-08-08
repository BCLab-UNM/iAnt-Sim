#import "Team.h"
#include "Util.h"

@implementation Team

@synthesize travelGiveUpProbability, searchGiveUpProbability;
@synthesize uninformedSearchCorrelation, informedSearchCorrelation, informedGiveUpProbability, neighborSearchGiveUpProbability, stepSizeVariation;
@synthesize pheromoneDecayRate, pheromoneLayingRate, siteFidelityRate;
@synthesize tagsCollected, explorePhase;

-(id) initRandom {
    if(self = [super init]) {
        pheromoneDecayRate = randomExponential(10.0);
        
        travelGiveUpProbability = randomFloat(1.0);
        searchGiveUpProbability = randomFloat(1.0);
        
        uninformedSearchCorrelation = randomFloat(2 * M_2PI);
        informedSearchCorrelation = randomFloat(2 * M_2PI);
        informedGiveUpProbability = randomFloat(1.0);
        neighborSearchGiveUpProbability = randomFloat(1.0);
        stepSizeVariation = randomExponential(1.0);
        
        pheromoneLayingRate = randomFloat(20.);
        siteFidelityRate = randomFloat(20.);
    }
    return self;
}

-(id) initWithFile:(NSString *)filePath {
    if (self = [super init]) {
        NSError* error;
        NSString *paramterString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        if (!paramterString) {
            NSLog(@"Error reading file.");
        }
        else {
            NSArray *parameters = [paramterString componentsSeparatedByString:@","];
            if ([parameters count] == 10) {
                NSEnumerator *parametersEnumerator = [parameters objectEnumerator];
                pheromoneDecayRate = [[parametersEnumerator nextObject] floatValue];
                
                travelGiveUpProbability = [[parametersEnumerator nextObject] floatValue];
                searchGiveUpProbability = [[parametersEnumerator nextObject] floatValue];
                
                uninformedSearchCorrelation = [[parametersEnumerator nextObject] floatValue];
                informedSearchCorrelation = [[parametersEnumerator nextObject] floatValue];
                informedGiveUpProbability = [[parametersEnumerator nextObject] floatValue];
                neighborSearchGiveUpProbability = [[parametersEnumerator nextObject] floatValue];
                stepSizeVariation = [[parametersEnumerator nextObject] floatValue];
                
                pheromoneLayingRate = [[parametersEnumerator nextObject] floatValue];
                siteFidelityRate = [[parametersEnumerator nextObject] floatValue];
            }
        }
    }
    return self;
}

-(NSMutableDictionary*) getParameters {
    return [[NSMutableDictionary alloc] initWithObjects:
            [NSArray arrayWithObjects:
             [NSNumber numberWithFloat:pheromoneDecayRate],
             [NSNumber numberWithFloat:travelGiveUpProbability],
             [NSNumber numberWithFloat:searchGiveUpProbability],
             [NSNumber numberWithFloat:uninformedSearchCorrelation],
             [NSNumber numberWithFloat:informedSearchCorrelation],
             [NSNumber numberWithFloat:informedGiveUpProbability],
             [NSNumber numberWithFloat:neighborSearchGiveUpProbability],
             [NSNumber numberWithFloat:stepSizeVariation],
             [NSNumber numberWithFloat:pheromoneLayingRate],
             [NSNumber numberWithFloat:siteFidelityRate], nil] forKeys:
            [NSArray arrayWithObjects:
             @"pheromoneDecayRate",
             @"travelGiveUpProbability",
             @"searchGiveUpProbability",
             @"uninformedSearchCorrelation",
             @"informedSearchCorrelation",
             @"informedGiveUpProbability",
             @"neighborSearchGiveUpProbability",
             @"stepSizeVariation",
             @"pheromoneLayingRate",
             @"siteFidelityRate", nil]];
}

-(void) setParameters:(NSMutableDictionary *)parameters {
    pheromoneDecayRate = [[parameters objectForKey:@"pheromoneDecayRate"] floatValue];
    
    travelGiveUpProbability = [[parameters objectForKey:@"travelGiveUpProbability"] floatValue];
    searchGiveUpProbability = [[parameters objectForKey:@"searchGiveUpProbability"] floatValue];
    
    uninformedSearchCorrelation = [[parameters objectForKey:@"uninformedSearchCorrelation"] floatValue];
    informedSearchCorrelation = [[parameters objectForKey:@"informedSearchCorrelation"] floatValue];
    informedGiveUpProbability = [[parameters objectForKey:@"informedGiveUpProbability"] floatValue];
    neighborSearchGiveUpProbability = [[parameters objectForKey:@"neighborSearchGiveUpProbability"] floatValue];
    stepSizeVariation = [[parameters objectForKey:@"stepSizeVariation"] floatValue];
    
    pheromoneLayingRate = [[parameters objectForKey:@"pheromoneLayingRate"] floatValue];
    siteFidelityRate = [[parameters objectForKey:@"siteFidelityRate"] floatValue];
}

@end
