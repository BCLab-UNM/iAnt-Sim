#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import "Simulation.h"
#import "Team.h"
#import "Robot.h"
#import "Tag.h"
#include "Util.h"

@interface Pheromone : NSObject {}
@property (nonatomic) int x;
@property (nonatomic) int y;
@property (nonatomic) float n;
@property (nonatomic) int updated;
@end

@implementation Pheromone
@synthesize x,y,n,updated;
@end

@implementation Simulation

@synthesize teamCount, generationCount, robotCount;
@synthesize distributionRandom, distributionPowerlaw, distributionClustered, tagCount, evaluationCount;
@synthesize averageTeam, bestTeam;
@synthesize tickRate;
@synthesize randomizeParameters;
@synthesize parameterFile;
@synthesize positionalError, detectionError;
@synthesize delegate, viewDelegate;

/*
 * Starts the simulation run.
 */
-(int) start {
    
    srandomdev();
    colonies = [[NSMutableArray alloc] initWithCapacity:teamCount];
    for(int i = 0; i < teamCount; i++) {
        if (randomizeParameters) {
            [colonies addObject:[[Team alloc] initRandom]];
        }
        else {
            [colonies addObject:[[Team alloc] initWithSpecificFile:parameterFile]];
        }
    }
    evaluationCount = (viewDelegate != nil) ? 1 : evaluationCount;
    
    for(int generation = 0; generation < generationCount; generation++) {
        
        for(Team* team in colonies){team.tagsCollected = 0;}
        
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_apply(evaluationCount, queue, ^(size_t idx) {
            @autoreleasepool {
                [self runEvaluation];
            }
        });
        
        [self breedColonies];
        
        if(delegate) {
        
            //Technically should pass in average and best colonies here.
            if([delegate respondsToSelector:@selector(finishedGeneration:)]) {
                [delegate finishedGeneration:generation];
            }
        }
    }
    
    return 0;
}


/*
 * Runs a single evaluation
 */
