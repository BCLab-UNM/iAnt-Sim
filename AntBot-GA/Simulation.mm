#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import "Simulation.h"

using namespace std;
using namespace cv;

@interface Simulation()

@end

@implementation Simulation

@synthesize teamCount, generationCount, robotCount, tagCount, evaluationCount, tickCount, exploreTime;
@synthesize distributionRandom, distributionPowerlaw, distributionClustered;
@synthesize averageTeam, bestTeam;
@synthesize pileRadius;
@synthesize crossoverRate, mutationRate, elitism;
@synthesize gridSize, nest;
@synthesize realWorldError;
@synthesize variableStepSize, uniformDirection, adaptiveWalk;
@synthesize decentralizedPheromones, wirelessRange;
@synthesize parameterFile;
@synthesize postEvaluationFile;
@synthesize delegate, viewDelegate;
@synthesize tickRate;

-(id) init {
    if(self = [super init]) {
        teamCount = 100;
        generationCount = 100;
        robotCount = 6;
        tagCount = 256;
        evaluationCount = 8;
        tickCount = 3600;
        exploreTime = 0;
        
        distributionClustered = 0.;
        distributionPowerlaw = 1.;
        distributionRandom = 0.;
        
        pileRadius = 2;
        
        crossoverRate = 1;
        mutationRate = 0.1;
        elitism = false;
        
        gridSize = NSMakeSize(125, 125);
        nest = NSMakePoint(62, 62);
        
        realWorldError = NO;
        
        variableStepSize = NO;
        uniformDirection = NO;
        adaptiveWalk = YES;
        
        decentralizedPheromones = NO;
        wirelessRange = 10;
        
        parameterFile = nil;
    }
    return self;
}

/*
 * Starts the simulation run.
 */
-(int) start {
    
    srandomdev(); //Seed random number generator.
    
    //Allocate teams and initialize parameters accordingly
    teams = [[NSMutableArray alloc] initWithCapacity:teamCount];
    for(int i = 0; i < teamCount; i++) {
        if(parameterFile) {
            [teams addObject:[[Team alloc] initWithFile:parameterFile]];
        }
        else {
            [teams addObject:[[Team alloc] initRandom]];
        }
    }
    
    //Allocate GA
    ga = [[GA alloc] initWithElitism:elitism crossover:crossoverRate andMutation:mutationRate];
    
    //Set evaluation count to 1 if using GUI
    evaluationCount = (viewDelegate != nil) ? 1 : evaluationCount;
    
    //Main loop
    for(int generation = 0; generation < generationCount; generation++) {
        
        for(Team* team in teams) {
            [team setTagsCollected:0];
            if (exploreTime > 0) {
                [team setExplorePhase:YES];
            }
            else {
                [team setExplorePhase:NO];
            }
        }
        
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_apply(evaluationCount, queue, ^(size_t idx) {
            [self runEvaluation];
        });
        
        [ga breedTeams:teams AtGeneration:generation];
        
        if(delegate) {
            
            //Technically should pass in average and best teams here.
            if([delegate respondsToSelector:@selector(finishedGeneration:)]) {
                [delegate finishedGeneration:generation];
            }
        }
    }
    
    //Run a super evaluation (100 evaluations) of the mean and best individuals and record the results in a special file.
    //Get the mean and best teams
    Team* meanTeam = [self averageTeam];
    [meanTeam setTagsCollected:0.0]; //Reset tags collected
    Team* topTeam = [self bestTeam];
    [topTeam setTagsCollected:0.0]; //Reset tags collected
    //Reset the teams array to just hold 2 individuals
    teams = [[NSMutableArray alloc] initWithCapacity:2];
    //put the mean and best teams in the teams array
    [teams addObject:meanTeam];
    [teams addObject:topTeam];
    //Evaluate the mean and best 100 times
    [self setEvaluationCount:100];
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_apply(evaluationCount, queue, ^(size_t idx) {
        @autoreleasepool {
            [self runEvaluation];
        }
    });
    //Write the results to a file.
    if(delegate) {
        [delegate writeHeadersToFile:postEvaluationFile];
        [delegate writeTeamToFile:postEvaluationFile :[teams objectAtIndex:0]];
        [delegate writeTeamToFile:postEvaluationFile :[teams objectAtIndex:1]];
    }
    
    printf("Completed\n");
    return 0;
}


/*
 * Runs a single evaluation
 */
