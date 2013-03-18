#import "Colony.h"
#include "Util.h"

@implementation Colony

@synthesize pheromoneGiveUpProbability, travelGiveUpProbability, searchGiveUpProbability;
@synthesize uninformedSearchCorrelation, informedSearchCorrelationDecayRate;
@synthesize pheromoneDecayRate, pheromoneLayingRate, siteFidelityRate, pheromoneFollowingRate;
@synthesize tagsCollected;

-(id) init {
    if(self = [super init]) {
        pheromoneDecayRate = randomFloat(7.);
        
        travelGiveUpProbability = randomFloat(1.);
        searchGiveUpProbability = randomFloat(1.);
        pheromoneGiveUpProbability = randomFloat(1.);
        
        uninformedSearchCorrelation = randomFloat(2*M_2PI);
        informedSearchCorrelationDecayRate = randomFloat(7.);
        
        pheromoneLayingRate = randomFloat(10.0);
        siteFidelityRate = randomFloat(10.0);
        pheromoneFollowingRate = randomFloat(10.0);
    }
    return self;
}

-(NSMutableDictionary*) getParameters {
    return [[NSMutableDictionary alloc] initWithObjects:
            [NSArray arrayWithObjects:
             [NSNumber numberWithFloat:pheromoneDecayRate],
             [NSNumber numberWithFloat:travelGiveUpProbability],
             [NSNumber numberWithFloat:searchGiveUpProbability],
             [NSNumber numberWithFloat:pheromoneGiveUpProbability],
             [NSNumber numberWithFloat:uninformedSearchCorrelation],
             [NSNumber numberWithFloat:informedSearchCorrelationDecayRate],
             [NSNumber numberWithFloat:pheromoneLayingRate],
             [NSNumber numberWithFloat:siteFidelityRate],
             [NSNumber numberWithFloat:pheromoneFollowingRate],nil] forKeys:
            [NSArray arrayWithObjects:
             @"pheromoneDecayRate",
             @"travelGiveUpProbability",
             @"searchGiveUpProbability",
             @"pheromoneGiveUpProbability",
             @"uninformedSearchCorrelation",
             @"informedSearchCorrelationDecayRate",
             @"pheromoneLayingRate",
             @"siteFidelityRate",
             @"pheromoneFollowingRate",nil]];
}

-(void) setParameters:(NSMutableDictionary *)parameters {
    pheromoneDecayRate = [[parameters objectForKey:@"pheromoneDecayRate"] floatValue];
    
    travelGiveUpProbability = [[parameters objectForKey:@"travelGiveUpProbability"] floatValue];
    searchGiveUpProbability = [[parameters objectForKey:@"searchGiveUpProbability"] floatValue];
    pheromoneGiveUpProbability = [[parameters objectForKey:@"pheromoneGiveUpProbability"] floatValue];
    
    uninformedSearchCorrelation = [[parameters objectForKey:@"uninformedSearchCorrelation"] floatValue];
    informedSearchCorrelationDecayRate = [[parameters objectForKey:@"informedSearchCorrelationDecayRate"] floatValue];
    
    pheromoneLayingRate = [[parameters objectForKey:@"pheromoneLayingRate"] floatValue];
    siteFidelityRate = [[parameters objectForKey:@"siteFidelityRate"] floatValue];
    pheromoneFollowingRate = [[parameters objectForKey:@"pheromoneFollowingRate"] floatValue];
}

@end
