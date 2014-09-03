#import "Team.h"

@implementation Team

@synthesize travelGiveUpProbability, searchGiveUpProbability;
@synthesize uninformedSearchCorrelation, informedSearchCorrelationDecayRate;
@synthesize pheromoneDecayRate, pheromoneLayingRate, siteFidelityRate;
@synthesize fitness, timeToCompleteCollection, explorePhase;

-(id) initRandom {
    if(self = [super init]) {
        travelGiveUpProbability = randomFloat(1.0);
        searchGiveUpProbability = randomFloat(1.0);
        
        uninformedSearchCorrelation = randomFloat(2 * M_2PI);
        informedSearchCorrelationDecayRate = randomExponential(5.0);
        
        pheromoneDecayRate = randomExponential(10.0);
        pheromoneLayingRate = randomFloat(20.);
        siteFidelityRate = randomFloat(20.);
    }
    return self;
}

-(id) initWithFile:(NSString *)filePath {
    if (self = [super init]) {
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        if (!parameters) {
            NSLog(@"Error reading file.");
        }
        else {
            [self setParameters:parameters];
        }
    }
    return self;
}


#pragma Archivable methods

-(NSMutableDictionary*) getParameters {
    return [@{@"travelGiveUpProbability" : @(travelGiveUpProbability),
              @"searchGiveUpProbability" : @(searchGiveUpProbability),
              @"uninformedSearchCorrelation" : @(uninformedSearchCorrelation),
              @"informedSearchCorrelationDecayRate" : @(informedSearchCorrelationDecayRate),
              @"pheromoneDecayRate" : @(pheromoneDecayRate),
              @"pheromoneLayingRate" : @(pheromoneLayingRate),
              @"siteFidelityRate" : @(siteFidelityRate)} mutableCopy];
}

-(void) setParameters:(NSDictionary *)parameters {
    travelGiveUpProbability = [[parameters objectForKey:@"travelGiveUpProbability"] floatValue];
    searchGiveUpProbability = [[parameters objectForKey:@"searchGiveUpProbability"] floatValue];
    uninformedSearchCorrelation = [[parameters objectForKey:@"uninformedSearchCorrelation"] floatValue];
    informedSearchCorrelationDecayRate = [[parameters objectForKey:@"informedSearchCorrelationDecayRate"] floatValue];
    pheromoneDecayRate = [[parameters objectForKey:@"pheromoneDecayRate"] floatValue];
    pheromoneLayingRate = [[parameters objectForKey:@"pheromoneLayingRate"] floatValue];
    siteFidelityRate = [[parameters objectForKey:@"siteFidelityRate"] floatValue];
}

-(void) writeParametersToFile:(NSString *)file {
    [Utilities appendText:[NSString stringWithFormat:@"%f,%f,%f,%f,%f,%f,%f,%f\n",
                           [self pheromoneDecayRate],
                           [self travelGiveUpProbability],
                           [self searchGiveUpProbability],
                           [self uninformedSearchCorrelation],
                           [self informedSearchCorrelationDecayRate],
                           [self pheromoneLayingRate],
                           [self siteFidelityRate],
                           [self fitness]]
                   toFile:file];
}


+(void) writeParameterNamesToFile:(NSString *)file {
    NSString* headers =
    @"travelGiveUpProbability,"
    @"searchGiveUpProbability,"
    @"uninformedSearchCorrelation,"
    @"informedSearchCorrelationDecayRate,"
    @"pheromoneDecayRate,"
    @"pheromoneLayingRate,"
    @"siteFidelityRate,"
    @"fitness\n";
    
    [Utilities appendText:headers toFile :file];
}

@end
