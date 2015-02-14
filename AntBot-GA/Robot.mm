#import "Robot.h"
#import "Utilities.h"

@interface Robot()

-(NSPoint) avoidObstacle:(NSPoint) tp;

@end

@implementation Robot

@synthesize status, informed;
@synthesize position, target;
@synthesize direction, searchTime, delay;
@synthesize discoveredTags;
@synthesize path;

@synthesize collisionCount;

//////////////POWER STUFF///////////////
@synthesize batteryLevel;
@synthesize batteryDeadPercent;
@synthesize batteryFull, batteryTime;
@synthesize pheremoneOn, atNest, isDead, needsCharging;

const float DISCHARGE_SCALE = 0.028;
const float DISCHARGE_VSHIFT = 0.8;
//////////////POWER STUFF///////////////

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
    path = [[NSMutableArray alloc] init];
    
    direction = randomFloat(M_2PI);
    delay = 0;
    
    discoveredTags = nil;
    
    collisionCount = 0;
    
    //////////////POWER STUFF///////////////
    batteryLevel = 1.0;                                                 // Battery level is a percent - starts at 100%
    batteryDeadPercent = 0.65;                                          // If battery falls below 65% of full charge robot dies
    batteryFull = 1080;                                                 //15% of 7200 = 1080(all alive but crappy fitness)  2160 = 30%(all dead)  1440 = 20% (alive) 1800 = 25%(alive)  2376 = 33%
    batteryTime = 0;
    pheremoneOn = FALSE;
    atNest = TRUE;
    isDead = FALSE;
    needsCharging = FALSE;
    //////////////POWER STUFF///////////////
    
}

-(void) moveWithObstacle:(std::vector<std::vector<Cell*>>&)grid{
    
    if(NSEqualPoints(position, target)){
        return;
    }
    
//    if([grid[target.y][target.x] obstacle]){
//        target.x = position.x;
//        target.y = position.y;
//    }
    
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
                    while([grid[y+dy][x+dx] obstacle]){
                        NSPoint tp;
                        tp = [self avoidObstacle: NSMakePoint(dx, dy)];
                        if(position.x + tp.x < 0 || position.y + tp.y < 0 || position.x + tp.x > grid[0].size()-1 || position.y + tp.y > grid.size()-1){
                            break;
                        }
                        dx = tp.x;
                        dy = tp.y;
                        [self setTarget:NSMakePoint(position.x + dx, position.y + dy)];
                    }
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
                    tp = [self avoidObstacle:NSMakePoint(dx, dy)];
                    if(position.x + tp.x < 0 || position.y + tp.y < 0 || position.x + tp.x > grid[0].size()-1 || position.y + tp.y > grid.size()-1){
                        break;
                    }
                    dx = tp.x;
                    dy = tp.y;
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
    collisionCount ++;
    delay ++;
    //NSLog(@"collision %d      %d", collisionCount, delay);
    return rp;
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
    delay += (int)abs(dTheta / (M_PI_4 + 0.001)) + 1;
}

//////////////POWER STUFF///////////////

-(void) chargeBattery:(int) tick {
    
    if(batteryLevel >= 1.0){
        //printf("                                   BATTERY FULL\n");
        return;
    }
    
    if(!isDead && batteryTime >= 0){
        batteryLevel = logitFunction((float) batteryTime/batteryFull, DISCHARGE_SCALE, DISCHARGE_VSHIFT);
        
        //batteryLevel = batteryLevel + .001;
        //printf("                  charging");
        batteryTime--;
    }
    //printf("%f\n", batteryLevel);
}

-(void) dischargeBattery:(int) tick {
    
    float temp;
    if(batteryTime < batteryFull){
        batteryTime++;
        temp = logitFunction((float) batteryTime/batteryFull, DISCHARGE_SCALE, DISCHARGE_VSHIFT);
        
        //temp = batteryLevel - .001;
    } else {
        return;
    }
    
    if(batteryLevel < batteryDeadPercent){                        // If battery > 65% then robot is now dead due to battery damage
        isDead = TRUE;
        //printf("%f     DEAD!!!!!!!!!!!!!!!!!\n", batteryLevel);
        return;
    }
    
    //    if(!pheremoneOn){
    //
    batteryLevel = temp;
    //
    //    } else {
    //
    //        batteryLevel = temp - .001;                                                             // Additional penalty for using pheremone is 0.1% per step
    //
    //    }
    
    //printf("%f\n", batteryLevel);
    
}
//////////////POWER STUFF///////////////

@end