-(void) runEvaluation {
    @autoreleasepool {
        Tag* tags[GRID_HEIGHT][GRID_WIDTH];
        [self initDistributionForArray:tags];
        
        NSMutableArray* robots = [[NSMutableArray alloc] initWithCapacity:robotCount];
        NSMutableArray* pheromones = [[NSMutableArray alloc] init];
        for(int i = 0; i < robotCount; i++){[robots addObject:[[Robot alloc] init]];}
        
        for(Team* team in colonies) {
            for(int i = 0; i < GRID_HEIGHT; i++) {
                for(int j = 0; j < GRID_WIDTH; j++) {
                    if(tags[i][j]){[tags[i][j] setPickedUp:NO];}
                }
            }
            for(int i = 0; i < robotCount; i++){[[robots objectAtIndex:i] reset];}
            [pheromones removeAllObjects];
            
            for(int tick = 0; tick < STEP_COUNT; tick++){
                for(Robot* robot in robots) {
                    
                    switch(robot.status) {
                            
                            /*
                             * The robot hasn't been initialized yet.
                             * Give it some basic starting values and then fall-through to the next state.
                             */
                        case ROBOT_STATUS_INACTIVE:
                            robot.status = ROBOT_STATUS_DEPARTING;
                            robot.position = NSMakePoint(NEST_X,NEST_Y);
                            robot.target = edge(GRID_WIDTH,GRID_HEIGHT);
                            //Fallthrough to ROBOT_STATUS_DEPARTING.
                            
                            /*
                             * The robot is either:
                             *  -Moving in a random direction away from the nest (not site-fidelity-ing or pheromone-ing).
                             *  -Moving towards a specific point where a tag was last found (site-fidelity-ing).
                             *  -Moving towards a specific point due to pheromones.
                             *
                             * For each of the cases, we have to ultimately decide on a direction for the robot to travel in,
                             * then decide which 'cell' best accomplishes traveling in this direction.  We then move the robot,
                             * and may change the robot/world state based on certain criteria (i.e. it reaches its destination).
                             */
                        case ROBOT_STATUS_DEPARTING:
                            if((!robot.informed && (randomFloat(1.) < team.travelGiveUpProbability)) ||
                                (NSEqualPoints(robot.position, robot.target))){
                                robot.status = ROBOT_STATUS_SEARCHING;
                                break;
                            }
                            
                            [robot move];
                            break;
                            
                            /*
                             * The robot is performing a random walk.
                             * In this state, the robot only exhibits behavior once every SEARCH_DELAY ticks.
                             * It will randomly change its direction based on how long it has been searching and move in this direction.
                             * If it finds a tag, its state changes to ROBOT_STATUS_RETURNING (it brings the tag back to the nest.
                             * All site fidelity and pheromone work, however, is taken care of once the robot actually arrives at the nest.
                             */
                        case ROBOT_STATUS_SEARCHING:
                            if(tick - robot.lastMoved < SEARCH_DELAY){break;}
                            
                            if(randomFloat(1.) < team.searchGiveUpProbability) {
                                robot.target = NSMakePoint(NEST_X,NEST_Y);
                                robot.status = ROBOT_STATUS_RETURNING;
                                break;
                            }
                            
                            if(tick - robot.lastTurned >= 3 * SEARCH_DELAY) { //Change direction every 3 iterations.
                                float dTheta;
                                if(robot.searchTime >= 0) {
                                    float informedSearchCorrelation = exponentialDecay(2*M_2PI-team.uninformedSearchCorrelation, robot.searchTime++, team.informedSearchCorrelationDecayRate);
                                    dTheta = clip(randomNormal(0, informedSearchCorrelation+team.uninformedSearchCorrelation),-M_PI,M_PI);
                                }
                                else {
                                    dTheta = clip(randomNormal(0, team.uninformedSearchCorrelation),-M_PI,M_PI);
                                }
                                robot.direction = pmod(robot.direction+dTheta,M_2PI);
                                robot.lastTurned = tick;
                            }
                            
                            //If our current direction takes us outside the world, frantically spin around until this isn't the case.
                            robot.target = NSMakePoint(roundf(robot.position.x+cos(robot.direction)),roundf(robot.position.y+sin(robot.direction)));
                            while(robot.target.x < 0 || robot.target.y < 0 || robot.target.x >= GRID_WIDTH || robot.target.y >= GRID_HEIGHT) {
                                robot.direction = randomFloat(M_2PI);
                                robot.target = NSMakePoint(roundf(robot.position.x+cos(robot.direction)),roundf(robot.position.y+sin(robot.direction)));
                            }
                            
                            [robot move];
                            
                            //After we've moved 1 square ahead, check one square ahead for a tag.
                            //Reusing robot.target here (without consequence, it just gets overwritten when moving).
                            robot.target = NSMakePoint(roundf(robot.position.x+cos(robot.direction)),roundf(robot.position.y+sin(robot.direction)));
                            if(robot.target.x >= 0 && robot.target.y >= 0 && robot.target.x < GRID_WIDTH && robot.target.y < GRID_HEIGHT) {
                                Tag* t = tags[(int)robot.target.y][(int)robot.target.x];
                                if((randomFloat(1.f) >= detectionError) && (t != 0) && !t.pickedUp) { //Note we use shortcircuiting here.
                                    [t setPickedUp:YES];
                                    robot.carrying = t;
                                    robot.status = ROBOT_STATUS_RETURNING;
                                    robot.target = NSMakePoint(NEST_X,NEST_Y);
                                    robot.neighbors = 0;
                                    
                                    //Sum up all non-picked-up seeds in the moore neighbor.
                                    for(int dx = -1; dx <= 1; dx++) {
                                        for(int dy = -1; dy <= 1; dy++) {
                                            if((robot.carrying.x+dx>=0 && robot.carrying.x+dx<GRID_WIDTH) && (robot.carrying.y+dy>=0 && robot.carrying.y+dy<GRID_HEIGHT)) {
                                                robot.neighbors += (randomFloat(1.f) >= detectionError) && (tags[robot.carrying.y+dy][robot.carrying.x+dx] != 0) && !(tags[robot.carrying.y+dy][robot.carrying.x+dx].pickedUp);
                                            }
                                        }
                                    }
                                }
                            }
                            
                            robot.lastMoved = tick;
                            break;
                            
                            /*
                             * The robot is on its way back to the nest.
                             * It is either carrying food, or it gave up on its search and is returning to base for further instruction.
                             * Stuff like laying/assigning of pheromones is handled here.
                             */
                        case ROBOT_STATUS_RETURNING:
                            [robot move];
                            
                            //Lots of repeated code in here.
                            if(NSEqualPoints(robot.position,robot.target)) {
                                if(robot.carrying != nil) {
                                    [team setTagsCollected:team.tagsCollected+1];
                                    
                                    NSPoint perturbedTagLocation = [self perturbPosition:NSMakePoint(robot.carrying.x, robot.carrying.y)];
                                    if(randomFloat(1.) < exponentialCDF(robot.neighbors+1, team.pheromoneLayingRate)) {
                                        Pheromone* p = [[Pheromone alloc] init];
                                        p.x = perturbedTagLocation.x;
                                        p.y = perturbedTagLocation.y;
                                        p.n = 1.;
                                        p.updated = tick;
                                        [pheromones addObject:p];
                                    }
                                    
                                    //Calling getPheromone here to force decay before guard check
                                    NSPoint pheromone;
                                    if ([pheromones count] > 0) {
                                        pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:team.pheromoneDecayRate];
                                    }
                                    
                                    //pheromones may now be empty as a result of decay, so we check again here
                                    if (([pheromones count] > 0) &&
                                       (randomFloat(1.) < exponentialCDF(9 - robot.neighbors, team.pheromoneFollowingRate)) &&
                                       (randomFloat(1.) > exponentialCDF(robot.neighbors, team.siteFidelityRate))) {
                                        robot.target = [self perturbPosition:pheromone];
                                        robot.informed = ROBOT_INFORMED_PHEROMONE;
                                    }
                                    else if ((randomFloat(1.) < exponentialCDF(robot.neighbors+1, team.siteFidelityRate)) &&
                                             (([pheromones count] == 0) ||
                                              (randomFloat(1.) > exponentialCDF(robot.neighbors - 9, team.pheromoneFollowingRate)))) {
                                        robot.target = [self perturbPosition:perturbedTagLocation];
                                        robot.informed = ROBOT_INFORMED_MEMORY;
                                    }
                                    else {
                                        robot.target = edge(GRID_WIDTH,GRID_HEIGHT);
                                        robot.informed = ROBOT_INFORMED_NONE;
                                    }
                                    
                                    robot.carrying = nil;
                                }
                                else {
                                    //Calling getPheromone here to force decay before guard check
                                    NSPoint pheromone;
                                    if ([pheromones count] > 0) {
                                        pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:team.pheromoneDecayRate];
                                    }
                                    
                                    //pheromones may now be empty as a result of decay, so we check again here
                                    if ([pheromones count] > 0) {
                                        robot.target = [self perturbPosition:pheromone];
                                        robot.informed = ROBOT_INFORMED_PHEROMONE;
                                    }
                                    else {
                                        robot.target = edge(GRID_WIDTH,GRID_HEIGHT);
                                        robot.informed = ROBOT_INFORMED_NONE;
                                    }
                                }
                                
                                //The old GA used a searchTime value of >= 0 to indicated we're doing an INFORMED random walk.
                                if(robot.informed == ROBOT_INFORMED_NONE){robot.searchTime = -1;}
                                else{robot.searchTime = 0;}
                                
                                robot.status = ROBOT_STATUS_DEPARTING;
                            }
                            break;
                    }
                }
                
                if(tickRate != 0.f){[NSThread sleepForTimeInterval:tickRate];}
                if(viewDelegate != nil) {
                    if([viewDelegate respondsToSelector:@selector(updateRobots:tags:pheromones:)]) {
                        NSMutableArray* tagsArray = [[NSMutableArray alloc] init];
                        for(int y = 0; y < GRID_HEIGHT; y++) {
                            for(int x = 0; x < GRID_WIDTH; x++) {
                                if(tags[y][x]){[tagsArray addObject:tags[y][x]];}
                            }
                        }
                        [self getPheromone:pheromones atTick:tick withDecayRate:team.pheromoneDecayRate];
                        [viewDelegate updateRobots:robots tags:tagsArray pheromones:pheromones];
                    }
                }
            }
        }
    }
}


