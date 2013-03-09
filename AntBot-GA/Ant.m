#import "Ant.h"
#include "Util.h"

@implementation Ant

@synthesize status, informed;
@synthesize position, target;
@synthesize direction, searchTime, lastMoved, lastTurned;
@synthesize carrying, neighbors;

-(void) reset {
    status = ANT_STATUS_INACTIVE;
    informed = ANT_INFORMED_NONE;
    
    position = NSMakePoint(-1,-1);
    target = NSMakePoint(-1,-1);
    
    direction = randomFloat(M_2PI);
    searchTime = -1;
    lastMoved = 0;
    lastTurned = 0;
    
    carrying = nil;
}


/*
 * Moves the ant towards its target.
 * Uses the Kenneth motion planning algorithm.
 */
-(void) move {
    if(NSEqualPoints(position,target)){return;}
    
    //Calculate the highest distance improvement we can get for every neighboring cell.  Ugly but optimized.
    float x = position.x;
    float y = position.y;
    float dis = pointDistance(x,y,target.x,target.y);
    float improvements[3][3];
    float improvementSum = 0;
    int dxMin = (x == 0) ? 0 : -1;
    int dyMin = (y == 0) ? 0 : -1;
    int dxMax = (x == (GRID_WIDTH-1)) ? 0 : 1;
    int dyMax = (y == (GRID_HEIGHT-1)) ? 0 : 1;
    for(int dx = dxMin; dx <=dxMax; dx++) {
        for(int dy = dyMin; dy<=dyMax; dy++) {
            if(dx || dy) {
                if(x+dx == target.x && y+dy == target.y){position = target; return;}
                float improvement = dis-pointDistance(x+dx, y+dy, target.x, target.y);
                if(improvement > 0.f) {
                    improvementSum += improvement;
                    improvements[dx+1][dy+1] = improvement;
                }
                else{improvements[dx+1][dy+1] = 0.;}
            }
            else{improvements[dx+1][dy+1] = 0.;}
        }
    }
    
    //Pick a random neighbor based on a random number weighted on how much of a distance improvement we can get.
    float r = randomFloat(improvementSum);
    for(int dx = dxMin; dx <= dxMax; dx++) {
        for(int dy = dyMin; dy<= dyMax; dy++) {
            if(r < improvements[dx+1][dy+1]){position = NSMakePoint(x+dx,y+dy); return;}
            r -= improvements[dx+1][dy+1];
        }
    }
}

@end
