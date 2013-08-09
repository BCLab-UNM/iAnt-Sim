#import "Pheromone.h"

@implementation Pheromone

@synthesize position;
@synthesize n,updated;

-(id) initWithPosition:(NSPoint)_position weight:(float)_n andUpdatedTick:(int)_updated {
    if(self = [super init]) {
        position = _position;
        n = _n;
        updated = _updated;
    }
    return self;
}

@end