#import "Tag.h"

@implementation Tag

@synthesize position;
@synthesize pickedUp, discovered;
@synthesize cluster;
@synthesize pile;

-(id) initWithX:(int)_x Y:(int)_y andCluster:(int)_cluster {
    if(self = [super init]) {
        position = NSMakePoint(_x, _y);
        pickedUp = NO;
        discovered = NO;
        cluster = _cluster;
        pile = nil;
    }
    return self;
}

-(id) initWithX:(int)_x Y:(int)_y andPile:(Pile*)_pile {
    if(self = [super init]) {
        self = [self initWithX:_x Y:_y andCluster:nil];
        pile = _pile;
    }
    return self;
}

-(void) removeFromPile {
    if (pile != nil) {
        [pile removeSpecificTag:self];
        pickedUp = YES;
    }
    pile = nil;
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