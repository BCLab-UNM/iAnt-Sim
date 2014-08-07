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
    NSMutableArray *curChildren = [[NSMutableArray alloc] init];
    NSMutableArray *allChildren = [[NSMutableArray alloc] init];
    NSMutableArray *unexploredRegions = [[NSMutableArray alloc] init];
    NSMutableArray *pendingRegions = [[NSMutableArray alloc] init];
    NSMutableArray *removedRegions = [[NSMutableArray alloc] init];
    NSMutableArray *tempRegions = [[NSMutableArray alloc] init];
    NSMutableArray *emptyRegions = [[NSMutableArray alloc] init];
    
    [tempRegions addObjectsFromArray:regions];
    for(int i = 0; i < [regions count]; ++i) {
        QuadTree *region = [regions objectAtIndex:i];
        [region setPercentExplored:[self checkExploredness:region]];
        if([region percentExplored] == 0) {
            [removedRegions addObject:region];
            [emptyRegions addObject:region];
        }
        if([region percentExplored] > .5) {
            [removedRegions addObject:region];
        }
        
        if([region area] < 4) {
            [removedRegions addObject:region];        }
        
        if([[region children] count] == 4) {
            [removedRegions addObject:region];
        }
    }
    
    for(QuadTree* region in removedRegions) {
        [tempRegions removeObject:region];
    }
    [parents addObjectsFromArray:tempRegions];
    
    for(QuadTree* parent in parents) {
        [curChildren removeAllObjects];
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
        
        [curChildren addObject:northWest];
        [curChildren addObject:northEast];
        [curChildren addObject:southWest];
        [curChildren addObject:southEast];
        
        [[parent children] addObjectsFromArray:curChildren];
        
        [baseRegions removeObject:parent];
        
        [allChildren addObjectsFromArray:curChildren];
    }
    
    [baseRegions addObjectsFromArray:allChildren];
    for(int i = 0; i < [allChildren count]; ++i) {
        QuadTree* child = [allChildren objectAtIndex:i];
        [child setPercentExplored:[self checkExploredness:child]];
        if([child percentExplored] == 0. && [child area] >= 4) {
            [unexploredRegions addObject:child];
        }
        else if([child percentExplored] <= .5 && [child area] >= 4) {
            [pendingRegions addObject:child];
        }
        else {
            [baseRegions removeObject:child];
            //            [child bubbleUpPercentage];
        }
    }
    
    if([pendingRegions count] > 0) {
        [unexploredRegions addObjectsFromArray:[self runDecomposition:pendingRegions]];
    }
    
    if([unexploredRegions count] > 0) {
        [unexploredRegions addObjectsFromArray:emptyRegions];
        return unexploredRegions;
    }
    else {
        return emptyRegions;
    }
}

/*
 * Checks how much of the region is explored
 * Returns the percentage of the region that has been explored as a double
 */
-(double) checkExploredness:(QuadTree*)region {
    double exploredCount = 0.;
    for(int i = 0; i < [region width]; i++) {
        for(int j = 0; j < [region height]; j++) {
            if([(Cell*)[[region cells] objectAtRow:i col:j] isExplored]) {
                exploredCount++;
            }
        }
    }
    
    double newPercent = exploredCount / (double)[region area];
    if([region percentExplored] != newPercent) {
        [region setNeedsDecomposition:YES];
    }
    
    return newPercent;
}

-(void) bubbleUpPercentage:(QuadTree*)region {
    QuadTree *parent = [region parent];
    [parent setPercentExplored:.25 * [region percentExplored] + [parent percentExplored]];
    
    if([parent percentExplored] > .75) {
        [baseRegions removeObject:parent];
        [self bubbleUpPercentage:parent];
    }
}

@end
