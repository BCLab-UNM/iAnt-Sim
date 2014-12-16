#import "Pheromone.h"

@implementation Pheromone

@synthesize path, weight, decayRate, updatedTick;

-(id) initWithPath:(NSMutableArray*)_path weight:(float)_weight decayRate:(float)_decayRate andUpdatedTick:(int)_updatedTick {
    if(self = [super init]) {
        path = _path;
        weight = _weight;
        decayRate = _decayRate;
        updatedTick = _updatedTick;
    }
    return self;
}

/*
 * Picks a pheromone out of the passed list based on a random number weighted on the pheromone strengths
 */
+(NSMutableArray*) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick {
    float nSum = 0.f;
    
    for(int i = 0; i < [pheromones count]; i++) {
        Pheromone* pheromone = [pheromones objectAtIndex:i];
        [pheromone setWeight:exponentialDecay([pheromone weight], tick - [pheromone updatedTick], [pheromone decayRate])];
        if([pheromone weight] < .001) {
            [pheromones removeObjectAtIndex:i];
            i--;
        }
        else {
            [pheromone setUpdatedTick:tick];
            nSum += [pheromone weight];
        }
    }
    
    float r = randomFloat(nSum);
    for(Pheromone* pheromone in pheromones) {
        if(r < [pheromone weight]) {
            return [pheromone path];
        }
        r -= [pheromone weight];
    }
    
    return nil;
}


@end