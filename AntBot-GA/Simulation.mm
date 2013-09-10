#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import "Simulation.h"

using namespace std;
using namespace cv;

@interface Simulation()

-(void) setAverageTeamFrom:(NSMutableArray*)teams;
-(void) setBestTeamFrom:(NSMutableArray*)teams;

@end

@implementation Simulation

@synthesize teamCount, generationCount, robotCount, tagCount, evaluationCount, evaluationLimit, evalCount, tickCount, exploreTime;
@synthesize distributionRandom, distributionPowerlaw, distributionClustered;
@synthesize averageTeam, bestTeam;
@synthesize pileRadius;
@synthesize crossoverRate, mutationRate, crossoverOperator, mutationOperator, elitism;
@synthesize gridSize, nest;
@synthesize realWorldError;
@synthesize variableStepSize, uniformDirection, adaptiveWalk;
@synthesize decentralizedPheromones, wirelessRange;
@synthesize parameterFile;
@synthesize delegate, viewDelegate;
@synthesize tickRate;

-(id) init {
    if(self = [super init]) {
        teamCount = 100;
        generationCount = 100;
        robotCount = 6;
        tagCount = 256;
        evaluationCount = 8;
        evaluationLimit = -1;
        evalCount = 0;
        tickCount = 3600;
        exploreTime = 0;
        
        distributionClustered = 0.;
        distributionPowerlaw = 1.;
        distributionRandom = 0.;
        
        pileRadius = 2;
        
        crossoverRate = 1.0;
        mutationRate = 0.1;
        crossoverOperator = UniformPointCrossId;
        mutationOperator = FixedVarMutId;
        elitism = true;
        
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
-(NSMutableArray*) run {
    
    srandomdev(); //Seed random number generator.
    
    //Allocate teams and initialize parameters accordingly
    NSMutableArray* teams = [[NSMutableArray alloc] initWithCapacity:teamCount];
    for(int i = 0; i < teamCount; i++) {
        if(parameterFile) {
            [teams addObject:[[Team alloc] initWithFile:parameterFile]];
        }
        else {
            [teams addObject:[[Team alloc] initRandom]];
        }
    }
    
    //If evaluationLimit is -1, make sure it does not factor into these calculations.
    if(evaluationLimit == -1){
        //Times 2 to make this so large that it will not be a limiting factor on this run.
        evaluationLimit = teamCount * generationCount * evaluationCount*2;
    }
    //If generationCount is -1, make sure it does not factor into these calculations.
    if(generationCount == -1){
        //At least one evaluation will take place per generation, so this ensures that generationCount will not be a limiting factor on this run.
        generationCount = evaluationLimit;
    }
    
    //Allocate GA
    ga = [[GA alloc] initWithElitism:elitism crossover:crossoverRate andMutation:mutationRate :mutationOperator :crossoverOperator];
    
    //Set evaluation count to 1 if using GUI
    evaluationCount = (viewDelegate != nil) ? 1 : evaluationCount;
    
    //Not the number of evaluations to perform on each individual, but a count of the total number of evaluations performed so far during this run.
    evalCount = 0;
    
    //Main loop
    for(int generation = 0; generation < generationCount && evalCount < evaluationLimit; generation++) {
        
        for(Team* team in teams) {
            [team setTagsCollected:0.];
            if (exploreTime > 0) {
                [team setExplorePhase:YES];
            }
            else {
                [team setExplorePhase:NO];
            }
        }
        
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_apply(evaluationCount, queue, ^(size_t idx) {
            [self evaluateTeams:teams];
        });
        
        //Number of evaluations performed is the number of teams times the number of evaluations per team.
        evalCount = evalCount + teamCount*evaluationCount;
        
        //Set average and best teams
        [self setAverageTeamFrom:teams];
        [self setBestTeamFrom:teams];
        
        [ga breedTeams:teams AtGeneration:generation:generationCount];
        
        if(delegate) {
            
            //Technically should pass in average and best teams here.
            if([delegate respondsToSelector:@selector(finishedGeneration:)]) {
                [delegate finishedGeneration:generation];
            }
        }
    }
    
    printf("Completed\n");
    
    //Return an evaluation of the average team from the final generation
    return [self evaluateTeam:averageTeam];
}


/*
 * Run a single evaluation
 */
-(void) evaluateTeams:(NSMutableArray*)teams {
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
                [robot setStepSize:(variableStepSize ? (int)floor(randomLogNormal(0, [team stepSizeVariation])) + 1 : 1)];
            }
            [pheromones removeAllObjects];
            
            for(int tick = 0; tick < tickCount; tick++) {
                for(Robot* robot in robots) {
                    
                    switch([robot status]) {
                            
                        /*
                         * The robot hasn't been initialized yet.
                         * Give it some basic starting values and then fall-through to the next state.
                         */
                        case ROBOT_STATUS_INACTIVE: {
                            [robot setStatus:ROBOT_STATUS_DEPARTING];
                            [robot setPosition:nest];
                            [robot setTarget:edge(gridSize)];
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
                                [robot setStatus:ROBOT_STATUS_RETURNING];
                                [robot setTarget:nest];
                                break;
                            }
                            if((![robot informed] && (randomFloat(1.) < team.travelGiveUpProbability)) || (NSEqualPoints([robot position], [robot target]))) {
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
                            
                            //Delay to emulate physical robot
                            if(tick - [robot lastMoved] <= [robot delay]) {
                                break;
                            }
                            [robot setDelay:0];
                            
                            //Probabilistically give up searching and return to the nest
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
                            
                            //Broadcast decentralized pheromones if using them
                            if(decentralizedPheromones && ([robot informed] == ROBOT_INFORMED_MEMORY) && [robot recruitmentTarget].x > 0) {
                                [robot broadcastPheromone:[robot recruitmentTarget] toRobots:robots atRange:wirelessRange];
                            }
                            
                            //Calculate end point based on step size
                            int stepsRemaining = [robot stepSize] - (tick - [robot lastTurned]);
                            [robot setTarget:NSMakePoint(roundf([robot position].x + (cos(robot.direction) * stepsRemaining)), roundf([robot position].y + (sin([robot direction]) * stepsRemaining)))];
                            
                            //If our current direction takes us outside the world, frantically spin around until this isn't the case.
                            while([robot target].x < 0 || [robot target].y < 0 || [robot target].x >= gridSize.width || [robot target].y >= gridSize.height) {
                                [robot setDirection:randomFloat(M_2PI)];
                                [robot setTarget:NSMakePoint(roundf([robot position].x + cos([robot direction])), roundf([robot position].y + sin([robot direction])))];
                            }
                            
                            //Move one cell
                            [robot moveWithin:gridSize];
                            
                            //Turn
                            if(stepsRemaining <= 1) {
                                if (variableStepSize) {
                                    [robot setStepSize:(int)round(randomLogNormal(0, [team stepSizeVariation]))];
                                }
                                
                                [robot turn:uniformDirection withParameters:team];
                                [robot setLastTurned:(tick + [robot delay] + 1)];
                            }
                            
                            //After we've moved 1 square ahead, check one square ahead for a tag.
                            //Reusing robot.target here (without consequence, it just gets overwritten when moving).
                            [robot setTarget:NSMakePoint(roundf([robot position].x + cos([robot direction])), roundf([robot position].y + sin([robot direction])))];
                            if([robot target].x >= 0 && [robot target].y >= 0 && [robot target].x < gridSize.width && [robot target].y < gridSize.height) {
                                Tag* foundTag = [tags objectAtRow:[robot target].y col:[robot target].x];
                                
                                //Note we use shortcircuiting here.
                                if(detectTag(realWorldError) && ![foundTag isKindOfClass:[NSNull class]] && ![foundTag pickedUp]) {
                                    
                                    //Perturb found tag position to simulate error
                                    NSPoint perturbedTagPosition = perturbTagPosition(realWorldError, [foundTag position], gridSize);
                                    [foundTag setPosition:perturbedTagPosition];
                                    [foundTag setDiscovered:NO];
                                    [foundTag setPickedUp:YES];
                                    [robot setDiscoveredTags:[[NSMutableArray alloc] initWithObjects:foundTag, nil]];
                                    
                                    [robot setStatus:ROBOT_STATUS_RETURNING];
                                    [robot setDelay:9];
                                    [robot setTarget:nest];
                                    [robot setLocalPheromone:NSNullPoint];
                                    [robot setRecruitmentTarget:NSNullPoint];
                                    
                                    //Sum up all non-picked-up seeds in the moore neighbor.
                                    for(int dx = -1; dx <= 1; dx++) {
                                        for(int dy = -1; dy <= 1; dy++) {
                                            
                                            //If neighboring cell is legal
                                            if(([foundTag position].x + dx >= 0 && [foundTag position].x + dx < gridSize.width) &&
                                               ([foundTag position].y + dy >= 0 && [foundTag position].y + dy < gridSize.height))
                                            {
                                                //Look up tag in tags array
                                                id neighboringTag = [tags objectAtRow:[foundTag position].y + dy col:[foundTag position].x + dx];
                                                
                                                //If tag exists and is detectable
                                                if ((neighboringTag != [NSNull null]) && !([neighboringTag pickedUp]) && detectTag(realWorldError)) {
                                                    //Add it to discoveredTags array
                                                    [[robot discoveredTags] addObject:neighboringTag];
                                                }
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
                                            Pheromone* p = [[Pheromone alloc] initWithPosition:NSMakePoint(means.at<double>(i,0), means.at<double>(i,1))
                                                                                        weight:1 - covDeterminants[i]/determinantSum andUpdatedTick:tick];
                                            [pheromones addObject:p];
                                        }
                                        
                                        for (Robot* r in robots) {
                                            [r setStatus:ROBOT_STATUS_RETURNING];
                                        }
                                        
                                        [team setExplorePhase:NO];
                                    }
                                }
                                
                                else {
                                    //Retrieve collected tag from discoveredTags array (if available)
                                    Tag* foundTag = nil;
                                    if ([[robot discoveredTags] count] > 0) {
                                        foundTag = [[robot discoveredTags] objectAtIndex:0];
                                        [team setTagsCollected:[team tagsCollected] + 1];
                                    }
                                    
                                    //Add (perturbed) tag position to global pheromone array if using centralized pheromones
                                    //Use of *decentralized pheromones* guarantees that the pheromones array will always be empty, which means robots will only be recruited from the nest when using *centralized pheromones*
                                    if (foundTag && !decentralizedPheromones &&
                                        (randomFloat(1.) < poissonCDF([[robot discoveredTags] count], [team pheromoneLayingRate]))) {
                                        Pheromone* p = [[Pheromone alloc] initWithPosition:[foundTag position] weight:1. andUpdatedTick:tick];
                                        [pheromones addObject:p];
                                    }

                                    
                                    //Set required local variables
                                    BOOL siteFidelityFlag = randomFloat(1.) < poissonCDF([[robot discoveredTags] count], [team siteFidelityRate]);
                                    NSPoint pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:[team pheromoneDecayRate]];
                                    
                                    //If a tag was found, decide whether to return to its location
                                    if(foundTag && siteFidelityFlag) {
                                        [robot setTarget:perturbTargetPosition(realWorldError, [foundTag position], gridSize)];
                                        [robot setInformed:ROBOT_INFORMED_MEMORY];
                                        //Decide whether to broadcast pheromones locally
                                        if(decentralizedPheromones &&
                                           (randomFloat(1.) < exponentialCDF([[robot discoveredTags] count], [team pheromoneLayingRate]))) {
                                            [robot setRecruitmentTarget:[foundTag position]];
                                        }
                                        else {
                                            [robot setRecruitmentTarget:NSNullPoint];
                                        }
                                    }
                                    
                                    //If no pheromones exist, pheromone will be (-1, -1)
                                    else if(!NSEqualPoints(pheromone, NSNullPoint) && !siteFidelityFlag) {
                                        [robot setTarget:perturbTargetPosition(realWorldError, pheromone, gridSize)];
                                        [robot setInformed:ROBOT_INFORMED_PHEROMONE];
                                    }
                                    
                                    //If no pheromones and no tag, go to a random location
                                    else {
                                        [robot setTarget:edge(gridSize)];
                                        [robot setInformed:ROBOT_INFORMED_NONE];
                                    }
                                    
                                    [robot setDiscoveredTags:nil];
                                    [robot setSearchTime:0];
                                    [robot setStatus:ROBOT_STATUS_DEPARTING];
                                }
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

                            [robot setLastMoved:tick];
                            break;
                        }
                    
                        //This makes the robots hold their current position (i.e. NO-OP)
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
 * Run 100 post evaluations of the average team from the final generation (i.e. generationCount)
 */
-(NSMutableArray*) evaluateTeam:(Team*)team {
    NSMutableArray* tagsCollected = [[NSMutableArray alloc] init];
    NSMutableArray* teams = [[NSMutableArray alloc] initWithObjects:averageTeam, nil];
    
    for (int i = 0; i < 100; i++) {
        
        //Reset
        [averageTeam setTagsCollected:0.];
        if (exploreTime > 0) {
            [team setExplorePhase:YES];
        }
        else {
            [team setExplorePhase:NO];
        }
        
        //Evaluate
        [self evaluateTeams:teams];
        [tagsCollected addObject:[NSNumber numberWithFloat:[averageTeam tagsCollected]]];
    }
    
    return tagsCollected;
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
            aggregate.at<double>(counter, 0) = [tag position].x;
            aggregate.at<double>(counter, 1) = [tag position].y;
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
        if(r < pheromone.n) {
            return [pheromone position];
        }
        r -= pheromone.n;
    }
    
    return NSNullPoint;
}

/*
 * Custom getter for averageTeam (lazy evaluation)
 */
-(void) setAverageTeamFrom:(NSMutableArray*)teams {
    averageTeam = [[Team alloc] init];
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
    
    [averageTeam setTagsCollected:(tagSum / teamCount) / evaluationCount];
    [averageTeam setParameters:parameterSums];
}


/*
 * Custom getter for bestTeam (lazy evaluation)
 */
-(void) setBestTeamFrom:(NSMutableArray*)teams {
    bestTeam = [[Team alloc] init];
    float maxTags = -1.;
    
    for(Team* team in teams) {
        if(team.tagsCollected > maxTags) {
            maxTags = team.tagsCollected;
            [bestTeam setParameters:[team getParameters]];
        }
    }
    
    [bestTeam setTagsCollected:maxTags / evaluationCount];
}


/*
 * Custom getter for all @properties of Simulation
 */
-(NSMutableDictionary*) getParameters {
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] initWithObjects:
            [NSArray arrayWithObjects:
             [NSNumber numberWithInt:teamCount],
             [NSNumber numberWithInt:generationCount],
             [NSNumber numberWithInt:robotCount],
             [NSNumber numberWithInt:tagCount],
             [NSNumber numberWithInt:evaluationCount],
             [NSNumber numberWithInt:tickCount],
             [NSNumber numberWithInt:exploreTime],
             
             [NSNumber numberWithFloat:distributionRandom],
             [NSNumber numberWithFloat:distributionPowerlaw],
             [NSNumber numberWithFloat:distributionClustered],
             
             [NSNumber numberWithInt:pileRadius],
             
             [NSNumber numberWithFloat:crossoverRate],
             [NSNumber numberWithFloat:mutationRate],
             [NSNumber numberWithBool:elitism],

             NSStringFromSize(gridSize),
             NSStringFromPoint(nest),
             
             [NSNumber numberWithBool:realWorldError],
             
             [NSNumber numberWithBool:variableStepSize],
             [NSNumber numberWithBool:uniformDirection],
             [NSNumber numberWithBool:adaptiveWalk],
             
             [NSNumber numberWithBool:decentralizedPheromones],
             [NSNumber numberWithInt:wirelessRange], nil] forKeys:
            [NSArray arrayWithObjects:
             @"teamCount",
             @"generationCount",
             @"robotCount",
             @"tagCount",
             @"evaluationCount",
             @"tickCount",
             @"exploreTime",
             
             @"distributionRandom",
             @"distributionPowerlaw",
             @"distributionClustered",
             
             @"pileRadius",
             
             @"crossoverRate",
             @"mutationRate",
             @"elitism",
             
             @"gridSize",
             @"nest",
             
             @"realWorldError",
             
             @"variableStepSize",
             @"uniformDirection",
             @"adaptiveWalk",
             
             @"decentralizedPheromones",
             @"wirelessRange", nil]];
    
    return parameters;
}

/*
 * Custom setter for all @properties of Simulation
 */
-(void) setParameters:(NSMutableDictionary *)parameters {
    teamCount = [[parameters objectForKey:@"teamCount"] intValue];
    generationCount = [[parameters objectForKey:@"generationCount"] intValue];
    robotCount = [[parameters objectForKey:@"robotCount"] intValue];
    tagCount = [[parameters objectForKey:@"tagCount"] intValue];
    evaluationCount = [[parameters objectForKey:@"evaluationCount"] intValue];
    tickCount = [[parameters objectForKey:@"tickCount"] intValue];
    exploreTime = [[parameters objectForKey:@"exploreTime"] intValue];
    
    distributionRandom = [[parameters objectForKey:@"distributionRandom"] floatValue];
    distributionPowerlaw = [[parameters objectForKey:@"distributionPowerlaw"] floatValue];
    distributionClustered = [[parameters objectForKey:@"distributionClustered"] floatValue];
    
    pileRadius = [[parameters objectForKey:@"pileRadius"] intValue];
    
    crossoverRate = [[parameters objectForKey:@"crossoverRate"] floatValue];
    mutationRate = [[parameters objectForKey:@"mutationRate"] floatValue];
    elitism = [[parameters objectForKey:@"elitism"] boolValue];
    
    gridSize = NSSizeFromString([parameters objectForKey:@"gridSize"]);
    nest = NSPointFromString([parameters objectForKey:@"nest"]);
    
    realWorldError = [[parameters objectForKey:@"realWorldError"] boolValue];
    
    variableStepSize = [[parameters objectForKey:@"variableStepSize"] boolValue];
    uniformDirection = [[parameters objectForKey:@"uniformDirection"] boolValue];
    adaptiveWalk = [[parameters objectForKey:@"adaptiveWalk"] boolValue];
    
    decentralizedPheromones = [[parameters objectForKey:@"decentralizedPheromones"] boolValue];
    wirelessRange = [[parameters objectForKey:@"wirelessRange"] boolValue];
}



@end