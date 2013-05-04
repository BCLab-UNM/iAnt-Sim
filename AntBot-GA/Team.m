#import "Team.h"
#include "Util.h"

@implementation Team

@synthesize travelGiveUpProbability, searchGiveUpProbability;
@synthesize uninformedSearchCorrelation, informedSearchCorrelationDecayRate, stepSizeVariation;
@synthesize pheromoneDecayRate, pheromoneLayingRate, siteFidelityRate, pheromoneFollowingRate;
@synthesize tagsCollected;

-(id) initRandom {
    if(self = [super init]) {
        pheromoneDecayRate = randomExponential(10.0);
        
        travelGiveUpProbability = randomFloat(1.0);
        searchGiveUpProbability = randomFloat(1.0);
        
        uninformedSearchCorrelation = randomFloat(2*M_2PI);
        informedSearchCorrelationDecayRate = randomExponential(5.0);
        stepSizeVariation = randomExponential(1.0);
        
        pheromoneLayingRate = randomExponential(1.0);
        siteFidelityRate = randomExponential(1.0);
        pheromoneFollowingRate = randomExponential(1.0);
    }
    return self;
}

-(id) initWithSpecificFile:(NSString *)filePath {
    if (self = [super init]) {
        NSError* error;
        NSString *paramterString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        if (!paramterString) {
            NSLog(@"Error reading file.");
        }
        else {
            NSArray *parameters = [paramterString componentsSeparatedByString:@","];
            if ([parameters count] == 9) {
                NSEnumerator *parametersEnumerator = [parameters objectEnumerator];
                pheromoneDecayRate = [[parametersEnumerator nextObject] floatValue];
                
                travelGiveUpProbability = [[parametersEnumerator nextObject] floatValue];
                searchGiveUpProbability = [[parametersEnumerator nextObject] floatValue];
                
                uninformedSearchCorrelation = [[parametersEnumerator nextObject] floatValue];
                informedSearchCorrelationDecayRate = [[parametersEnumerator nextObject] floatValue];
                stepSizeVariation = [[parametersEnumerator nextObject] floatValue];
                
                pheromoneLayingRate = [[parametersEnumerator nextObject] floatValue];
                siteFidelityRate = [[parametersEnumerator nextObject] floatValue];
                pheromoneFollowingRate = [[parametersEnumerator nextObject] floatValue];
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
             [NSNumber numberWithFloat:informedSearchCorrelationDecayRate],
             [NSNumber numberWithFloat:stepSizeVariation],
             [NSNumber numberWithFloat:pheromoneLayingRate],
             [NSNumber numberWithFloat:siteFidelityRate],
             [NSNumber numberWithFloat:pheromoneFollowingRate],nil] forKeys:
            [NSArray arrayWithObjects:
             @"pheromoneDecayRate",
             @"travelGiveUpProbability",
             @"searchGiveUpProbability",
             @"uninformedSearchCorrelation",
             @"informedSearchCorrelationDecayRate",
             @"stepSizeVariation",
             @"pheromoneLayingRate",
             @"siteFidelityRate",
             @"pheromoneFollowingRate",nil]];
}

-(void) setParameters:(NSMutableDictionary *)parameters {
    pheromoneDecayRate = [[parameters objectForKey:@"pheromoneDecayRate"] floatValue];
    
    travelGiveUpProbability = [[parameters objectForKey:@"travelGiveUpProbability"] floatValue];
    searchGiveUpProbability = [[parameters objectForKey:@"searchGiveUpProbability"] floatValue];
    
    uninformedSearchCorrelation = [[parameters objectForKey:@"uninformedSearchCorrelation"] floatValue];
    informedSearchCorrelationDecayRate = [[parameters objectForKey:@"informedSearchCorrelationDecayRate"] floatValue];
    stepSizeVariation = [[parameters objectForKey:@"stepSizeVariation"] floatValue];
    
    pheromoneLayingRate = [[parameters objectForKey:@"pheromoneLayingRate"] floatValue];
    siteFidelityRate = [[parameters objectForKey:@"siteFidelityRate"] floatValue];
    pheromoneFollowingRate = [[parameters objectForKey:@"pheromoneFollowingRate"] floatValue];
}

@end
