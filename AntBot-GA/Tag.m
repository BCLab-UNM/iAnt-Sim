#import "Tag.h"

@implementation Tag

@synthesize x,y;
@synthesize pickedUp;

-(id) initWithX:(int)_x andY:(int)_y {
    if(self = [super init]) {
        x = _x;
        y = _y;
        pickedUp = NO;
    }
    return self;
}
@end
