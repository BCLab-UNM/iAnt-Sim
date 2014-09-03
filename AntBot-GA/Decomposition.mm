#import "Decomposition.h"

@implementation Decomposition

@synthesize exploredCutoff;
@synthesize grid;

-(id) initWithGrid:(std::vector<std::vector<Cell*>>)_grid andExploredCutoff:(float)_exploredCutoff {
    if(self = [super init]) {
        grid = _grid;
        exploredCutoff = _exploredCutoff;
    }
    return self;
}

/*
 * Executes quadratic decomposition algorithm on input region
 * Returns array of unexplored regions
 */
-(NSMutableArray*) runDecomposition:(NSMutableArray*)regions {
    int width1, width2, height1, height2;
    NSMutableArray* parents = [[NSMutableArray alloc] init];
    NSMutableArray* unexploredRegions = [[NSMutableArray alloc] init];
    
    for(QuadTree* region in regions) {
        if ([region dirty]) {
            [region setPercentExplored:[self checkExploredness:region]];
            if([region percentExplored] == 0 && ([region area] >= 4)) {
                [unexploredRegions addObject:region];
            }
            else if(([region percentExplored] <= exploredCutoff) && ([region area] >= 4)){
                [parents addObject:region];
            }
        }
        else {
            [unexploredRegions addObject:region];
        }
    }
    
    NSMutableArray* children = [[NSMutableArray alloc] init];
    
    for(QuadTree* parent in parents) {
        if(fmod([parent shape].size.width, 2) == 0) {
            width1 = width2 = [parent shape].size.width / 2;
        }
        else {
            width1 = [parent shape].size.width / 2;
            width2 = ([parent shape].size.width / 2) + 1;
        }
        if(fmod([parent shape].size.height, 2) == 0) {
            height1 = height2 = [parent shape].size.height / 2;
        }
        else {
            height1 = [parent shape].size.height / 2;
            height2 = ([parent shape].size.height / 2) + 1;
        }
        
        [children addObject:[[QuadTree alloc] initWithRect:NSMakeRect([parent shape].origin.x, [parent shape].origin.y, width1, height1)]];
        [children addObject:[[QuadTree alloc] initWithRect:NSMakeRect([parent shape].origin.x + width1, [parent shape].origin.y, width2, height1)]];
        [children addObject:[[QuadTree alloc] initWithRect:NSMakeRect([parent shape].origin.x, [parent shape].origin.y + height1, width1, height2)]];
        [children addObject:[[QuadTree alloc] initWithRect:NSMakeRect([parent shape].origin.x + width1, [parent shape].origin.y + height1, width2, height2)]];
    }
    
    //Recursive case
    if ([children count]) {
        return [[unexploredRegions arrayByAddingObjectsFromArray:[self runDecomposition:children]] mutableCopy];
    }
    //Base case
    else {
        return unexploredRegions;
    }
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
            [grid[i][j] setRegion:region];
            if([grid[i][j] isExplored]) {
                exploredCount++;
            }
        }
    }
    
    [region setDirty:NO];
    
    return exploredCount / [region area];
}

@end
