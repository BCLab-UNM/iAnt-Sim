#import "Robot.h"
#import "Utilities.h"

@interface Robot()

-(NSPoint) avoidObstacle:(NSPoint) tp;

@end

@implementation Robot

@synthesize status, informed;
@synthesize position, target;
@synthesize direction, searchTime, lastMoved, lastTurned, delay;
@synthesize discoveredTags;

@synthesize collisionCount;

-(id) init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

-(void) reset {
    status = ROBOT_STATUS_INACTIVE;
    informed = ROBOT_INFORMED_NONE;
    
    position = NSNullPoint;
    target = NSNullPoint;
    
    direction = randomFloat(M_2PI);
    lastMoved = 0;
    lastTurned = 0;
    delay = 0;
    
    discoveredTags = nil;
    
    collisionCount = 0;
}

-(void) moveWithObstacle:(std::vector<std::vector<Cell*>>&)grid{
    
    if(NSEqualPoints(position, target)){
        return;
    }
    
    //Calculate the highest distance improvement we can get for every neighboring cell.  Ugly but optimized.
    float x = position.x;
    float y = position.y;
    float dis = pointDistance(x, y, target.x, target.y);
    float improvements[3][3];
    float improvementSum = 0;
    int dxMin = (x == 0) ? 0 : -1;
    int dyMin = (y == 0) ? 0 : -1;
    int dxMax = (x == (grid[0].size() - 1)) ? 0 : 1;
    int dyMax = (y == (grid.size() - 1)) ? 0 : 1;
    for(int dx = dxMin; dx <= dxMax; dx++) {
        for(int dy = dyMin; dy <= dyMax; dy++) {
            if(dx || dy) {
                if(x + dx == target.x && y + dy == target.y){
                    // SEARCHING
                    //printf("current position x %f y %f  and current target x %f y %f\n", position.x, position.y, target.x, target.y);
                    while([grid[target.y][target.x] obstacle]){
                        NSPoint tp;
                        printf("current position x %f y %f      obstacle at x %f y %f\n", position.x, position.y, target.x, target.y);
                        printf("dx dy %d %d\n", dx, dy);
                        tp = [self avoidObstacle: NSMakePoint(dx, dy)];
                        dx = tp.x;
                        dy = tp.y;
                        [self setTarget:NSMakePoint(position.x + dx, position.y + dy)];
                        printf("current position x %f y %f      new target loc set x %f  y %f\n", position.x, position.y, target.x, target.y);
                    }
                    //printf("moving to new position x %f y %f\n\n", target.x, target.y);
//                    if(abs(target.x - position.x) > 1 || abs(target.y - position.y) > 1){
//                        printf("                                                    FUCK ME\n");
//                    }
                    collisionCount = 0;
                    position = target;
                    return;
                }
                float improvement = dis - pointDistance(x + dx, y + dy, target.x, target.y);
                if(improvement > 0.f) {
                    improvementSum += improvement;
                    improvements[dx + 1][dy + 1] = improvement;
                }
                else{improvements[dx + 1][dy + 1] = 0.;}
            }
            else{improvements[dx + 1][dy + 1] = 0.;}
        }
    }
    
    //Pick a random neighbor based on a random number weighted on how much of a distance improvement we can get.
    float r = randomFloat(improvementSum);
    for(int dx = dxMin; dx <= dxMax; dx++) {
        for(int dy = dyMin; dy <= dyMax; dy++) {
            if(r < improvements[dx + 1][dy + 1]){
                // RETURNING or DEPARTING
                while([grid[y+dy][x+dx] obstacle]){
                    NSPoint tp;
                    printf("Travelling Obstacle %d\n", collisionCount++);
                    tp = [self avoidObstacle:NSMakePoint(dx, dy)];
                    dx = tp.x;
                    dy = tp.y;
                    if (collisionCount > 20) {
                        [self setStatus:ROBOT_STATUS_SEARCHING];
                        [self setTarget:NSMakePoint(position.x + dx, position.y + dy)];
                        collisionCount = 0;
                    }
                }
                position = NSMakePoint(x + dx, y + dy);
                return;
            }
            r -= improvements[dx + 1][dy + 1];
        }
    }
    
}

