#import "QuadTree.h"

@implementation QuadTree

@synthesize shape, area;
@synthesize percentExplored;
@synthesize dirty;

-(id) initWithRect:(NSRect)rect{
    if(self = [super init]) {
        shape = rect;
        area = rect.size.height * rect.size.width;
        percentExplored = 0.;
        dirty = YES;
    }
    return self;
}

@end
