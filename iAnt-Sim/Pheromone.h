#import <Foundation/Foundation.h>
#import "Utilities.h"

@interface Pheromone : NSObject {}

-(id) initWithPosition:(NSPoint)_position weight:(float)_n decayRate:(float)_decayRate andUpdatedTick:(int)_updatedTick;
+(NSPoint) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick;

@property (nonatomic) NSPoint position;
@property (nonatomic) float weight;
@property (nonatomic) float decayRate;
@property (nonatomic) int updatedTick;

@end