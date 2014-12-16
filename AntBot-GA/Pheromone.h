#import <Foundation/Foundation.h>
#import "Utilities.h"

@interface Pheromone : NSObject {}

-(id) initWithPath:(NSMutableArray*)_path weight:(float)_n decayRate:(float)_decayRate andUpdatedTick:(int)_updatedTick;
+(NSMutableArray*) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick;

@property (nonatomic) NSMutableArray* path;
@property (nonatomic) float weight;
@property (nonatomic) float decayRate;
@property (nonatomic) int updatedTick;

@end