#import "QuadTree.h"

@implementation QuadTree

@synthesize shape, area;
@synthesize percentExplored;
@synthesize needsDecomposition;

-(id) initWithRect:(NSRect)rect{
    if(self = [super init]) {
        shape = rect;
        area = rect.size.height * rect.size.width;
        needsDecomposition = YES;
        percentExplored = 0.;
    }
    return self;
}

@end