/*
 * Introduces error into the given position.
 */
-(NSPoint) perturbPosition:(NSPoint)position {
    position.x = roundf(clip(randomNormal(position.x, positionalError),0,GRID_WIDTH-1));
    position.y = roundf(clip(randomNormal(position.y, positionalError),0,GRID_HEIGHT-1));
    return position;
}


/*
 * 'Breeds' and mutates colonies.
 * There is a slight tradeoff for readability at the cost of efficiency here,
 * which has to do with the use of (and enumeration over) dictionaries.
 */
-(void) breedColonies {
    @autoreleasepool {
        Team* children[teamCount];
        for(int i = 0; i < teamCount; i++) {
            children[i] = [[Team alloc] init];
            Team* child = children[i];
            
            Team* parent[2];
            for(int j = 0; j < 2; j++) {
                Team *p1 = [colonies objectAtIndex:randomInt(teamCount)],
                *p2 = [colonies objectAtIndex:randomInt(teamCount)];
                while (p1 == p2) {p2 = [colonies objectAtIndex:randomInt(teamCount)];}
                parent[j] = (p1.tagsCollected > p2.tagsCollected) ? p1 : p2;
            }
            
            NSMutableDictionary* parameters = [child getParameters];
            for(NSString* key in [parameters allKeys]) {
                
                //Independent assortment.
                [parameters setObject:[[parent[(randomInt(100)<CROSSOVER_RATE)] getParameters] objectForKey:key] forKey:key];
                
                //Random mutations.
                if(randomInt(10)==0){
                    float val = [[parameters objectForKey:key] floatValue];
                    float sig = fabs(val) * .05;
                    val += randomNormal(0,sig);
                
                    [parameters setObject:[NSNumber numberWithFloat:val] forKey:key];
                }
            }
        
            [children[i] setParameters:parameters];
        }
        
        //Set the children to be the new set of colonies for the next generation.
        for(int i = 0; i < teamCount; i++) {
            Team* team = [colonies objectAtIndex:i];
            [team setParameters:[children[i] getParameters]];
        }
    }
}


