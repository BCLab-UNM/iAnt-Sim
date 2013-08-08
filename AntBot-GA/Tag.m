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

@end
