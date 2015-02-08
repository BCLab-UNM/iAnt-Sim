#import "Tag.h"

@implementation Tag

@synthesize position;
@synthesize pickedUp, discovered;
@synthesize cluster;

-(id) initWithX:(int)_x Y:(int)_y andCluster:(int)_cluster {
    if(self = [super init]) {
        position = NSMakePoint(_x, _y);
        pickedUp = NO;
        discovered = NO;
        cluster = _cluster;
    }
    return self;
}

#pragma NSCopying methods

-(id) copyWithZone:(NSZone *)zone {
    Tag *tagCopy = [[[self class] allocWithZone:zone] init];
    if(tagCopy) {
        [tagCopy setPosition:position];
        [tagCopy setPickedUp:pickedUp];
        [tagCopy setDiscovered:discovered];
    }
    return tagCopy;
}

@end