#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import "Simulation.h"

@implementation Simulation

@synthesize teamCount, generationCount, robotCount;
@synthesize distributionRandom, distributionPowerlaw, distributionClustered, tagCount, evaluationCount;
@synthesize averageTeam, bestTeam;
@synthesize tickRate;
@synthesize realWorldError;
@synthesize variableStepSize, uniformDirection, adaptiveWalk;
@synthesize decentralizedPheromones;
@synthesize randomizeParameters, parameterFile;
@synthesize delegate, viewDelegate;

/*
 * Starts the simulation run.
 */
-(int) start {
    
    srandomdev(); //Seed random number generator.
    
    teams = [[NSMutableArray alloc] initWithCapacity:teamCount];
    for(int i = 0; i < teamCount; i++) {
        if(randomizeParameters) {
            [teams addObject:[[Team alloc] initRandom]];
        }
        else {
            [teams addObject:[[Team alloc] initWithFile:parameterFile]];
        }
    }
    evaluationCount = (viewDelegate != nil) ? 1 : evaluationCount;
    
    for(int generation = 0; generation < generationCount; generation++) {
        
        for(Team* team in teams){team.tagsCollected = 0;}
        
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_apply(evaluationCount, queue, ^(size_t idx) {
            @autoreleasepool {
                [self runEvaluation];
            }
        });
        
        [self breedTeams];
        
        if(delegate) {
            
            //Technically should pass in average and best teams here.
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
        Array2D* tags = [[Array2D alloc] initWithRows:gridWidth cols:gridHeight];
        [self initDistributionForArray:tags];
        
        NSMutableArray* robots = [[NSMutableArray alloc] initWithCapacity:robotCount];
        NSMutableArray* pheromones = [[NSMutableArray alloc] init];
        for(int i = 0; i < robotCount; i++){[robots addObject:[[Robot alloc] init]];}
        
        for(Team* team in teams) {
            for(int i = 0; i < gridHeight; i++) {
                for(int j = 0; j < gridWidth; j++) {
                    if([tags objectAtRow:i col:j] != [NSNull null]){[[tags objectAtRow:i col:j] setPickedUp:NO];}
                }
            }
            for(Robot* robot in robots) {
                [robot reset];
                [robot setStepSize:(variableStepSize ? (int)floor(randomLogNormal(0, team.stepSizeVariation)) + 1 : 1)];
            }
            [pheromones removeAllObjects];
            
            for(int tick = 0; tick < stepCount; tick++) {
                for(Robot* robot in robots) {
                    
                    switch(robot.status) {
                            
                        /*
                         * The robot hasn't been initialized yet.
                         * Give it some basic starting values and then fall-through to the next state.
                         */
                        case ROBOT_STATUS_INACTIVE:
                            robot.status = ROBOT_STATUS_DEPARTING;
                            robot.position = NSMakePoint(nestX, nestY);
                            robot.target = edge(gridWidth, gridHeight);
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
                            if((!robot.informed && (randomFloat(1.) < team.travelGiveUpProbability)) || (NSEqualPoints(robot.position, robot.target))) {
                                [robot setStatus:ROBOT_STATUS_SEARCHING];
                                [robot turn:uniformDirection withParameters:team];
                                [robot setLastTurned:(tick + [robot delay] + 1)];
                                [robot setLastMoved:tick];
                                break;
                            }
                            
                            [robot move];
                            break;
                            
                        /*
                         * The robot is performing a random walk.
                         * It will randomly change its direction based on how long it has been searching and move in this direction.
                         * If it finds a tag, its state changes to ROBOT_STATUS_RETURNING (it brings the tag back to the nest.
                         * All site fidelity and pheromone work, however, is taken care of once the robot actually arrives at the nest.
                         */
                        case ROBOT_STATUS_SEARCHING:
                            if(tick - [robot lastMoved] <= [robot delay]) {
                                break;
                            }
                            [robot setDelay:0];
                            
                            if(randomFloat(1.) < [team searchGiveUpProbability]) {
                                if(decentralizedPheromones && !NSEqualPoints([robot localPheromone], NSNullPoint)) {
                                    [robot setTarget:[robot localPheromone]];
                                    [robot setInformed:ROBOT_INFORMED_PHEROMONE];
                                    [robot setStatus:ROBOT_STATUS_DEPARTING];
                                }
                                else {
                                    [robot setTarget:NSMakePoint(nestX, nestY)];
                                    [robot setStatus:ROBOT_STATUS_RETURNING];
                                }
                                [robot setLocalPheromone:NSNullPoint];
                                [robot setRecruitmentTarget:NSNullPoint];
                                break;
                            }
                            
                            if(decentralizedPheromones && ([robot searchTime] >= 0) && ([robot informed] == ROBOT_INFORMED_MEMORY) && [robot recruitmentTarget].x > 0) {
                                float decayedRange = exponentialDecay(wirelessRange, [robot searchTime], [team informedSearchCorrelationDecayRate]);
                                [robot broadcastPheromone:[robot recruitmentTarget] toRobots:robots atRange:decayedRange];
                            }
                            
                            int stepsRemaining = [robot stepSize] - (tick - [robot lastTurned]);
                            [robot setTarget:NSMakePoint(roundf([robot position].x + (cos(robot.direction) * stepsRemaining)), roundf([robot position].y + (sin([robot direction]) * stepsRemaining)))];
                            
                            //If our current direction takes us outside the world, frantically spin around until this isn't the case.
                            while([robot target].x < 0 || [robot target].y < 0 || [robot target].x >= gridWidth || [robot target].y >= gridHeight) {
                                [robot setDirection:randomFloat(M_2PI)];
                                [robot setTarget:NSMakePoint(roundf([robot position].x + cos([robot direction])), roundf([robot position].y + sin([robot direction])))];
                            }
                            
                            [robot move];
                            
                            if(stepsRemaining <= 1) {
                                if (variableStepSize) {
                                    [robot setStepSize:(int)round(randomLogNormal(0, team.stepSizeVariation))];
                                }
                                
                                [robot turn:uniformDirection withParameters:team];
                                [robot setLastTurned:(tick + robot.delay + 1)];
                            }
                            
                            //After we've moved 1 square ahead, check one square ahead for a tag.
                            //Reusing robot.target here (without consequence, it just gets overwritten when moving).
                            [robot setTarget:NSMakePoint(roundf([robot position].x + cos([robot direction])), roundf([robot position].y + sin([robot direction])))];
                            if([robot target].x >= 0 && [robot target].y >= 0 && [robot target].x < gridWidth && [robot target].y < gridHeight) {
                                Tag* t = [tags objectAtRow:(int)[robot target].y col:(int)[robot target].x];
                                if(detectTag(realWorldError) && ![t isKindOfClass:[NSNull class]] && ![t pickedUp]) { //Note we use shortcircuiting here.
                                    [t setPickedUp:YES];
                                    [robot setCarrying:t];
                                    [robot setStatus:ROBOT_STATUS_NEIGHBOR_SEARCH];
                                    [robot setDelay:9];
                                    [robot setTarget:NSMakePoint(nestX, nestY)];
                                    [robot setNeighbors:0];
                                    [robot setLocalPheromone:NSNullPoint];
                                    [robot setRecruitmentTarget:NSNullPoint];
                                    
                                    //Sum up all non-picked-up seeds in the moore neighbor.
                                    for(int dx = -1; dx <= 1; dx++) {
                                        for(int dy = -1; dy <= 1; dy++) {
                                            if((robot.carrying.x + dx >= 0 && robot.carrying.x + dx < gridWidth) && (robot.carrying.y + dy >= 0 && robot.carrying.y + dy < gridHeight)) {
                                                robot.neighbors += detectTag(realWorldError) &&
                                                                ([tags objectAtRow:robot.carrying.y + dy col:robot.carrying.x + dx] != [NSNull null]) &&
                                                                !([[tags objectAtRow:robot.carrying.y + dy col:robot.carrying.x + dx] pickedUp]);
                                            }
                                        }
                                    }
                                }
                            }
                            
                            [robot setLastMoved:tick];
                            break;
                         
                        /*
                         * Robot is held here to emulate neighbor search time in physical robots
                         */
                        case ROBOT_STATUS_NEIGHBOR_SEARCH:
                            if (tick - [robot lastMoved] > [robot delay]) {
                                [robot setStatus:ROBOT_STATUS_RETURNING];
                            }
                            break;
                            
                        /*
                         * The robot is on its way back to the nest.
                         * It is either carrying food, or it gave up on its search and is returning to base for further instruction.
                         * Stuff like laying/assigning of pheromones is handled here.
                         */
                        case ROBOT_STATUS_RETURNING:
                            [robot move];
                            
                            //Lots of repeated code in here.
                            if(NSEqualPoints(robot.position, robot.target)) {
                                if(robot.carrying != nil) {
                                    [team setTagsCollected:team.tagsCollected + 1];
                                    
                                    //Record position where tag was found, then perturb it to simulate error
                                    NSPoint tagPosition = NSMakePoint(robot.carrying.x, robot.carrying.y);
                                    NSPoint perturbedTagPosition = perturbTagPosition(realWorldError, tagPosition);
                                    
                                    //Add (perturbed) tag position to global pheromone array if using centralized pheromones
                                    //Use of *decentralized pheromones* guarantees that the pheromones array will always be empty, which means robots will only be recruited from the nest when using *centralized pheromones*
                                    if(!decentralizedPheromones && (randomFloat(1.) < exponentialCDF(robot.neighbors + 1, team.pheromoneLayingRate))) {
                                        Pheromone* p = [[Pheromone alloc] init];
                                        p.x = perturbedTagPosition.x;
                                        p.y = perturbedTagPosition.y;
                                        p.n = 1.;
                                        p.updated = tick;
                                        [pheromones addObject:p];
                                    }
                                    
                                    NSPoint pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:team.pheromoneDecayRate];
                                    
                                    //pheromones may now be empty as a result of decay, so we check again here
                                    if(NSEqualPoints(pheromone, NSNullPoint) &&
                                        (randomFloat(1.) < exponentialCDF(9 - robot.neighbors, team.pheromoneFollowingRate)) &&
                                        (randomFloat(1.) > exponentialCDF(robot.neighbors + 1, team.siteFidelityRate))) {
                                        robot.target = perturbTargetPosition(realWorldError, pheromone);
                                        robot.informed = ROBOT_INFORMED_PHEROMONE;
                                    }
                                    else if((randomFloat(1.) < exponentialCDF(robot.neighbors + 1, team.siteFidelityRate)) &&
                                             (randomFloat(1.) > exponentialCDF(9 - robot.neighbors, team.pheromoneFollowingRate))) {
                                        robot.target = perturbTargetPosition(realWorldError, perturbedTagPosition);
                                        robot.informed = ROBOT_INFORMED_MEMORY;
                                        //Decide whether to broadcast pheromones locally
                                        if(decentralizedPheromones && (randomFloat(1.) < exponentialCDF(robot.neighbors + 1, team.pheromoneLayingRate))) {
                                            robot.recruitmentTarget = perturbedTagPosition;
                                        }
                                        else {
                                            robot.recruitmentTarget = NSNullPoint;
                                        }
                                    }
                                    else {
                                        robot.target = edge(gridWidth, gridHeight);
                                        robot.informed = ROBOT_INFORMED_NONE;
                                    }
                                    
                                    robot.carrying = nil;
                                }
                                else {
                                    //If no pheromones exist, pheromone will be (-1, -1).
                                    NSPoint pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:team.pheromoneDecayRate];
                                    
                                    if(NSEqualPoints(pheromone, NSNullPoint)) {
                                        robot.target = edge(gridWidth, gridHeight);
                                        robot.informed = ROBOT_INFORMED_NONE;
                                    }
                                    else {
                                        robot.target = perturbTargetPosition(realWorldError, pheromone);
                                        robot.informed = ROBOT_INFORMED_PHEROMONE;
                                    }
                                }
                                
                                //The old GA used a searchTime value of >= 0 to indicated we're doing an INFORMED random walk.
                                if(robot.informed == ROBOT_INFORMED_NONE || !adaptiveWalk) {
                                    robot.searchTime = -1;
                                }
                                else {
                                    robot.searchTime = 0;
                                }
                                
                                robot.status = ROBOT_STATUS_DEPARTING;
                            }
                            break;
                    }
                }
                
                if(tickRate != 0.f){[NSThread sleepForTimeInterval:tickRate];}
                if(viewDelegate != nil) {
                    if([viewDelegate respondsToSelector:@selector(updateDisplayWindowWithRobots:team:tags:pheromones:)]) {
                        [self getPheromone:pheromones atTick:tick withDecayRate:team.pheromoneDecayRate];
                        [viewDelegate updateDisplayWindowWithRobots:[robots copy] team:team tags:[tags copy] pheromones:[pheromones copy]];
                    }
                }
            }
        }
    }
}

