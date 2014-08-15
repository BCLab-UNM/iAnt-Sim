#import "Cell.h"

@implementation Cell

@synthesize tag, region;
@synthesize isClustered, isExplored;

-(id)init {
    if (self = [super init]) {
        tag = nil;
        region = nil;
        isClustered = NO;
        isExplored = NO;
    }
    return self;
}

@end