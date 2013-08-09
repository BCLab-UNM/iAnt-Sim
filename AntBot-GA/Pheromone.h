#import <Foundation/Foundation.h>

@interface Pheromone : NSObject {}

-(id) initWithPosition:(NSPoint)_position weight:(float)_n andUpdatedTick:(int)_updated;

@property (nonatomic) NSPoint position;
@property (nonatomic) float n;
@property (nonatomic) int updated;

@end