-(void) runEvaluation {
    @autoreleasepool {
        Array2D* tags = [[Array2D alloc] initWithRows:gridSize.width cols:gridSize.height];
        [self initDistributionForArray:tags];
        
        NSMutableArray* robots = [[NSMutableArray alloc] initWithCapacity:robotCount];
        NSMutableArray* pheromones = [[NSMutableArray alloc] init];
        for(int i = 0; i < robotCount; i++){[robots addObject:[[Robot alloc] init]];}
        
        for(Team* team in teams) {
            for(int i = 0; i < gridSize.height; i++) {
                for(int j = 0; j < gridSize.width; j++) {
                    if([tags objectAtRow:i col:j] != [NSNull null]){
                        [[tags objectAtRow:i col:j] setPickedUp:NO];
                        [[tags objectAtRow:i col:j] setDiscovered:NO];
                    }
                }
            }

            for(Robot* robot in robots) {
                [robot reset];
                [robot setStepSize:(variableStepSize ? (int)floor(randomLogNormal(0, team.stepSizeVariation)) + 1 : 1)];
            }
            [pheromones removeAllObjects];
            
            for(int tick = 0; tick < tickCount; tick++) {
                for(Robot* robot in robots) {
                    
                    switch(robot.status) {
                            
                        /*
                         * The robot hasn't been initialized yet.
                         * Give it some basic starting values and then fall-through to the next state.
                         */
                        case ROBOT_STATUS_INACTIVE: {
                            robot.status = ROBOT_STATUS_DEPARTING;
                            robot.position = nest;
                            robot.target = edge(gridSize);
                            //Fallthrough to ROBOT_STATUS_DEPARTING.
                        }
                            
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
                        case ROBOT_STATUS_DEPARTING: {
                            if (tick >= exploreTime && [team explorePhase]) {
                                robot.status = ROBOT_STATUS_RETURNING;
                                [robot setTarget:nest];
                                break;
                            }
                            if((!robot.informed && (randomFloat(1.) < team.travelGiveUpProbability)) || (NSEqualPoints(robot.position, robot.target))) {
                                [robot setStatus:([team explorePhase] ? ROBOT_STATUS_EXPLORING : ROBOT_STATUS_SEARCHING)];
                                [robot turn:uniformDirection withParameters:team];
                                [robot setLastTurned:(tick + [robot delay] + 1)];
                                [robot setLastMoved:tick];
                                break;

                            }
                
                            [robot moveWithin:gridSize];
                            break;
                        }
                            
                        /*
                         * The robot is performing a random walk.
                         * It will randomly change its direction based on how long it has been searching and move in this direction.
                         * If it finds a tag, its state changes to ROBOT_STATUS_RETURNING (it brings the tag back to the nest.
                         * All site fidelity and pheromone work, however, is taken care of once the robot actually arrives at the nest.
                         */
                        case ROBOT_STATUS_SEARCHING: {
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
                                    [robot setTarget:nest];
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
                            while([robot target].x < 0 || [robot target].y < 0 || [robot target].x >= gridSize.width || [robot target].y >= gridSize.height) {
                                [robot setDirection:randomFloat(M_2PI)];
                                [robot setTarget:NSMakePoint(roundf([robot position].x + cos([robot direction])), roundf([robot position].y + sin([robot direction])))];
                            }
                            
                            [robot moveWithin:gridSize];
                            
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
                            if([robot target].x >= 0 && [robot target].y >= 0 && [robot target].x < gridSize.width && [robot target].y < gridSize.height) {
                                Tag* t = [tags objectAtRow:(int)[robot target].y col:(int)[robot target].x];
                                if(detectTag(realWorldError) && ![t isKindOfClass:[NSNull class]] && ![t pickedUp]) { //Note we use shortcircuiting here.
                                    [t setDiscovered:NO];
                                    [t setPickedUp:YES];
                                    [robot setCarrying:t];
                                    [robot setStatus:ROBOT_STATUS_RETURNING];
                                    [robot setDelay:9];
                                    [robot setTarget:nest];
                                    [robot setNeighbors:0];
                                    [robot setLocalPheromone:NSNullPoint];
                                    [robot setRecruitmentTarget:NSNullPoint];
                                    
                                    //Sum up all non-picked-up seeds in the moore neighbor.
                                    for(int dx = -1; dx <= 1; dx++) {
                                        for(int dy = -1; dy <= 1; dy++) {
                                            if((robot.carrying.x + dx >= 0 && robot.carrying.x + dx < gridSize.width) && (robot.carrying.y + dy >= 0 && robot.carrying.y + dy < gridSize.height)) {
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
                        }
                    
                        /*
                         * The robot is on its way back to the nest.
                         * It is either carrying food, or it gave up on its search and is returning to base for further instruction.
                         * Stuff like laying/assigning of pheromones is handled here.
                         */
                        case ROBOT_STATUS_RETURNING: {
                            if(tick - [robot lastMoved] <= [robot delay]) {
                                break;
                            }
                            [robot setDelay:0];
                            [robot moveWithin:gridSize];
                            
                            //Lots of repeated code in here.
                            if(NSEqualPoints(robot.position, nest)) {
                                if ([team explorePhase]){
                                    
                                    BOOL allHome = YES;
                                    for(Robot* r in robots) {
                                        if(!NSEqualPoints(r.position, nest)) {
                                            allHome = NO;
                                        }
                                    }
                                    
                                    EM em;
                                    em = [self clusterTags:[robot discoveredTags] ifAllRobotsHome:allHome];
                                    
                                    if(allHome == NO) {
                                        [robot setStatus:ROBOT_STATUS_WAITING];
                                        break;
                                    }
                                    else {
                                        //Extract means and covariance matrices
                                        Mat means = em.get<Mat>("means");
                                        vector<Mat> covs = em.get<vector<Mat>>("covs");
                                        
                                        //Calculate determinants of covs
                                        //Store results in covDeterminants
                                        double determinantSum = 0;
                                        vector<double> covDeterminants;
                                        for(Mat cov : covs) {
                                            covDeterminants.push_back(determinant(cov));
                                            determinantSum += covDeterminants.back();
                                        }

                                        //Iterate through clusters
                                        for(int i = 0; i < em.get<int>("nclusters"); i++) {
                                            //Create pheromone at centroid location
                                            Pheromone* p = [[Pheromone alloc] init];
                                            [p setX:means.at<double>(i,0)];
                                            [p setY:means.at<double>(i,1)];
                                            [p setN:1 - covDeterminants[i]/determinantSum]; //pheromone weight = 1 - det(sigma_i) / sum(det(sigma_i))
                                            [p setUpdated:tick];
                                            [pheromones addObject:p];
                                        }
                                        
                                        for (Robot* r in robots) {
                                            [r setStatus:ROBOT_STATUS_RETURNING];
                                        }
                                        
                                        [team setExplorePhase:NO];
                                    }
                                }
                    
                                if(robot.carrying != nil) {
                                    [team setTagsCollected:team.tagsCollected + 1];
                                    
                                    //Record position where tag was found, then perturb it to simulate error
                                    NSPoint tagPosition = NSMakePoint(robot.carrying.x, robot.carrying.y);
                                    NSPoint perturbedTagPosition = perturbTagPosition(realWorldError, tagPosition, gridSize);
                                    
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
                                    
                                    //If no pheromones exist, pheromone will be (-1, -1)
                                    NSPoint pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:team.pheromoneDecayRate];

                                    if(!NSEqualPoints(pheromone, NSNullPoint) &&
                                        (randomFloat(1.) < exponentialCDF(9 - robot.neighbors, team.pheromoneFollowingRate)) &&
                                        (randomFloat(1.) > exponentialCDF(robot.neighbors + 1, team.siteFidelityRate))) {
                                        robot.target = perturbTargetPosition(realWorldError, pheromone, gridSize);
                                        robot.informed = ROBOT_INFORMED_PHEROMONE;
                                    }
                                    else if((randomFloat(1.) < exponentialCDF(robot.neighbors + 1, team.siteFidelityRate)) &&
                                             (randomFloat(1.) > exponentialCDF(9 - robot.neighbors, team.pheromoneFollowingRate))) {
                                        robot.target = perturbTargetPosition(realWorldError, perturbedTagPosition, gridSize);
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
                                        robot.target = edge(gridSize);
                                        robot.informed = ROBOT_INFORMED_NONE;
                                    }
                                    
                                    robot.carrying = nil;
                                }
                                else {
                                    //If no pheromones exist, pheromone will be (-1, -1)
                                    NSPoint pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:team.pheromoneDecayRate];
                                    
                                    if(NSEqualPoints(pheromone, NSNullPoint)) {
                                        robot.target = edge(gridSize);
                                        robot.informed = ROBOT_INFORMED_NONE;
                                    }
                                    else {
                                        robot.target = perturbTargetPosition(realWorldError, pheromone, gridSize);
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
                    
                        case ROBOT_STATUS_EXPLORING: {
                            if (tick >= exploreTime) {
                                robot.status = ROBOT_STATUS_RETURNING;
                                [robot setTarget:nest];
                                break;
                            }
                            
                            if(tick - [robot lastMoved] <= [robot delay]) {
                                break;
                            }
                            [robot setDelay:0];
                            
                            int stepsRemaining = [robot stepSize] - (tick - [robot lastTurned]);
                            [robot setTarget:NSMakePoint(roundf([robot position].x+(cos(robot.direction)*stepsRemaining)),roundf([robot position].y+(sin([robot direction])*stepsRemaining)))];
                    
                            //If our current direction takes us outside the world, frantically spin around until this isn't the case.
                            while([robot target].x < 0 || [robot target].y < 0 || [robot target].x >= gridSize.width || [robot target].y >= gridSize.height) {
                                [robot setDirection:randomFloat(M_2PI)];
                                [robot setTarget:NSMakePoint(roundf([robot position].x+cos([robot direction])),roundf([robot position].y+sin([robot direction])))];
                            }
                    
                            [robot moveWithin:gridSize];
                    
                            if(stepsRemaining <= 1) {
                                [robot setStepSize:(int)round(randomLogNormal(0, team.stepSizeVariation))];
                                [robot turn:TRUE withParameters:team];
                                [robot setLastTurned:(tick + robot.delay + 1)];
                            }
                    
                            //After we've moved 1 square ahead, check one square ahead for a tag.
                            //Reusing robot.target here (without consequence, it just gets overwritten when moving).
                            [robot setTarget:NSMakePoint(roundf([robot position].x+cos([robot direction])),roundf([robot position].y+sin([robot direction])))];
                            if([robot target].x >= 0 && [robot target].y >= 0 && [robot target].x < gridSize.width && [robot target].y < gridSize.height) {
                                Tag* t = [tags objectAtRow:(int)[robot target].y col:(int)[robot target].x];
                                if(detectTag(realWorldError) && ![t isKindOfClass:[NSNull class]]) { //Note we use shortcircuiting here.
                                    [[robot discoveredTags] addObject:t];
                                    [t setDiscovered:YES];
                                    
                            
                                    
                                }
                            }
                            //[robot setInformed:ROBOT_INFORMED_PHEROMONE];
                            [robot setLastMoved:tick];
                            break;
                        }
                    
                        //This makes the robots hold their current position. NO-OP
                        case ROBOT_STATUS_WAITING:{
                            break;
                        }
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
 * Executes unsupervised clustering algorithm Expectation-Maximization (EM) on input
 * Returns trained instantiation of EM if all robots home, untrained otherwise
 */
-(cv::EM) clusterTags:(NSMutableArray*)foundTags ifAllRobotsHome:(BOOL)allHome {
    //Create aggregate array
    // (static keyword ensures value is maintained between calls)
    static NSMutableArray* totalFoundTags = [[NSMutableArray alloc] init];
    
    //Instantiate NSLock to ensure thread safety during access to totalFoundTags
    // (also done statically to save memory)
    static NSLock* threadLock = [[NSLock alloc] init];
    [threadLock lock]; //lock program
    
    //Append input to aggregate tag array
    [totalFoundTags addObjectsFromArray:foundTags];
    
    //Construct EM for k clusters, where k = sqrt(num points / 2)
    int k = round(sqrt((double)[totalFoundTags count] / 2));
    EM em = EM(k);
    
    //If all robots have returned to the nest and tags have been found, run EM on aggregate tag array
    if (allHome && [totalFoundTags count]) {
        
        Mat aggregate((int)[totalFoundTags count], 2, CV_64F); //Create [totalFoundTags count] x 2 matrix
        int counter = 0;
        //Iterate over all tags
        for (Tag* tag in totalFoundTags) {
            //Copy x and y location of tag into matrix
            aggregate.at<double>(counter, 0) = [tag x];
            aggregate.at<double>(counter, 1) = [tag y];
            counter++;
        }

        //Train EM
        em.train(aggregate);

        [totalFoundTags removeAllObjects];
    }
    
    [threadLock unlock]; //unlock program
    
    return em;
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
                    tagX = randomInt(gridSize.width);
                    tagY = randomInt(gridSize.height);
                } while([tags objectAtRow:tagY col:tagX] != [NSNull null]);
                
                [tags setObjectAtRow:tagY col:tagX to:[[Tag alloc] initWithX:tagX andY:tagY]];
            }
        }
        else {
            for(int i = 0; i < pilesOf[size]; i++) { //Place each pile.
                int pileX,pileY;
                
                int overlapping = 1;
                while(overlapping) {
                    pileX = randomIntRange(pileRadius, gridSize.width - (pileRadius * 2));
                    pileY = randomIntRange(pileRadius, gridSize.height - (pileRadius * 2));
                    
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
                        
                        tagX = clip(roundf(pileX + (rad * cos(dir))), 0, gridSize.width - 1);
                        tagY = clip(roundf(pileY + (rad * sin(dir))), 0, gridSize.height - 1);
                        
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