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

@synthesize teamCount, generationCount, robotCount, tagCount, evaluationCount, evaluationLimit, tickCount, exploreTime;
@synthesize distributionRandom, distributionPowerlaw, distributionClustered;
@synthesize averageTeam, bestTeam;
@synthesize pileRadius;
@synthesize crossoverRate, mutationRate, selectionOperator, crossoverOperator, mutationOperator, elitism;
@synthesize gridSize, nest;
@synthesize variableStepSize, uniformDirection, adaptiveWalk;
@synthesize decentralizedPheromones, wirelessRange;
@synthesize parameterFile;
@synthesize error, observedError;
@synthesize delegate, viewDelegate;
@synthesize tickRate;

int simTime;
@synthesize deadCount;

-(id) init {
    if(self = [super init]) {
        teamCount = 100;
        generationCount = 100;
        robotCount = 6;
        tagCount = 256;
        evaluationCount = 1;
        evaluationLimit = -1;
        tickCount = 7200;
        simTime = tickCount;
        exploreTime = 0;
        
        distributionClustered = 1.;
        distributionPowerlaw = 0.;
        distributionRandom = 0.;
        
        pileRadius = 2;
        
        crossoverRate = 1.0;
        mutationRate = 0.1;
        selectionOperator  = TournamentSelectionId;
        crossoverOperator = UniformPointCrossId;
        mutationOperator = FixedVarMutId;
        elitism = YES;
        
        gridSize = NSMakeSize(125, 125);
        nest = NSMakePoint(62, 62);
        
        variableStepSize = NO;
        uniformDirection = NO;
        adaptiveWalk = YES;
        
        decentralizedPheromones = NO;
        wirelessRange = 10;
        
        parameterFile = nil;
        
        observedError = YES;
        
        deadCount = 0;
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
    
    //Allocate and initialize error model
    if (observedError) {
        error = [[SensorError alloc] initObserved];
    }
    else {
        error = [[SensorError alloc] init];
    }
    
    //Initialize average and best teams
    [self setAverageTeamFrom:teams];
    [self setBestTeamFrom:teams];
    
    //If evaluationLimit is -1, make sure it does not factor into these calculations.
    if(evaluationLimit == -1){
        //Times 2 to make this so large that it will not be a limiting factor on this run.
        evaluationLimit = teamCount * generationCount * evaluationCount * 2;
    }
    //If generationCount is -1, make sure it does not factor into these calculations.
    if(generationCount == -1){
        //At least one evaluation will take place per generation, so this ensures that generationCount will not be a limiting factor on this run.
        generationCount = evaluationLimit;
    }
    
    //Set up GA
    ga = [[GA alloc] initWithElitism:elitism selectionOperator:selectionOperator crossoverRate:crossoverRate crossoverOperator:crossoverOperator mutationRate:mutationRate andMutationOperator:mutationOperator];
    
    //Set evaluation count to 1 if using GUI
    evaluationCount = (viewDelegate != nil) ? 1 : evaluationCount;
    
    //Not the number of evaluations to perform on each individual, but a count of the total number of evaluations performed so far during this run.
    int evalCount = 0;
    
    //Allocate and initialize cellular grids
    NSMutableArray* grids = [[NSMutableArray alloc] initWithCapacity:evaluationCount];
    for (int i = 0; i < evaluationCount; i++) {
        Array2D* grid = [[Array2D alloc] initWithRows:gridSize.height cols:gridSize.width objClass:[Cell class]];
        [grids addObject:grid];
    }
    
    //Main loop
    for(int generation = 0; generation < generationCount && evalCount < evaluationLimit; generation++) {
        
        for(Team* team in teams) {
            [team setFitness:0.];
            if (exploreTime > 0) {
                [team setExplorePhase:YES];
            }
            else {
                [team setExplorePhase:NO];
            }
        }
        
        if (evaluationCount > 1) {
            dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
            dispatch_apply(evaluationCount, queue, ^(size_t iteration) {
                [self evaluateTeams:teams onGrid:[grids objectAtIndex:iteration]];
            });
        }
        else {
            [self evaluateTeams:teams onGrid:[grids objectAtIndex:0]];
        }
        
        //Number of evaluations performed is the number of teams times the number of evaluations per team.
        evalCount = evalCount + teamCount*evaluationCount;
        
        //Set average and best teams
        [self setAverageTeamFrom:teams];
        [self setBestTeamFrom:teams];
        
        [ga breedPopulation:teams AtGeneration:generation andMaxGeneration:generationCount];
        
        if(delegate) {
            
            //Technically should pass in average and best teams here.
            if([delegate respondsToSelector:@selector(finishedGeneration:atEvaluation:)]) {
                [delegate finishedGeneration:generation atEvaluation:evalCount];
            }
        }
    }
    
    printf("Completed\n");
    
    //Return an evaluation of the average team from the final generation
    return [self evaluateTeam:averageTeam onGrid:[grids objectAtIndex:0]];
}


/*
 * Run a single evaluation
 */
-(void) evaluateTeams:(NSMutableArray*)teams onGrid:(Array2D*)grid {
    @autoreleasepool {
        [self initDistributionForArray:grid];
        
        NSMutableArray* robots = [[NSMutableArray alloc] initWithCapacity:robotCount];
        NSMutableArray* pheromones = [[NSMutableArray alloc] init];
        NSMutableArray* regions = [[NSMutableArray alloc] init];
        NSMutableArray* unexploredRegions = [[NSMutableArray alloc] init];
        NSMutableArray* clusters = [[NSMutableArray alloc] init];
//        int scheduledClusterings = 2;
//        int numberOfClusterings = 0;
//        int reclusteringInterval = tickCount / scheduledClusterings;
        for(int i = 0; i < robotCount; i++){[robots addObject:[[Robot alloc] init]];}
        
        for(Team* team in teams) {
            
            for(Cell* cell in grid) {
                [cell setIsClustered:NO];
                if([cell tag]) {
                    [[cell tag] setDiscovered:NO];
                    [[cell tag] setPickedUp:NO];
                }
            }
            
            for(Robot* robot in robots) {
                [robot reset];
                if (variableStepSize) {
                    [robot setStepSize:(int)round(randomLogNormal(0, [team stepSizeVariation]))];
                }
            }
            
            [pheromones removeAllObjects];
            [unexploredRegions removeAllObjects];
            [clusters removeAllObjects];
            [regions removeAllObjects];
            
            for(int tick = 0; tick < tickCount; tick++) {
                
                int tagsFound = [self stateTransition:robots inTeam:team atTick:tick onGrid:grid withPheromones:pheromones clusters:clusters regions:regions unexploredRegions:unexploredRegions];
                
                [team setFitness:[team fitness] + tagsFound];
                
                //////////////POWER STUFF///////////////
                //printf("%d dead      ", [team casualties]);
                //printf("%f tags\n", [team fitness]);
                [team setCasualties:[team casualties] + deadCount];
                //////////////POWER STUFF///////////////
            
                if(tickRate != 0.f){[NSThread sleepForTimeInterval:tickRate];}
                if(viewDelegate != nil) {
                    if([viewDelegate respondsToSelector:@selector(updateDisplayWindowWithRobots:team:grid:pheromones:regions:clusters:)]) {
                        [Pheromone getPheromone:pheromones atTick:tick];
                        [viewDelegate updateDisplayWindowWithRobots:[robots copy] team:team grid:[grid copy] pheromones:[pheromones copy] regions:[unexploredRegions copy] clusters:[clusters copy]];
                    }
                }
            }
        }
    }
}

/*
 * State transition case statement for robots using central-place foraging algorithm
 */
-(int) stateTransition:(NSMutableArray*)robots inTeam:(Team*)team atTick:(int)tick onGrid:(Array2D*)grid
         withPheromones:(NSMutableArray*)pheromones
               clusters:(NSMutableArray*)clusters
                regions:(NSMutableArray*)regions
      unexploredRegions:(NSMutableArray*)unexploredRegions {
    
    int tagsFound = 0;
    
    for (Robot* robot in robots) {
        
        //////////////POWER STUFF///////////////
        if(robot.isDead == TRUE){           // IF YOU REMOVE DEAD ROBOT FROM ARRAY, ALL HELL BREAKS LOOSE SO JUST DONT ALLOW MOVEMENT
            continue;
        }
        //////////////POWER STUFF///////////////
        
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
                if([robot informed] == ROBOT_INFORMED_DECOMPOSITION && (NSEqualPoints([robot position], [robot target]))) {
                    [robot setStatus:ROBOT_STATUS_SEARCHING];
                    [robot setInformed:ROBOT_INFORMED_NONE];
                    [robot turn:uniformDirection withParameters:team];
                    [robot setLastTurned:(tick + [robot delay] + 1)];
                    [robot setLastMoved:tick];
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
                
                //////////////POWER STUFF///////////////
                [robot dischargeBattery:tick];
                //////////////POWER STUFF///////////////
                
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
                
                //////////////POWER STUFF///////////////
                if(randomFloat(1.0) < rayleighCDF((1 - robot.batteryLevel), team.powerReturnSigma, team.powerReturnShift)){
                    
                    //printf("SIGMA   %f    SHIFT   %f\n", team.powerReturnSigma, team.powerReturnShift);
                    [robot setTarget:nest];
                    robot.needsCharging = true;
                    robot.status = ROBOT_STATUS_RETURNING;
                    break;
                    
                }
                //////////////POWER STUFF///////////////
                
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
                
                //////////////POWER STUFF///////////////
                [robot dischargeBattery:tick];
                //////////////POWER STUFF///////////////
                
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
                    Tag* foundTag = [(Cell*)[grid objectAtRow:[robot target].y col:[robot target].x] tag];
                    //Note we use shortcircuiting here.
                    if([error detectTag] && foundTag && ![foundTag pickedUp]) {
                        //Perturb found tag position to simulate error
                        NSPoint perturbedTagPosition = [error perturbTagPosition:[foundTag position] withGridSize:gridSize andGridCenter:nest];
                        Tag* tagCopy = [foundTag copy];
                        [tagCopy setPosition:perturbedTagPosition];
                        
                        [robot setDiscoveredTags:[[NSMutableArray alloc] initWithObjects:tagCopy, nil]];
                        [foundTag setPickedUp:YES];
                        
                        //Sum up all non-picked-up seeds in the moore neighbor.
                        for(int dx = -1; dx <= 1; dx++) {
                            for(int dy = -1; dy <= 1; dy++) {
                                
                                //If neighboring cell is legal
                                if(([foundTag position].x + dx >= 0 && [foundTag position].x + dx < gridSize.width) &&
                                   ([foundTag position].y + dy >= 0 && [foundTag position].y + dy < gridSize.height))
                                {
                                    //Look up tag in tags array
                                    Cell* cell = [grid objectAtRow:[foundTag position].y + dy col:[foundTag position].x + dx];
                                    
                                    //If tag exists and is detectable
                                    if (([cell tag]) && !([[cell tag] pickedUp]) && [error detectTag]) {
                                        //Add it to discoveredTags array
                                        [[robot discoveredTags] addObject:[cell tag]];
                                    }
                                }
                            }
                        }
                        
                        [robot setStatus:ROBOT_STATUS_RETURNING];
                        [robot setDelay:9];
                        [robot setTarget:nest];
                        [robot setLocalPheromone:NSNullPoint];
                        [robot setRecruitmentTarget:NSNullPoint];
                    }
                }
                
                [robot setLastMoved:tick];
                break;
            }
                
                //////////////POWER STUFF///////////////
                /*
                 The robot has returned to the nest for battery charging
                 */
            case ROBOT_STATUS_CHARGING:
                
                if(randomFloat(1.0) < rayleighCDF(robot.batteryLevel, team.chargeActiveSigma, 0.0)){
                    
                    //printf("CHARGE SIGMA   %f\n", team.chargeActiveSigma);
                    robot.status = ROBOT_STATUS_DEPARTING;
                    break;
                    
                } else {
                    
                    //printf("CHARGING ");
                    [robot chargeBattery];
                    break;
                    
                }
                //////////////POWER STUFF///////////////
                
                /*
                 * The robot is on its way back to the nest.
                 * It is either carrying food, or it gave up on its search and is returning to base for further instruction.
                 * Stuff like laying/assigning of pheromones is handled here.
                 */
            case ROBOT_STATUS_RETURNING: {
                if(tick - [robot lastMoved] <= [robot delay]) {
                    break;
                }
                //                            if(tick >= reclusteringInterval && numberOfClusterings < scheduledClusterings) {
                //                                [team setExplorePhase:YES];
                //                            }
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
                            
                            cv::Size meansSize = means.size();
                            
                            for(int i = 0; i < meansSize.height; i++) {
                                NSPoint p = NSMakePoint(round(means.at<double>(i,0)), round(means.at<double>(i,1)));
                                double width = ceil(covs[i].at<double>(0,0) * 2);
                                double height = ceil(covs[i].at<double>(1,1) * 2);
                                Cluster* c = [[Cluster alloc] initWithCenter:p width:width andHeight:height];
                                [clusters addObject:c];
                                for(int j = clip(p.x - ceil(width/2),0,gridSize.width); j < clip(p.x + ceil(width/2),0,gridSize.width); j++) {
                                    for(int k= clip(p.y-ceil(height/2),0,gridSize.height); k<clip(p.y + ceil(height/2),0,gridSize.height); k++) {
                                        [(Cell*)[grid objectAtRow:j col:k] setIsClustered:YES];
                                    }
                                }
                            }
                            
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
                                Pheromone* p = [[Pheromone alloc] initWithPosition:NSMakePoint(means.at<double>(i,0), means.at<double>(i,1)) weight:1 - covDeterminants[i]/determinantSum decayRate:[team pheromoneDecayRate] andUpdatedTick:tick];
                                [pheromones addObject:p];
                            }
                            
                            for (Robot* r in robots) {
                                [r setStatus:ROBOT_STATUS_RETURNING];
                            }
                            
                            [team setExplorePhase:NO];
                            
                            //numberOfClusterings++;
                            
                            NSPoint origin;
                            origin.x = 0;
                            origin.y = 0;
                            QuadTree* tree = [[QuadTree alloc] initWithHeight:gridSize.height width:gridSize.width origin:origin andCells:grid];
                            [regions addObject:tree];
                            [unexploredRegions addObjectsFromArray:[Decomposition runDecomposition:regions]];
                        }
                    }
                    
                    else {
                        //Retrieve collected tag from discoveredTags array (if available)
                        Tag* foundTag = nil;
                        if ([[robot discoveredTags] count] > 0) {
                            foundTag = [[robot discoveredTags] objectAtIndex:0];
                            tagsFound++;
                        }
                        
                        //Add (perturbed) tag position to global pheromone array if using centralized pheromones
                        //Use of *decentralized pheromones* guarantees that the pheromones array will always be empty, which means robots will only be recruited from the nest when using *centralized pheromones*
                        if (foundTag && !decentralizedPheromones &&
                            (randomFloat(1.) < poissonCDF([[robot discoveredTags] count], [team pheromoneLayingRate]))) {
                            Pheromone* p = [[Pheromone alloc] initWithPosition:[foundTag position] weight:1. decayRate:[team pheromoneDecayRate] andUpdatedTick:tick];
                            [pheromones addObject:p];
                        }
                        
                        
                        //Set required local variables
                        BOOL siteFidelityFlag = randomFloat(1.) < poissonCDF([[robot discoveredTags] count], [team siteFidelityRate]);
                        BOOL decompositionAllocFlag = randomFloat(1.) > [team decompositionAllocProbability];
                        NSPoint pheromone = [Pheromone getPheromone:pheromones atTick:tick];
                        
                        //If a tag was found, decide whether to return to its location
                        if(foundTag && siteFidelityFlag) {
                            [robot setTarget:[error perturbTargetPosition:[foundTag position] withGridSize:gridSize andGridCenter:nest]];
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
                            [robot setTarget:[error perturbTargetPosition:pheromone withGridSize:gridSize andGridCenter:nest]];
                            [robot setInformed:ROBOT_INFORMED_PHEROMONE];
                        }
                        
                        else if(([unexploredRegions count] > 0) && decompositionAllocFlag) {
                            int regionChoice = arc4random() % [unexploredRegions count];
                            QuadTree* tree = [unexploredRegions objectAtIndex:regionChoice];
                            NSPoint target;
                            target.x = [tree origin].x + [tree width] / 2;
                            target.y = [tree origin].y + [tree height] / 2;
                            [robot setTarget:[error perturbTargetPosition:target withGridSize:gridSize andGridCenter:nest]];
                            [robot setInformed:ROBOT_INFORMED_DECOMPOSITION];
                        }
                        
                        
                        //If no pheromones and no tag and no partitioning knowledge, go to a random location
                        else {
                            [robot setTarget:edge(gridSize)];
                            [robot setInformed:ROBOT_INFORMED_NONE];
                        }
                        
                        [robot setDiscoveredTags:nil];
                        [robot setSearchTime:0];
                        
                        //////////////POWER STUFF///////////////
                        if(robot.needsCharging){
                            
                            //printf("STATUS CHANGED TO CHARGING\n");
                            robot.status = ROBOT_STATUS_CHARGING;
                            
                        } else {
                            
                            robot.status = ROBOT_STATUS_DEPARTING;
                            
                        }
                        //////////////POWER STUFF///////////////
                        
                    }
                }
                break;
            }
                
            case ROBOT_STATUS_EXPLORING: {
                if (tick >= exploreTime) {
                    robot.status = ROBOT_STATUS_RETURNING;
                    [robot setStepSize:(variableStepSize ? (int)round(randomLogNormal(0, team.stepSizeVariation)) : 1)];
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
                    [robot setStepSize:(int)round(randomLogNormal(0, [team stepSizeVariation]))];
                    [robot turn:TRUE withParameters:team];
                    [robot setLastTurned:(tick + robot.delay + 1)];
                }
                
                //After we've moved 1 square ahead, check one square ahead for a tag.
                //Reusing robot.target here (without consequence, it just gets overwritten when moving).
                [robot setTarget:NSMakePoint(roundf([robot position].x+cos([robot direction])),roundf([robot position].y+sin([robot direction])))];
                if([robot target].x >= 0 && [robot target].y >= 0 && [robot target].x < gridSize.width && [robot target].y < gridSize.height) {
                    Tag* t = [(Cell*)[grid objectAtRow:(int)[robot target].y col:(int)[robot target].x] tag];
                    if([error detectTag] && t) { //Note we use shortcircuiting here.
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
        
    return tagsFound;
}

/*
 * Run 100 post evaluations of the average team from the final generation (i.e. generationCount)
 */
-(NSMutableArray*) evaluateTeam:(Team*)team onGrid:(Array2D *)grid {
    NSMutableArray* fitness = [[NSMutableArray alloc] init];
    NSMutableArray* teams = [[NSMutableArray alloc] initWithObjects:averageTeam, nil];
    
    for (int i = 0; i < 100; i++) {
        
        //Reset
        [averageTeam setFitness:0.];
        if (exploreTime > 0) {
            [team setExplorePhase:YES];
        }
        else {
            [team setExplorePhase:NO];
        }
        
        //Evaluate
        [self evaluateTeams:teams onGrid:grid];
        [fitness addObject:[NSNumber numberWithFloat:[averageTeam fitness]]];
    }
    
    return fitness;
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
-(void) initDistributionForArray:(Array2D*)grid {
    
    for(Cell* cell in grid) {
        [cell setTag:nil];
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
    
    for(int size = 1; size <= (tagCount / 4); size++) { //For each distinct size of pile.
        if (size >= tagCount) {
            break;
        }
        
        if(pilesOf[size] == 0) {
            continue;
        }
        
        if(size == 1) {
            for(int i = 0; i < pilesOf[1]; i++) {
                int tagX, tagY;
                do {
                    tagX = randomInt(gridSize.width);
                    tagY = randomInt(gridSize.height);
                } while([(Cell*)[grid objectAtRow:tagY col:tagX] tag]);
                
                [(Cell*)[grid objectAtRow:tagY col:tagX] setTag:[[Tag alloc] initWithX:tagX andY:tagY]];
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
                    } while([(Cell*)[grid objectAtRow:tagY col:tagX] tag]);
                    
                    [(Cell*)[grid objectAtRow:tagY col:tagX] setTag:[[Tag alloc] initWithX:tagX andY:tagY]];
                }
            }
        }
    }
}

/*
 * Custom getter for averageTeam (lazy evaluation)
 */
-(void) setAverageTeamFrom:(NSMutableArray*)teams {
    averageTeam = [[Team alloc] init];
    NSMutableDictionary* parameterSums = [[NSMutableDictionary alloc] init];
    float tagSum = 0.f;
    
    for(Team* team in teams) {
        NSMutableDictionary* parameters = [team getParameters];
        tagSum += [team fitness];
        for(NSString* key in parameters) {
            float val = [[parameterSums objectForKey:key] floatValue] + [[parameters objectForKey:key] floatValue];
            [parameterSums setObject:[NSNumber numberWithFloat:val] forKey:key];
        }
    }
    
    for(NSString* key in [parameterSums allKeys]) {
        float val = [[parameterSums objectForKey:key] floatValue] / teamCount;
        [parameterSums setObject:[NSNumber numberWithFloat:val] forKey:key];
    }
    
    [averageTeam setFitness:(tagSum / teamCount) / evaluationCount];
    [averageTeam setParameters:parameterSums];
}


/*
 * Custom getter for bestTeam (lazy evaluation)
 */
-(void) setBestTeamFrom:(NSMutableArray*)teams {
    bestTeam = [[Team alloc] init];
    float maxTags = -1.;
    
    for(Team* team in teams) {
        if([team fitness] > maxTags) {
            maxTags = [team fitness];
            [bestTeam setParameters:[team getParameters]];
        }
    }
    
    [bestTeam setFitness:maxTags / evaluationCount];
}


#pragma Archivable methods

/*
 * Getter for all @properties of Simulation
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
             
             @"variableStepSize",
             @"uniformDirection",
             @"adaptiveWalk",
             
             @"decentralizedPheromones",
             @"wirelessRange", nil]];
    
    return parameters;
}

/*
 * Setter for all @properties of Simulation
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
    
    variableStepSize = [[parameters objectForKey:@"variableStepSize"] boolValue];
    uniformDirection = [[parameters objectForKey:@"uniformDirection"] boolValue];
    adaptiveWalk = [[parameters objectForKey:@"adaptiveWalk"] boolValue];
    
    decentralizedPheromones = [[parameters objectForKey:@"decentralizedPheromones"] boolValue];
    wirelessRange = [[parameters objectForKey:@"wirelessRange"] boolValue];
}

-(void)writeParametersToFile:(NSString *)file {
    //unused
}

+(void)writeParameterNamesToFile:(NSString *)file {
    //unused
}

//////////////POWER STUFF///////////////
+(int) getSimTicks {
    return simTime;
}
//////////////POWER STUFF///////////////


@end