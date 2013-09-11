#import "Tag.h"

@implementation Tag

@synthesize position;
@synthesize pickedUp, discovered;

-(id) initWithX:(int)_x andY:(int)_y {
    if(self = [super init]) {
        position = NSMakePoint(_x, _y);
        pickedUp = NO;
        discovered = NO;
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