/*
 * Creates a random distribution of tags.
 * Called at the beginning of each evaluation.
 */
-(void) initDistributionForArray:(Tag* __strong[GRID_HEIGHT][GRID_WIDTH])tags {
    for(int i = 0; i < GRID_HEIGHT; i++) {
        for(int j = 0; j < GRID_WIDTH; j++) {
            tags[i][j]=0;
        }
    }
    
    int pilesOf[tagCount]; //Key is size of pile.  Value is number of piles with this many tags.
    for(int i = 0; i < tagCount; i++){pilesOf[i]=0;}
    
    //Needs to be adjusted if doing a powerlaw distribution with tagCount != 256.
    pilesOf[1] = roundf(((tagCount / 4) * distributionPowerlaw) + (tagCount * distributionRandom));
    pilesOf[(tagCount / 64)] = roundf((tagCount / 16) * distributionPowerlaw);
    pilesOf[(tagCount / 16)] = roundf((tagCount / 64) * distributionPowerlaw);
    pilesOf[(tagCount / 4)] = roundf(distributionPowerlaw + (4 * distributionClustered));
    
    int pileCount = 0;
    NSPoint pilePoints[64]; //64 piles as a loose upper bound on number of piles.
    
    for(int size = 1; size < 65; size++) { //For each distinct size of pile.
        if(pilesOf[size] == 0){continue;}
        
        if(size == 1) {
            for(int i = 0; i < pilesOf[1]; i++) {
                int tagX,tagY;
                do {
                    tagX = randomInt(GRID_WIDTH);
                    tagY = randomInt(GRID_HEIGHT);
                } while(tags[tagY][tagX]);
                
                tags[tagY][tagX] = [[Tag alloc] initWithX:tagX andY:tagY];
            }
        }
        else {
            for(int i = 0; i < pilesOf[size]; i++) { //Place each pile.
                int pileX,pileY;
                
                int overlapping = 1;
                while(overlapping) {
                    pileX = randomIntRange(PILE_RADIUS,GRID_WIDTH-(PILE_RADIUS*2));
                    pileY = randomIntRange(PILE_RADIUS,GRID_HEIGHT-(PILE_RADIUS*2));
                    
                    //Make sure the place we picked isn't close to another pile.  Pretty naive.
                    overlapping = 0;
                    for(int j = 0; j < pileCount; j++) {
                        if(pointDistance(pilePoints[j].x,pilePoints[j].y,pileX,pileY) < PILE_RADIUS){overlapping = 1; break;}
                    }
                }
                
                pilePoints[pileCount++] = NSMakePoint(pileX,pileY);
                
                //Place each individual tag in the pile.
                for(int j = 0; j < size; j++) {
                    float maxRadius = PILE_RADIUS;
                    int tagX,tagY;
                    do {
                        float rad = randomFloat(maxRadius);
                        float dir = randomFloat(M_2PI);
                        
                        tagX = clip(roundf(pileX + (rad * cos(dir))),0,GRID_WIDTH-1);
                        tagY = clip(roundf(pileY + (rad * sin(dir))),0,GRID_HEIGHT-1);
                        
                        maxRadius += 1;
                    } while(tags[tagY][tagX]);
                    
                    tags[tagY][tagX] = [[Tag alloc] initWithX:tagX andY:tagY];
                }
            }
        }
    }
}