/*
 * 'Breeds' and mutates teams.
 * There is a slight tradeoff for readability at the cost of efficiency here,
 * which has to do with the use of (and enumeration over) dictionaries.
 */
-(void) breedTeams {
    @autoreleasepool {
        Team* children[teamCount];
        for(int i = 0; i < teamCount; i++) {
            children[i] = [[Team alloc] init];
            Team* child = children[i];
            
            //TODO pick 4 different candidates -- do tournament selection, make sure candidates + resulting parents are all different.
            Team* parent[2];
            for(int j = 0; j < 2; j++) {
                Team *p1 = [teams objectAtIndex:randomInt(teamCount)],
                *p2 = [teams objectAtIndex:randomInt(teamCount)];
                while((teamCount > 2) && (p1 == p2)){p2 = [teams objectAtIndex:randomInt(teamCount)];}
                parent[j] = (p1.tagsCollected > p2.tagsCollected) ? p1 : p2;
            }
            
            NSMutableDictionary* parameters = [child getParameters];
            for(NSString* key in [parameters allKeys]) {
                
                //Crossover.
                [parameters setObject:[[parent[(randomInt(100) < crossoverRate)] getParameters] objectForKey:key] forKey:key];
                
                //Random mutations.
                if(randomInt(10) == 0) {
                    float val = [[parameters objectForKey:key] floatValue];
                    float sig = fabs(val) * .05;
                    val += randomNormal(0, sig);
                    
                    [parameters setObject:[NSNumber numberWithFloat:val] forKey:key];
                }
            }
            
            [children[i] setParameters:parameters];
        }
        
        //Set the children to be the new set of teams for the next generation.
        for(int i = 0; i < teamCount; i++) {
            Team* team = [teams objectAtIndex:i];
            [team setParameters:[children[i] getParameters]];
        }
    }
}


