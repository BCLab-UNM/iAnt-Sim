//
//  Pile.mm
//  AntBot-GA
//
//  Created by Drew Levin on 2/21/15.
//  Copyright (c) 2015 AntBot. All rights reserved.
//

#import "Pile.h"

using namespace std;

@implementation Pile

@synthesize capacity;
@synthesize radius;
@synthesize position;
@synthesize tagArray;

-(Pile*) initAtX:(int)_x andY:(int)_y withCapacity:(int)_capacity andRadius:(int)_radius {
    position = NSMakePoint(_x, _y);
    capacity = _capacity;
    radius = _radius;
    
    tagArray = [[NSMutableArray alloc] init];
    
    return self;
}

-(UInt8) numTags {
    return [tagArray count];
}

-(void) addTagtoGrid:(vector<vector<Cell*>>&)grid ofSize:(NSSize)gridSize {
    // Place tag in an empty grid cell
    float maxRadius = radius;
    int tagX, tagY;
    float rad, dir;
    do {
        rad = randomFloat(maxRadius);
        dir = randomFloat(M_2PI);
        
        tagX = clip(roundf(position.x + (rad * cos(dir))), 0, gridSize.width - 1);
        tagY = clip(roundf(position.y + (rad * sin(dir))), 0, gridSize.height - 1);
        
        maxRadius += 1;
    } while([grid[tagY][tagX] tag]);
    
    Tag* tag = [[Tag alloc] initWithX:tagX Y:tagY andPile:self];
    [grid[tagY][tagX] setTag:tag];

    [tagArray addObject:tag];

    [tag setPickedUp:NO];
    [tag setDiscovered:NO];
}

-(void) removeTagFromGrid:(vector<vector<Cell*>>&)grid {
    Tag* tag = [tagArray lastObject];
    
    [grid[tag.position.y][tag.position.x] setTag:nil];
    
    [tagArray removeLastObject];
}

-(void) addTag:(Tag*)_tag {
    [tagArray addObject:_tag];
}

-(void) removeSpecificTag:(Tag*)_tag {
    [tagArray removeObjectIdenticalTo:_tag];
}

-(BOOL) containsPointX:(float)_x andY:(float)_y {
    return pointDistance(position.x, position.y, _x, _y) < radius;
}

-(void) shuffle {
    int j;
    for (int i=0; i<[tagArray count]; i++) {
        j = randomInt((int)[tagArray count] - i) + i;
        [tagArray exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
}

@end
