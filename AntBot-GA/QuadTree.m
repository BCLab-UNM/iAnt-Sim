#import "QuadTree.h"

@implementation QuadTree

@synthesize origin;
@synthesize width, height;
@synthesize percentExplored;
@synthesize dirty;
@synthesize cells;
@synthesize parent;
@synthesize children;

-(id) initWithHeight:(int)_height width:(int)_width origin:(NSPoint)_origin cells:(Array2D*)_cells andParent:(QuadTree *)_parent{
    if(self = [super init]) {
        height = _height;
        width = _width;
        origin = _origin;
        cells = _cells;
        parent = _parent;
        dirty = NO;
        percentExplored = 2.0;
        children = [[NSMutableArray alloc] init];
    }
    return self;
}

@end
