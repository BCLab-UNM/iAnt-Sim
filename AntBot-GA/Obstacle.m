#import "Obstacle.h"

@implementation Obstacle

@synthesize position;

-(id) initWithX:(int)_x andY:(int)_y {
    if(self = [super init]) {
        position = NSMakePoint(_x, _y);

    }
    return self;
}

#pragma NSCopying methods

-(id) copyWithZone:(NSZone *)zone {
    Obstacle *obstacleCopy = [[[self class] allocWithZone:zone] init];
    if(obstacleCopy) {
        [obstacleCopy setPosition:position];
    }
    return obstacleCopy;
}

@end
