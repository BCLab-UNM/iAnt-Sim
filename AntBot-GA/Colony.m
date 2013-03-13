#import "Colony.h"
#include "Util.h"

@implementation Colony

@synthesize trailDropRate, walkDropRate, searchGiveupRate;
@synthesize dirDevConst, dirDevCoeff, dirTimePow;
@synthesize decayRate, densityThreshold, densityConstant, densityPatchThreshold, densityPatchConstant, densityInfluenceThreshold, densityInfluenceConstant;
@synthesize tagsCollected;

-(id) init {
    if(self = [super init]) {
        decayRate = randomFloat(1.);
        walkDropRate = randomFloat(1.);
        searchGiveupRate = randomFloat(1.);
        trailDropRate = randomFloat(1.);
        dirDevConst = randomFloat(3.14);
        dirDevCoeff = randomFloat(3.14);
        dirTimePow = randomFloat(5.);
        
        densityThreshold = randomFloat(8.0);
        densityConstant = -1 + randomFloat(2.0);
        
        densityPatchThreshold = randomFloat(8.0);
        densityPatchConstant = -1 + randomFloat(2.0);
        
        densityInfluenceThreshold = randomFloat(8.0);
        densityInfluenceConstant = -1 + randomFloat(2.0);
    }
    return self;
}

-(NSMutableDictionary*) getParameters {
    return [[NSMutableDictionary alloc] initWithObjects:
            [NSArray arrayWithObjects:
             [NSNumber numberWithFloat:decayRate],
             [NSNumber numberWithFloat:walkDropRate],
             [NSNumber numberWithFloat:searchGiveupRate],
             [NSNumber numberWithFloat:trailDropRate],
             [NSNumber numberWithFloat:dirDevConst],
             [NSNumber numberWithFloat:dirDevCoeff],
             [NSNumber numberWithFloat:dirTimePow],
             [NSNumber numberWithFloat:densityThreshold],
             [NSNumber numberWithFloat:densityConstant],
             [NSNumber numberWithFloat:densityPatchThreshold],
             [NSNumber numberWithFloat:densityPatchConstant],
             [NSNumber numberWithFloat:densityInfluenceThreshold],
             [NSNumber numberWithFloat:densityInfluenceConstant], nil] forKeys:
            [NSArray arrayWithObjects:
             @"decayRate",
             @"walkDropRate",
             @"searchGiveupRate",
             @"trailDropRate",
             @"dirDevConst",
             @"dirDevCoeff",
             @"dirTimePow",
             @"densityThreshold",
             @"densityConstant",
             @"densityPatchThreshold",
             @"densityPatchConstant",
             @"densityInfluenceThreshold",
             @"densityInfluenceConstant", nil]];
}

-(void) setParameters:(NSMutableDictionary *)parameters {
    decayRate = [[parameters objectForKey:@"decayRate"] floatValue];
    walkDropRate = [[parameters objectForKey:@"walkDropRate"] floatValue];
    searchGiveupRate = [[parameters objectForKey:@"searchGiveupRate"] floatValue];
    trailDropRate = [[parameters objectForKey:@"trailDropRate"] floatValue];
    
    dirDevConst = [[parameters objectForKey:@"dirDevConst"] floatValue];
    dirDevCoeff = [[parameters objectForKey:@"dirDevCoeff"] floatValue];
    dirTimePow = [[parameters objectForKey:@"dirTimePow"] floatValue];
    
    densityThreshold = [[parameters objectForKey:@"densityThreshold"] floatValue];
    densityConstant = [[parameters objectForKey:@"densityConstant"] floatValue];
    
    densityPatchThreshold = [[parameters objectForKey:@"densityPatchThreshold"] floatValue];
    densityPatchConstant = [[parameters objectForKey:@"densityPatchConstant"] floatValue];
    
    densityInfluenceThreshold = [[parameters objectForKey:@"densityInfluenceThreshold"] floatValue];
    densityInfluenceConstant = [[parameters objectForKey:@"densityInfluenceConstant"] floatValue];
}

@end
