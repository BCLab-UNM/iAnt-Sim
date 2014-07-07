#import "Decomposition.h"

@implementation Decomposition

@synthesize baseRegions;

-(id) initWithRegions:(NSMutableArray *)_baseRegions {
    if(self = [super init]) {
        baseRegions = _baseRegions;
    }
    return self;
}

/*
 * Executes quadratic decomposition algorithm on input region
 * Returns array of unclustered regions
 */
-(NSMutableArray*) runDecomposition:(NSMutableArray*)regions {
    int width1, width2, height1, height2;
    NSMutableArray *parents = [[NSMutableArray alloc] init];
    NSMutableArray *kids = [[NSMutableArray alloc] init];
    NSMutableArray *unexploredRegions = [[NSMutableArray alloc] init];
    NSMutableArray *pendingRegions = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < [regions count]; ++i) {
        QuadTree *region = [regions objectAtIndex:i];
        [region setPercentExplored:[self checkExploredness:region]];
        if([region percentExplored] > .75) {
            [regions removeObject:region];
            [baseRegions removeObject:region];
        }
        
        if([region width] * [region height] < 16) {
            [regions removeObject:region];
            [baseRegions removeObject:region];
        }
    }
    [parents addObjectsFromArray:regions];
    
    for(QuadTree* parent in parents) {
        if([parent width] % 2 == 0) {
            width1 = width2 = [parent width] / 2;
        }
        else {
            width1 = [parent width] / 2;
            width2 = ([parent width] / 2) + 1;
        }
        if([parent height] % 2 == 0) {
            height1 = height2 = [parent height] / 2;
        }
        else {
            height1 = [parent height] / 2;
            height2 = ([parent height] / 2) + 1;
        }
        
        NSPoint nwOrigin, neOrigin, swOrigin, seOrigin;
        nwOrigin = [parent origin];
        neOrigin.x = parent.origin.x + width1;
        neOrigin.y = parent.origin.y;
        swOrigin.x = parent.origin.x;
        swOrigin.y = parent.origin.y + height1;
        seOrigin.x = parent.origin.x + width1;
        seOrigin.y = parent.origin.y + height1;
        
        Array2D* nwCells = [[Array2D alloc] initWithRows:width1 cols:height1];
        Array2D* neCells = [[Array2D alloc] initWithRows:width2 cols:height1];
        Array2D* swCells = [[Array2D alloc] initWithRows:width1 cols:height2];
        Array2D* seCells = [[Array2D alloc] initWithRows:width2 cols:height2];
        
        int x, y;
        x = y = 0;
        for(int i = 0; i < width1; i++) {
            for(int j = 0; j < height1; j++) {
                [nwCells setObjectAtRow:x col:y to:[[parent cells] objectAtRow:i col:j]];
                y++;
            }
            x++;
            y = 0;
        }
        
        x = y = 0;
        for(int i = width1; i < [parent width]; i++) {
            for(int j = 0; j < height1; j++) {
                [neCells setObjectAtRow:x col:y to:[[parent cells] objectAtRow:i col:j]];
                y++;
            }
            x++;
            y = 0;
        }
        
        x = y = 0;
        for(int i = 0; i < width1; i++) {
            for(int j = height1; j < [parent height]; j++) {
                [swCells setObjectAtRow:x col:y to:[[parent cells] objectAtRow:i col:j]];
                y++;
            }
            x++;
            y = 0;
        }
        
        x = y = 0;
        for(int i = width1; i < [parent width]; i++) {
            for(int j = height1; j < [parent height]; j++) {
                [seCells setObjectAtRow:x col:y to:[[parent cells] objectAtRow:i col:j]];
                y++;
            }
            x++;
            y = 0;
        }
        
        QuadTree *northWest = [[QuadTree alloc] initWithHeight:height1 width:width1 origin:nwOrigin cells:nwCells andParent:parent];
        QuadTree *northEast = [[QuadTree alloc] initWithHeight:height1 width:width2 origin:neOrigin cells:neCells andParent:parent];
        QuadTree *southWest = [[QuadTree alloc] initWithHeight:height2 width:width1 origin:swOrigin cells:swCells andParent:parent];
        QuadTree *southEast = [[QuadTree alloc] initWithHeight:height2 width:width2 origin:seOrigin cells:seCells andParent:parent];
        
        [kids addObject:northWest];
        [kids addObject:northEast];
        [kids addObject:southWest];
        [kids addObject:southEast];
        
        [[parent children] addObjectsFromArray:kids];
        [parent setDirty:NO];
        
        [baseRegions removeObject:parent];
    }
    
    [baseRegions addObjectsFromArray:kids];
    for(int i = 0; i < [kids count]; ++i) {
        QuadTree* child = [kids objectAtIndex:i];
        [child setPercentExplored:[self checkExploredness:child]];
        if([child percentExplored] == 0.) {
            [unexploredRegions addObject:child];
        }
        else if([child percentExplored] <= .75 && ([child height] * [child width]) >= 16) {
            [pendingRegions addObject:child];
        }
        else {
            [baseRegions removeObject:child];
            [child bubbleUpPercentage];
        }
    }
    
    if([pendingRegions count] > 0) {
        [unexploredRegions addObjectsFromArray:[self runDecomposition:pendingRegions]];
    }
    
    return unexploredRegions;
}

/*
 * Checks how much of the region is explored
 * Returns the percentage of the region that has been explored as a double
 */
-(double) checkExploredness:(QuadTree*)region {
    double exploredCount = 0.;
    double regionSize = [region width] * [region height];
    for(int i = 0; i < [region width]; i++) {
        for(int j = 0; j < [region height]; j++) {
            if([(Cell*)[[region cells] objectAtRow:i col:j] isExplored]) {
                exploredCount++;
            }
        }
    }
    
    return exploredCount / regionSize;
}

@end
