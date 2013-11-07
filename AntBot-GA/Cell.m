#import "Cell.h"

@implementation Cell

@synthesize tag;
@synthesize isClustered;

-(id)init {
    if (self = [super init]) {
        tag = nil;
        isClustered = NO;
    }
    return self;
}

@end