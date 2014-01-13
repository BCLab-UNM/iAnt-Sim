#import "QuadTree.h"

@implementation QuadTree

@synthesize origin;
@synthesize width, height;
@synthesize cells;

-(id) initWithHeight:(int)_height width:(int)_width origin:(NSPoint)_origin andCells:(Array2D*)_cells {
    if(self = [super init]) {
        height = _height;
        width = _width;
        origin = _origin;
        cells = _cells;
    }
    return self;
}
@end