/*
 * Creates a random distribution of tags.
 * Called at the beginning of each evaluation.
 */
-(void) initDistributionForArray:(Array2D*)tags {
    
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
                int tagX, tagY;
                do {
                    tagX = randomInt(gridWidth);
                    tagY = randomInt(gridHeight);
                } while([tags objectAtRow:tagY col:tagX] != [NSNull null]);
                
                [tags setObjectAtRow:tagY col:tagX to:[[Tag alloc] initWithX:tagX andY:tagY]];
            }
        }
        else {
            for(int i = 0; i < pilesOf[size]; i++) { //Place each pile.
                int pileX,pileY;
                
                int overlapping = 1;
                while(overlapping) {
                    pileX = randomIntRange(pileRadius, gridWidth - (pileRadius * 2));
                    pileY = randomIntRange(pileRadius, gridHeight - (pileRadius * 2));
                    
                    //Make sure the place we picked isn't close to another pile.  Pretty naive.
                    overlapping = 0;
                    for(int j = 0; j < pileCount; j++) {
                        if(pointDistance(pilePoints[j].x, pilePoints[j].y, pileX, pileY) < pileRadius){overlapping = 1; break;}
                    }
                }
                
                pilePoints[pileCount++] = NSMakePoint(pileX, pileY);
                
                //Place each individual tag in the pile.
                for(int j = 0; j < size; j++) {
                    float maxRadius = pileRadius;
                    int tagX, tagY;
                    do {
                        float rad = randomFloat(maxRadius);
                        float dir = randomFloat(M_2PI);
                        
                        tagX = clip(roundf(pileX + (rad * cos(dir))), 0, gridWidth - 1);
                        tagY = clip(roundf(pileY + (rad * sin(dir))), 0, gridHeight - 1);
                        
                        maxRadius += 1;
                    } while([tags objectAtRow:tagY col:tagX] != [NSNull null]);
                    
                    [tags setObjectAtRow:tagY col:tagX to:[[Tag alloc] initWithX:tagX andY:tagY]];
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
        pheromone.n = exponentialDecay(pheromone.n, tick - pheromone.updated, decayRate);
        if(pheromone.n < .001){[pheromones removeObjectAtIndex:i]; i--;}
        else {
            pheromone.updated = tick;
            nSum += pheromone.n;
        }
    }
    
    float r = randomFloat(nSum);
    for(Pheromone* pheromone in pheromones) {
        if(r < pheromone.n){return NSMakePoint(pheromone.x, pheromone.y);}
        r -= pheromone.n;
    }
    
    return NSNullPoint;
}

/*
 * Custom getter for averageTeam (lazy evaluation)
 */
-(Team*) averageTeam {
    Team* _averageTeam = [[Team alloc] init];
    NSMutableDictionary* parameterSums = [[NSMutableDictionary alloc] initWithCapacity:9];
    float tagSum = 0.f;
    
    for(Team* team in teams) {
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
    
    for(Team* team in teams) {
        if(team.tagsCollected > maxTags) {
            maxTags = team.tagsCollected;
            [_maxTeam setParameters:[team getParameters]];
        }
    }
    
    _maxTeam.tagsCollected = maxTags / evaluationCount;
    
    return _maxTeam;
}

@end