-(NSPoint) avoidObstacle:(NSPoint) tp{
    NSPoint rp = {0,0};
    if(tp.x == 1 && tp.y == 0){
        rp.x = 1; rp.y = -1;
    } else if (tp.x == 1 && tp.y == -1){
        rp.x = 0; rp.y = -1;
    } else if (tp.x == 0 && tp.y == -1){
        rp.x = -1; rp.y = -1;
    } else if (tp.x == -1 && tp.y == -1){
        rp.x = -1; rp.y = 0;
    } else if (tp.x == -1 && tp.y == 0){
        rp.x = -1; rp.y = 1;
    } else if (tp.x == -1 && tp.y == 1){
        rp.x = 0; rp.y = 1;
    } else if (tp.x == 0 && tp.y == 1){
        rp.x = 1; rp.y = 1;
    } else {
        rp.x = 1; rp.y = 0;
    }
    return rp;
}

/*
 * Moves the robot towards its target.
 * Uses the Kenneth motion planning algorithm.
 */
-(void) moveWithin:(NSSize)bounds {
    if(NSEqualPoints(position, target)){return;}
    
    //Calculate the highest distance improvement we can get for every neighboring cell.  Ugly but optimized.
    float x = position.x;
    float y = position.y;
    float dis = pointDistance(x, y, target.x, target.y);
    float improvements[3][3];
    float improvementSum = 0;
    int dxMin = (x == 0) ? 0 : -1;
    int dyMin = (y == 0) ? 0 : -1;
    int dxMax = (x == (bounds.width - 1)) ? 0 : 1;
    int dyMax = (y == (bounds.height - 1)) ? 0 : 1;
    for(int dx = dxMin; dx <= dxMax; dx++) {
        for(int dy = dyMin; dy <= dyMax; dy++) {
            if(dx || dy) {
                if(x + dx == target.x && y + dy == target.y){position = target; return;}
                float improvement = dis - pointDistance(x + dx, y + dy, target.x, target.y);
                if(improvement > 0.f) {
                    improvementSum += improvement;
                    improvements[dx + 1][dy + 1] = improvement;
                }
                else{improvements[dx + 1][dy + 1] = 0.;}
            }
            else{improvements[dx + 1][dy + 1] = 0.;}
        }
    }
    
    //Pick a random neighbor based on a random number weighted on how much of a distance improvement we can get.
    float r = randomFloat(improvementSum);
    for(int dx = dxMin; dx <= dxMax; dx++) {
        for(int dy = dyMin; dy <= dyMax; dy++) {
            if(r < improvements[dx + 1][dy + 1]){position = NSMakePoint(x + dx, y + dy); return;}
            r -= improvements[dx + 1][dy + 1];
        }
    }
}

-(void) turnWithParameters:(Team *)params {
    //We keep track of the amount of turning the robot does so we can penalize it with a time delay
    // (emulating the physical robots)
    float dTheta;
    
    if(informed) {
        float informedSearchCorrelation = exponentialDecay(2 * M_2PI - [params uninformedSearchCorrelation], searchTime++, [params informedSearchCorrelationDecayRate]);
        dTheta = clip(randomNormal(0, informedSearchCorrelation + [params uninformedSearchCorrelation]), -M_PI, M_PI);
    }
    else {
        dTheta = clip(randomNormal(0, [params uninformedSearchCorrelation]), -M_PI, M_PI);
    }
    direction = pmod(direction + dTheta, M_2PI);
    
    //We delay the robot 1 tick for every PI/4 radians (i.e. 45 degrees) of turning
    //NOTE: We increment PI/4 by a small epsilon value to avoid over-penalizing at PI (i.e. 180 degrees)
    delay = (int)abs(dTheta / (M_PI_4 + 0.001)) + 1;
}

@end
