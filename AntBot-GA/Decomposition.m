#import "Decomposition.h"

@implementation Decomposition

/*
 * Executes quadratic decomposition algorithm on input region
 * Returns array of unclustered regions
 */
+(NSMutableArray*) runDecomposition:(NSMutableArray*)regions {
    BOOL decompComplete = NO;
    int width1, width2, height1, height2;
    NSMutableArray *parents = [[NSMutableArray alloc] init];
    NSMutableArray *children = [[NSMutableArray alloc] init];
    NSMutableArray *unclusteredRegions = [[NSMutableArray alloc] init];
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
        
        QuadTree *northWest = [[QuadTree alloc] initWithHeight:height1 width:width1 origin:nwOrigin andCells:nwCells];
        QuadTree *northEast = [[QuadTree alloc] initWithHeight:height1 width:width2 origin:neOrigin andCells:neCells];
        QuadTree *southWest = [[QuadTree alloc] initWithHeight:height2 width:width1 origin:swOrigin andCells:swCells];
        QuadTree *southEast = [[QuadTree alloc] initWithHeight:height2 width:width2 origin:seOrigin andCells:seCells];
        
        [children addObject:northWest];
        [children addObject:northEast];
        [children addObject:southWest];
        [children addObject:southEast];
    }
    
    for(QuadTree* child in children) {
        if([self isFullyUnclustered:child]) {
            decompComplete = YES;
            [unclusteredRegions addObject:child];
        }
    }
    
    if(!decompComplete) {
        [unclusteredRegions removeAllObjects];
        unclusteredRegions = [self runDecomposition:children];
    }
    
    return unclusteredRegions;
}

/*
 * Checks all cells in input region for cluster status
 * Returns true if all cells are unclustered, false otherwise
 */
+(BOOL) isFullyUnclustered:(QuadTree*)region {
    for(int i = 0; i < [region width]; i++) {
        for(int j = 0; j < [region height]; j++) {
            if([(Cell*)[[region cells] objectAtRow:i col:j] isClustered]) {
                return FALSE;
            }
        }
    }
    return TRUE;
}

@end
