#import "Cell.h"

@implementation Cell

@synthesize tag;
@synthesize isClustered;
@synthesize isExplored;

-(id)init {
    if (self = [super init]) {
        tag = nil;
        isClustered = NO;
        isExplored = NO;
    }
    return self;
}

@end