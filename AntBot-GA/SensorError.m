#import "SensorError.h"
#include "Util.h"

@implementation SensorError

@synthesize localizationSlope, localizationIntercept;
@synthesize travelingSlope, travelingIntercept;
@synthesize tagDetectionProbability, neighborDetectionProbability;
@synthesize fitness;

-(id)initRandom {
    if (self = [super init]) {
        localizationSlope = NSMakePoint(randomFloatRange(-1, 1), randomFloatRange(-1, 1));
        localizationIntercept = NSMakePoint(randomFloatRange(0, 500), randomFloatRange(0, 500));
        travelingSlope = NSMakePoint(randomFloatRange(-1, 1), randomFloatRange(-1, 1));
        travelingIntercept = NSMakePoint(randomFloatRange(0, 500), randomFloatRange(0, 500));
        tagDetectionProbability = randomFloat(1);
        neighborDetectionProbability = randomFloat(1);
    }
    return self;
}

/*
 * Introduces error into recorded tag position - Simulates localization error in real robot
 */
-(NSPoint)perturbTagPosition:(NSPoint)position withGridSize:(NSSize)size andGridCenter:(NSPoint)center {
    float distanceFromCenter = pointDistance(position.x, position.y, center.x, center.y);
    NSPoint standardDeviation = NSMakePoint(MAX([self localizationSlope].x * distanceFromCenter + ([self localizationIntercept].x / 8), 0),
                                            MAX([self localizationSlope].y * distanceFromCenter + ([self localizationIntercept].y / 8), 0));
    position.x = roundf(clip(randomNormal(position.x, standardDeviation.x), 0, size.width - 1));
    position.y = roundf(clip(randomNormal(position.y, standardDeviation.y), 0, size.height - 1));
    
    return position;
}

/*
 * Introduces error into target position - Simulates traveling error in real robot
 */
-(NSPoint)perturbTargetPosition:(NSPoint)position withGridSize:(NSSize)size andGridCenter:(NSPoint)center {
    float distanceFromCenter = pointDistance(position.x, position.y, center.x, center.y);
    NSPoint standardDeviation = NSMakePoint(MAX([self travelingSlope].x * distanceFromCenter + ([self travelingIntercept].x / 8.), 0),
                                            MAX([self travelingSlope].y * distanceFromCenter + ([self travelingIntercept].y / 8.), 0));
    position.x = roundf(clip(randomNormal(position.x, standardDeviation.x), 0, size.width - 1));
    position.y = roundf(clip(randomNormal(position.y, standardDeviation.y), 0, size.height - 1));
    
    return position;
}

/*
 * Introduces error into tag reading - Simulates probability of missing tag
 */
-(BOOL)detectTag {
    return (randomFloat(1.) <= [self tagDetectionProbability]);
}

/*
 * Introduces error into neighbor reading = Simulates probability of missing neighboring tags
 */
-(BOOL)detectNeighbor {
    return (randomFloat(1.) <= [self neighborDetectionProbability]);
}


#pragma Archivable methods

-(NSMutableDictionary *)getParameters {
    return [[NSMutableDictionary alloc] initWithObjects:
            [NSArray arrayWithObjects:
             [NSValue valueWithPoint:localizationSlope],
             [NSValue valueWithPoint:localizationIntercept],
             [NSValue valueWithPoint:travelingSlope],
             [NSValue valueWithPoint:travelingIntercept],
             [NSNumber numberWithFloat:tagDetectionProbability],
             [NSNumber numberWithFloat:neighborDetectionProbability], nil] forKeys:
            [NSArray arrayWithObjects:
             @"localizationSlope",
             @"localizationIntercept",
             @"travelingSlope",
             @"travelingIntercept",
             @"tagDetectionProbability",
             @"neighborDetectionProbability",nil]];
}

-(void)setParameters:(NSMutableDictionary *)parameters {
    localizationSlope = [[parameters objectForKey:@"localizationSlope"] pointValue];
    localizationIntercept = [[parameters objectForKey:@"localizationIntercept"] pointValue];
    
    travelingSlope = [[parameters objectForKey:@"travelingSlope"] pointValue];
    travelingIntercept = [[parameters objectForKey:@"travelingIntercept"] pointValue];
    
    tagDetectionProbability = [[parameters objectForKey:@"tagDetectionProbability"] floatValue];
    neighborDetectionProbability = [[parameters objectForKey:@"neighborDetectionProbability"] floatValue];
}

@end
