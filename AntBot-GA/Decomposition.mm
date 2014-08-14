#import "Decomposition.h"

@implementation Decomposition

@synthesize grid;

-(id) initWithGrid:(std::vector<std::vector<Cell*>>)_grid {
    if(self = [super init]) {
        grid = _grid;
        unexploredRegions = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) reset {
    [unexploredRegions removeAllObjects];
}

/*
 * Executes quadratic decomposition algorithm on input region
 * Returns array of unexplored regions
 */
-(NSMutableArray*) runDecomposition:(NSMutableArray*)regions {
    int width1, width2, height1, height2;
    NSMutableArray* parents = [[NSMutableArray alloc] init];
    NSMutableArray* allChildren = [[NSMutableArray alloc] init];
    
    for(QuadTree* region in regions) {
        [region setPercentExplored:[self checkExploredness:region]];
        if([region percentExplored] == 0 && ([region area] >= 4)) {
            [unexploredRegions addObject:region];
        }
        else if(([region needsDecomposition] && [region percentExplored] <= .5) && ([region area] >= 4)){
            [parents addObject:region];
        }
    }
    
    for(QuadTree* parent in parents) {
        if(fmod([parent shape].size.width, 2) == 0) {
            width1 = width2 = [parent shape].size.width / 2.;
        }
        else {
            width1 = [parent shape].size.width / 2.;
            width2 = ([parent shape].size.width / 2.) + 1;
        }
        if(fmod([parent shape].size.height, 2) == 0) {
            height1 = height2 = [parent shape].size.height / 2.;
        }
        else {
            height1 = [parent shape].size.height / 2.;
            height2 = ([parent shape].size.height / 2.) + 1;
        }
        
        QuadTree* northWest = [[QuadTree alloc] initWithRect:NSMakeRect([parent shape].origin.x, [parent shape].origin.y, width1, height1)];
        QuadTree* northEast = [[QuadTree alloc] initWithRect:NSMakeRect([parent shape].origin.x + width1, [parent shape].origin.y, width2, height1)];
        QuadTree* southWest = [[QuadTree alloc] initWithRect:NSMakeRect([parent shape].origin.x, [parent shape].origin.y + height1, width1, height2)];
        QuadTree* southEast = [[QuadTree alloc] initWithRect:NSMakeRect([parent shape].origin.x + width1, [parent shape].origin.y + height1, width2, height2)];
        
        [allChildren addObject:northWest];
        [allChildren addObject:northEast];
        [allChildren addObject:southWest];
        [allChildren addObject:southEast];
    }
    
    if ([allChildren count]) {
        [self runDecomposition:allChildren];
    }
    
    return unexploredRegions;
}

/*
 * Checks how much of the region is explored
 * Returns the percentage of the region that has been explored as a double
 */
-(double) checkExploredness:(QuadTree*)region {
    double exploredCount = 0.;
    NSRect shape = [region shape];
    for(int i = shape.origin.y; i < shape.origin.y + shape.size.height; i++) {
        for(int j = shape.origin.x; j < shape.origin.x + shape.size.width; j++) {
            if([grid[i][j] isExplored]) {
                exploredCount++;
            }
        }
    }
    
    double newPercent = exploredCount / (double)[region area];
    if(newPercent > [region percentExplored]) {
        [region setNeedsDecomposition:YES];
    }
    
    return newPercent;
}

@end
