#import "Tag.h"

@implementation Tag

@synthesize x,y;
@synthesize pickedUp, discovered;

-(id) initWithX:(int)_x andY:(int)_y {
    if(self = [super init]) {
        x = _x;
        y = _y;
        pickedUp = NO;
        discovered = NO;
    }
    return self;
}
@end