/*
 * Picks a pheromone out of the passed list based on a random number weighted on the pheromone strengths.
 * This might work better in Team.m, as we're passing a lot of Team related stuff.
 */
-(NSPoint) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick withDecayRate:(float)decayRate {
    float nSum = 0.f;
    
    for(int i = 0; i < [pheromones count]; i++) {
        Pheromone* pheromone = [pheromones objectAtIndex:i];
        pheromone.n = exponentialDecay(pheromone.n, tick-pheromone.updated, decayRate);
        if(pheromone.n < .001){[pheromones removeObjectAtIndex:i]; i--;}
        else {
            pheromone.updated = tick;
            nSum += pheromone.n;
        }
    }
    
    float r = randomFloat(nSum);
    for(Pheromone* pheromone in pheromones) {
        if(r < pheromone.n){return NSMakePoint(pheromone.x,pheromone.y);}
        r -= pheromone.n;
    }
    
    return NSMakePoint(-1,-1);
}


/*
 * Custom getter for averageTeam (lazy evaluation)
 */
-(Team*) averageTeam {
    Team* _averageTeam = [[Team alloc] init];
    NSMutableDictionary* parameterSums = [[NSMutableDictionary alloc] initWithCapacity:13];
    float tagSum = 0.f;
    
    for(Team* team in colonies) {
        NSMutableDictionary* parameters = [team getParameters];
        tagSum += team.tagsCollected;
        for(NSString* key in parameters) {
            float val = [[parameterSums objectForKey:key] floatValue] + [[parameters objectForKey:key] floatValue];
            [parameterSums setObject:[NSNumber numberWithFloat:val] forKey:key];
        }
    }
    
    for(NSString* key in [parameterSums allKeys]) {
        float val = [[parameterSums objectForKey:key] floatValue] / teamCount;
        [parameterSums setObject:[NSNumber numberWithFloat:val] forKey:key];
    }
    
    _averageTeam.tagsCollected = (tagSum / teamCount) / evaluationCount;
    [_averageTeam setParameters:parameterSums];
    
    return _averageTeam;
}


/*
 * Custom getter for bestTeam (lazy evaluation)
 */
-(Team*) bestTeam {
    Team* _maxTeam = [[Team alloc] init];
    int maxTags = 0;
    
    for(Team* team in colonies) {
        if(team.tagsCollected > maxTags) {
            maxTags = team.tagsCollected;
            [_maxTeam setParameters:[team getParameters]];
        }
    }
    
    _maxTeam.tagsCollected = maxTags / evaluationCount;
    
    return _maxTeam;
}

@end