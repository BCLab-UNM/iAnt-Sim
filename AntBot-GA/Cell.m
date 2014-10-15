#import "Cell.h"

@implementation Cell

@synthesize tag, region;
@synthesize isClustered, isExplored;
@synthesize obstacle;

-(id)init {
    if (self = [super init]) {
        tag = nil;
        region = nil;
        isClustered = NO;
        isExplored = NO;
        
        obstacle = nil;
    }
    return self;
}

@end