#import "Team.h"

@implementation Team

@synthesize travelGiveUpProbability, searchGiveUpProbability;
@synthesize uninformedSearchCorrelation, informedSearchCorrelationDecayRate, stepSizeVariation;
@synthesize pheromoneDecayRate, pheromoneLayingRate, siteFidelityRate;//, decompositionAllocProbability;
@synthesize fitness, explorePhase;

//////////////POWER STUFF///////////////
//@synthesize powerReturnShift, powerReturnSigma, chargeActiveSigma;
@synthesize batteryReturnVal;
@synthesize batteryLeaveVal;
@synthesize casualties;
//////////////POWER STUFF///////////////

-(id) initRandom {
    if(self = [super init]) {
        pheromoneDecayRate = randomExponential(10.0);
        
        travelGiveUpProbability = randomFloat(1.0);
        searchGiveUpProbability = randomFloat(1.0);
//        decompositionAllocProbability = randomFloat(1.0);
        
        uninformedSearchCorrelation = randomFloat(2 * M_2PI);
        informedSearchCorrelationDecayRate = randomExponential(5.0);
        stepSizeVariation = randomExponential(1.0);
        
        pheromoneLayingRate = randomFloat(20.);
        siteFidelityRate = randomFloat(20.);
        
        //////////////POWER STUFF///////////////
        batteryReturnVal = randomFloat(1.0);
        batteryLeaveVal = randomFloat(1.0);
        //////////////POWER STUFF///////////////
        
        
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
    return [[NSMutableDictionary alloc] initWithObjects:
            [NSArray arrayWithObjects:
             [NSNumber numberWithFloat:pheromoneDecayRate],
             [NSNumber numberWithFloat:travelGiveUpProbability],
             [NSNumber numberWithFloat:searchGiveUpProbability],
//             [NSNumber numberWithFloat:decompositionAllocProbability],
             [NSNumber numberWithFloat:uninformedSearchCorrelation],
             [NSNumber numberWithFloat:informedSearchCorrelationDecayRate],
             [NSNumber numberWithFloat:stepSizeVariation],
             [NSNumber numberWithFloat:pheromoneLayingRate],
             [NSNumber numberWithFloat:siteFidelityRate],
//             [NSNumber numberWithFloat:powerReturnShift],
//             [NSNumber numberWithFloat:powerReturnSigma],
//             [NSNumber numberWithFloat:chargeActiveSigma],
             [NSNumber numberWithFloat:batteryReturnVal],
             [NSNumber numberWithFloat:batteryLeaveVal],
             nil] forKeys:
            [NSArray arrayWithObjects:
             @"pheromoneDecayRate",
             @"travelGiveUpProbability",
             @"searchGiveUpProbability",
//             @"decompositionAllocProbability",
             @"uninformedSearchCorrelation",
             @"informedSearchCorrelationDecayRate",
             @"stepSizeVariation",
             @"pheromoneLayingRate",
             @"siteFidelityRate",
//             @"powerReturnShift",
//             @"powerReturnSigma",
//             @"chargeActiveSigma",
             @"batteryReturnVal",
             @"batteryLeaveVal",
             nil]];
}

-(void) setParameters:(NSDictionary *)parameters {
    pheromoneDecayRate = [[parameters objectForKey:@"pheromoneDecayRate"] floatValue];
    
    travelGiveUpProbability = [[parameters objectForKey:@"travelGiveUpProbability"] floatValue];
    searchGiveUpProbability = [[parameters objectForKey:@"searchGiveUpProbability"] floatValue];
//    decompositionAllocProbability = [[parameters objectForKey:@"decompositionAllocProbability"] floatValue];
    
    uninformedSearchCorrelation = [[parameters objectForKey:@"uninformedSearchCorrelation"] floatValue];
    informedSearchCorrelationDecayRate = [[parameters objectForKey:@"informedSearchCorrelationDecayRate"] floatValue];
    stepSizeVariation = [[parameters objectForKey:@"stepSizeVariation"] floatValue];
    
    pheromoneLayingRate = [[parameters objectForKey:@"pheromoneLayingRate"] floatValue];
    siteFidelityRate = [[parameters objectForKey:@"siteFidelityRate"] floatValue];
    
//    powerReturnShift = [[parameters objectForKey:@"powerReturnShift"] floatValue];
//    powerReturnSigma = [[parameters objectForKey:@"powerReturnSigma"] floatValue];
//    chargeActiveSigma = [[parameters objectForKey:@"chargeActiveSigma"] floatValue];
    batteryReturnVal = [[parameters objectForKey:@"batteryReturnVal"] floatValue];
    batteryLeaveVal = [[parameters objectForKey:@"batteryLeaveVal"] floatValue];
}

-(void) writeParametersToFile:(NSString *)file {
    [Utilities appendText:[NSString stringWithFormat:@"%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
                           [self pheromoneDecayRate],
                           [self travelGiveUpProbability],
                           [self searchGiveUpProbability],
//                           [self decompositionAllocProbability],
                           [self uninformedSearchCorrelation],
                           [self informedSearchCorrelationDecayRate],
                           [self stepSizeVariation],
                           [self pheromoneLayingRate],
                           [self siteFidelityRate],
//                           [self powerReturnShift],
//                           [self powerReturnSigma],
//                           [self chargeActiveSigma],
                           [self batteryReturnVal],
                           [self batteryLeaveVal],
                           [self casualties],
                           [self fitness]]
                   toFile:file];
}


+(void) writeParameterNamesToFile:(NSString *)file {
    NSString* headers = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                         @"pheromoneDecayRate",
                         @"travelGiveUpProbability",
                         @"searchGiveUpProbability",
//                         @"decompositionAllocProbability",
                         @"uninformedSearchCorrelation",
                         @"informedSearchCorrelationDecayRate",
                         @"stepSizeVariation",
                         @"pheromoneLayingRate",
                         @"siteFidelityRate",
//                         @"powerReturnShift",
//                         @"powerReturnSigma",
//                         @"chargeActiveSigma",
                         @"batteryReturnVal",
                         @"batteryLeaveVal",
                         @"casualties",
                         @"fitness"];
    [Utilities appendText:headers toFile :file];
}

@end
