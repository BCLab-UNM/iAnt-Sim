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

@synthesize teamCount, generationCount, robotCount, tagCount, evaluationCount, evaluationLimit, postEvaluations, tickCount, clusteringTagCutoff;
@synthesize useTravel, useGiveUp, useSiteFidelity, usePheromone, useInformedWalk, useRecruitment;
@synthesize distributionRandom, distributionPowerlaw, distributionClustered;
@synthesize averageTeam, bestTeam;
@synthesize pileRadius, numberOfClusteredPiles, xPointArray, yPointArray;
@synthesize crossoverRate, mutationRate, selectionOperator, crossoverOperator, mutationOperator, elitism;
@synthesize gridSize, nest;
@synthesize parameterFile;
@synthesize error, observedError;
@synthesize delegate, viewDelegate;
@synthesize tickRate;
@synthesize volatilityRate;

-(id) init {
    if(self = [super init]) {
        teamCount = 20;
        generationCount = 50;
        robotCount = 64;
        tagCount = 1280;
        evaluationCount = 8;
        evaluationLimit = -1;
        postEvaluations = 1000;
        tickCount = 7200;
        clusteringTagCutoff = -1;
        volatilityRate = 0.;
        
        useTravel = NO;
        useGiveUp = NO;
        useSiteFidelity = NO;
        useInformedWalk = NO;
        useRecruitment = NO;
        usePheromone = NO;
        
        distributionClustered = 1.;
        distributionPowerlaw = 0.;
        distributionRandom = 0.;
        
        pileRadius = 3;
        numberOfClusteredPiles = 1280;
        
        crossoverRate = 1.0;
        mutationRate = 0.1;
        selectionOperator  = TournamentSelectionId;
        crossoverOperator = UniformPointCrossId;
        mutationOperator = FixedVarMutId;
        elitism = YES;
        
        gridSize = NSMakeSize(280, 280);
        nest = NSMakePoint(140, 140);
        
        parameterFile = nil;
        
        observedError = NO;
        
        xPointArray = [[NSMutableArray alloc] initWithCapacity:100];
        yPointArray = [[NSMutableArray alloc] initWithCapacity:100];
    }
    return self;
}

/*
 * Starts the simulation run.
 */
-(NSMutableDictionary*) run {
    
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
    vector<vector<vector<Cell*>>> grids;
    for (int i = 0; i < evaluationCount; i++) {
        vector<vector<Cell*>> grid;
        grid.resize(gridSize.height);
        for (int i = 0; i < gridSize.height; i++) {
            grid[i].resize(gridSize.width);
            for (int j = 0; j < gridSize.width; j++) {
                grid[i][j] = [[Cell alloc] init];
            }
        }
        grids.push_back(grid);
    }
    
    if(delegate && [delegate respondsToSelector:@selector(simulationDidStart:)]) {
        [delegate simulationDidStart:self];
    }
    
    //Main loop
    for(int generation = 0; generation < generationCount && evalCount < evaluationLimit; generation++) {
        printf("Generation %d\n", generation+1);
        for(Team* team in teams) {
            [team setFitness:0.];
            [team setTimeToCompleteCollection:0.];
        }
        
        if (evaluationCount > 1) {
            dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
            dispatch_apply(evaluationCount, queue, ^(size_t iteration) {
                [self evaluateTeams:teams onGrid:grids[iteration]];
            });
        }
        else {
            [self evaluateTeams:teams onGrid:grids[0]];
        }
        
        //Number of evaluations performed is the number of teams times the number of evaluations per team.
        evalCount = evalCount + teamCount*evaluationCount;

        //Set average and best teams
        [self setAverageTeamFrom:teams];
        [self setBestTeamFrom:teams];
        
        @autoreleasepool {
            [ga breedPopulation:teams AtGeneration:generation andMaxGeneration:generationCount];
        }
        
        if(delegate && [delegate respondsToSelector:@selector(simulation:didFinishGeneration:atEvaluation:)]) {
            [delegate simulation:self didFinishGeneration:generation atEvaluation:evalCount];
        }
    }
    
    if(delegate && [delegate respondsToSelector:@selector(simulationDidFinish:)]) {
        [delegate simulationDidFinish:self];
    }
    
    printf("Completed\n");
    
    //Return an evaluation of the average team from the final generation
    return [self evaluateTeam:averageTeam onGrid:grids[0]];
}


/*
 * Run a single evaluation
 */
-(void) evaluateTeams:(NSMutableArray*)teams onGrid:(vector<vector<Cell*>>)grid {
    NSMutableArray* robots = [[NSMutableArray alloc] initWithCapacity:robotCount];
    NSMutableArray* pheromones = [[NSMutableArray alloc] init];
    NSMutableArray* clusters = [[NSMutableArray alloc] init];
    NSMutableArray* piles = [[NSMutableArray alloc] init];
    NSMutableArray* resting = [[NSMutableArray alloc] init];
    NSMutableArray* totalCollectedTags = [[NSMutableArray alloc] init];
    
    float volatilityCounter;
    int timeToCompleted;
    
    for(int i = 0; i < robotCount; i++){[robots addObject:[[Robot alloc] init]];}
    
//    time_t seed = time(NULL);
    
    for(Team* team in teams) {
//        srandom((unsigned int)seed);
        
        // Create a pool of locations immediately after the random seed is set to make sure
        // the pile locations are consistent across teams.
        [xPointArray removeAllObjects];
        [yPointArray removeAllObjects];
        for (int i=0; i<100; i++) {
//            NSNumber* tempX = [[NSNumber alloc] initWithInt:randomIntRange(pileRadius, gridSize.width - (pileRadius * 2))];
//            NSNumber* tempY = [[NSNumber alloc] initWithInt:randomIntRange(pileRadius, gridSize.height - (pileRadius * 2))];

            float theta = randomFloat(2*M_PI);
            NSNumber* tempX = [[NSNumber alloc] initWithInt: (int)((randomIntRange(1.9, 2.1)*cos(theta)/3.)*gridSize.width)];
            NSNumber* tempY = [[NSNumber alloc] initWithInt: (int)((randomIntRange(1.9, 2.1)*sin(theta)/3.)*gridSize.width)];
            
            [xPointArray addObject:tempX];
            [yPointArray addObject:tempY];
        }
        
        [self initDistributionForArray:grid intoPiles:piles];
        
        for (vector<Cell*> v : grid) {
            for (Cell* cell : v) {
                [cell setIsClustered:NO];
                [cell setIsExplored:NO];
                if([cell tag]) {
                    [[cell tag] setDiscovered:NO];
                    [[cell tag] setPickedUp:NO];
                }
            }
        }
        
        for(Robot* robot in robots) {
            [robot reset];
        }
        
        [resting removeAllObjects];
        [pheromones removeAllObjects];
        [totalCollectedTags removeAllObjects];
        BOOL clustered = NO;
        
        volatilityCounter = 0.f;
        timeToCompleted = 0;
        [team setCollectedTags:0];
        
        for(int tick = 0; tickCount >= 0 ? tick < tickCount : YES; tick++) {
            
            NSMutableArray* collectedTags = [self stateTransition:robots inTeam:team atTick:tick onGrid:grid withPheromones:pheromones andClusters:clusters andResting:resting];
            
            [team setCollectedTags:[team collectedTags] + (int)[collectedTags count]];
            [totalCollectedTags addObjectsFromArray:collectedTags];
            
            if ((clusteringTagCutoff >= 0) && ([totalCollectedTags count] > [self clusteringTagCutoff]) && !clustered) {
                EM em = [Cluster trainOptimalEMWith:totalCollectedTags];
                Mat means = em.get<Mat>("means");
                vector<Mat> covs = em.get<vector<Mat>>("covs");
                
                [clusters removeAllObjects];
                for(int i = 0; i < means.size().height; i++) {
                    NSPoint p = NSMakePoint(round(means.at<double>(i,0)), round(means.at<double>(i,1)));
                    double width = ceil(covs[i].at<double>(0,0));
                    double height = ceil(covs[i].at<double>(1,1));
                    Cluster* c = [[Cluster alloc] initWithCenter:p width:width andHeight:height];
                    [clusters addObject:c];
                }
                
                [team setPredictedClusters:(int)[clusters count]];
                clustered = YES;
            }
            
            if ([team collectedTags] == [self tagCount]) {
                if (evaluationCount == 1) {
                    [team setTimeToCompleteCollection:tick];
                }
                timeToCompleted = tick;
                break;
            }
            
            if(tickRate != 0.f){[NSThread sleepForTimeInterval:tickRate];}
            
            if(viewDelegate != nil) {
                if([viewDelegate respondsToSelector:@selector(updateDisplayWindowWithRobots:team:grid:pheromones:clusters:)]) {
                    [Pheromone getPheromone:pheromones atTick:tick];
                    [viewDelegate updateDisplayWindowWithRobots:[robots copy] team:team grid:grid pheromones:[pheromones copy] clusters:[clusters copy]];
                }
            }
            
            if(delegate && [delegate respondsToSelector:@selector(simulation:didFinishTick:)]) {
                [delegate simulation:self didFinishTick:tick];
            }
            
            
            volatilityCounter += volatilityRate;
            while (volatilityCounter >= 1.0) {
                [self swapPilesOnGrid:grid fromPiles:piles];
                volatilityCounter -= 1.0;
            }
        }
        
        if (timeToCompleted > 0) {
            [team setFitness:[team fitness] + (tickCount*tagCount/timeToCompleted)];
        }
        else {
            [team setFitness:[team fitness] + [team collectedTags]];
        }
    }
}

/*
 * Swap piles: move tags around the grid to simulate volatility
 */
-(void) swapPilesOnGrid:(vector<vector<Cell*>>&)grid fromPiles:(NSMutableArray*)piles {
    
    NSPoint loc;
    Pile* newPile;
    Tag* tempTag;
    int size;
    
    // Remove all empty piles at the start of the pile list
    while ([[[piles firstObject] tagArray] count] == 0 && [piles count] > 0) {
        [piles removeObjectAtIndex:0];
    }

    if ([piles count] >= 2 && [[[piles firstObject] tagArray] count] > 0) {
        // If a tag has been picked up, move it to the new pile, but leave it in the same spot
        if ([[[[piles firstObject] tagArray] firstObject] pickedUp]) {
            tempTag = [[[piles firstObject] tagArray] firstObject];
            [[piles lastObject] addTag:tempTag];
            [[piles firstObject] removeSpecificTag:tempTag];
        }
        // If a tag has not been picked up, remove it and make a new one
        else {
            [[piles firstObject] removeTagFromGrid:grid];
            [[piles lastObject] addTagtoGrid:grid ofSize:gridSize];
        }
    }
    
    // If a pile has been cleared, remove it and (maybe) add a new one to the end of the list
//    if ([[[piles firstObject] tagArray] count] <= 0 && [piles count] > 0) {
//        [piles removeObjectAtIndex:0];
//
//        loc = [self findNewPileLocationInPiles:piles];
//        size = roundf(tagCount / (distributionPowerlaw + (numberOfClusteredPiles * distributionClustered)));
//        newPile = [[Pile alloc] initAtX:loc.x andY:loc.y withCapacity:size andRadius:pileRadius];
//        [piles addObject:newPile];
//    }
    
    // If the final pile is full, add a new one to the list
    if ([[[piles lastObject] tagArray] count] >= tagCount / numberOfClusteredPiles) {
        loc = [self findNewPileLocationInPiles:piles];
        size = roundf(tagCount / (distributionPowerlaw + (numberOfClusteredPiles * distributionClustered)));
        newPile = [[Pile alloc] initAtX:loc.x andY:loc.y withCapacity:size andRadius:pileRadius];
        [piles addObject:newPile];
    }
}

-(void) resetTag:(Tag*)tag onGrid:(vector<vector<Cell*>>&)grid fromPiles:(NSMutableArray*)piles {

    NSPoint loc;
    Pile* newPile;
    int size;
    
    // Remove old tag
    [tag.pile removeSpecificTag:tag];
    
    // If the first pile has been cleared, remove it
    if ([[[piles firstObject] tagArray] count] <= 0) {
        [piles removeObjectAtIndex:0];
    }
    
    // Add new tag
    [[piles lastObject] addTagtoGrid:grid ofSize:gridSize];

    // If the last pile is full, start a new one
    if ([[[piles lastObject] tagArray] count] >= tagCount / numberOfClusteredPiles) {
        loc = [self findNewPileLocationInPiles:piles];
        size = roundf(tagCount / (distributionPowerlaw + (numberOfClusteredPiles * distributionClustered)));
        newPile = [[Pile alloc] initAtX:loc.x andY:loc.y withCapacity:size andRadius:pileRadius];
        [piles addObject:newPile];
    }
}

/*
 * State transition case statement for robots using central-place foraging algorithm
 */
-(NSMutableArray*) stateTransition:(NSMutableArray*)robots inTeam:(Team*)team atTick:(int)tick onGrid:(vector<vector<Cell*>>&)grid
                    withPheromones:(NSMutableArray*)pheromones andClusters:(NSMutableArray*)clusters andResting:(NSMutableArray*)resting {
    
    NSMutableArray* collectedTags = [[NSMutableArray alloc] init];
    
    for (Robot* robot in robots) {
        switch([robot status]) {
                
                /*
                 * The robot hasn't been initialized yet.
                 * Give it some basic starting values and then fall-through to the next state.
                 */
            case ROBOT_STATUS_INACTIVE: {
                [robot setStatus:ROBOT_STATUS_DEPARTING];
                [robot setPosition:nest];
                [robot setTarget:edge(gridSize)];
                
                if (useRecruitment) {
                    [robot setStatus:ROBOT_STATUS_RESTING];
                    [resting addObject:robot];
                }
                //Fallthrough to ROBOT_STATUS_RESTING or ROBOT_STATUS_DEPARTING.
            }
                
                /*
                 * The robot is waiting inside the nest.
                 * This should only happen when useRecruitment is true.
                 * Robots leave the nest to forage at a low resting probability.
                 * Robots leave the nest to visit a specific location if they are recruited.
                 */
            case ROBOT_STATUS_RESTING: {
                
                //Delay to emulate physical robot
                if([robot delay]) {
                    [robot setDelay:[robot delay] - 1];
                    break;
                }
                
                if (useRecruitment) {
                    // Leave the nest at a fixed probability
                    if (randomFloat(1.) < team.leaveNestProbability) {
                        [resting removeObjectIdenticalTo:robot];
                        [robot setStatus:ROBOT_STATUS_DEPARTING];
                    }
                    break;
                }
                // Fallthrough to ROBOT_STATUS_DEPARTING if useRecruitment is false.
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
                
                //Delay to emulate physical robot
                if([robot delay]) {
                    [robot setDelay:[robot delay] - 1];
                    break;
                }
                
                if((![robot informed] && (!useTravel || (randomFloat(1.) < team.travelGiveUpProbability))) || (NSEqualPoints([robot position], [robot target]))) {
                    [robot setStatus:ROBOT_STATUS_SEARCHING];
                    [robot setInformed:(useInformedWalk & [robot informed])];
                    [robot turnWithParameters:team];
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
                if([robot delay]) {
                    [robot setDelay:[robot delay] - 1];
                    break;
                }
                
                //Probabilistically give up searching and return to the nest
                if(useGiveUp && (randomFloat(1.) < [team searchGiveUpProbability])) {
                    [robot setTarget:nest];
                    [robot setStatus:ROBOT_STATUS_RETURNING];
                    break;
                }
                
                //Calculate end point
                [robot setTarget:NSMakePoint(roundf([robot position].x + (cos(robot.direction))), roundf([robot position].y + (sin([robot direction]))))];
                
                //If our current direction takes us outside the world, frantically spin around until this isn't the case.
                while([robot target].x < 0 || [robot target].y < 0 || [robot target].x >= gridSize.width || [robot target].y >= gridSize.height) {
                    [robot setDirection:randomFloat(M_2PI)];
                    [robot setTarget:NSMakePoint(roundf([robot position].x + cos([robot direction])), roundf([robot position].y + sin([robot direction])))];
                }
                
                //Move one cell
                [robot moveWithin:gridSize];
                Cell* currentCell = grid[[robot position].y][[robot position].x];
                if (![currentCell isExplored]) {
                    [currentCell setIsExplored:YES];
                    if ([currentCell region]) {
                        [[currentCell region] setDirty:YES];
                    }
                }
                
                //Turn
                [robot turnWithParameters:team];
                
                //After we've moved 1 square ahead, check one square ahead for a tag.
                //Reusing robot.target here (without consequence, it just gets overwritten when moving).
                [robot setTarget:NSMakePoint(roundf([robot position].x + cos([robot direction])), roundf([robot position].y + sin([robot direction])))];
                if([robot target].x >= 0 && [robot target].y >= 0 && [robot target].x < gridSize.width && [robot target].y < gridSize.height) {
                    Tag* foundTag = [grid[[robot target].y][[robot target].x] tag];
                    //Note we use shortcircuiting here.
                    if([error detectTag] && foundTag && ![foundTag pickedUp]) {
                        //Perturb found tag position to simulate error
                        NSPoint perturbedTagPosition = [error perturbTagPosition:[foundTag position] withGridSize:gridSize andGridCenter:nest];
                        Tag* tagCopy = [foundTag copy];
                        [tagCopy setPosition:perturbedTagPosition];
                        
                        [robot setDiscoveredTags:[[NSMutableArray alloc] initWithObjects:tagCopy, nil]];
//                        [foundTag setPickedUp:YES];
//                        [foundTag removeFromPile];
                        
                        //Sum up all non-picked-up seeds in the moore neighbor.
                        for(int dx = -1; dx <= 1; dx++) {
                            for(int dy = -1; dy <= 1; dy++) {
                                
                                //If neighboring cell is legal
                                if(([foundTag position].x + dx >= 0 && [foundTag position].x + dx < gridSize.width) &&
                                   ([foundTag position].y + dy >= 0 && [foundTag position].y + dy < gridSize.height))
                                {
                                    //Look up tag in tags array
                                    Cell* cell = grid[[foundTag position].y + dy][[foundTag position].x + dx];
                                    
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
                        
                        if(delegate && [delegate respondsToSelector:@selector(simulation:didPickupTag:atTick:)]) {
                            [delegate simulation:self didPickupTag:foundTag atTick:tick];
                        }
                    }
                }
                
                break;
            }
                
                /*
                 * The robot is on its way back to the nest.
                 * It is either carrying food, or it gave up on its search and is returning to base for further instruction.
                 * Stuff like laying/assigning of pheromones is handled here.
                 */
            case ROBOT_STATUS_RETURNING: {
                
                //Delay to emulate physical robot
                if([robot delay]) {
                    [robot setDelay:[robot delay] - 1];
                    break;
                }
                
                [robot moveWithin:gridSize];
                
                // If back at the nest
                if(NSEqualPoints(robot.position, nest)) {
                    //Retrieve collected tag from discoveredTags array (if available)
                    Tag* foundTag = nil;
                    if ([[robot discoveredTags] count] > 0) {
                        foundTag = [[robot discoveredTags] objectAtIndex:0];
                        [collectedTags addObject:foundTag];
                    }
                    
                    //Add (perturbed) tag position to global pheromone array
                    if (foundTag && (randomFloat(1.) < poissonCDF([[robot discoveredTags] count], [team pheromoneLayingRate]))) {
                        Pheromone* pheromone = [[Pheromone alloc] initWithPosition:[foundTag position] weight:1. decayRate:[team pheromoneDecayRate] andUpdatedTick:tick];
                        [pheromones addObject:pheromone];
                        
                        if(delegate && [delegate respondsToSelector:@selector(simulation:didPlacePheromone:atTick:)]) {
                            [delegate simulation:self didPlacePheromone:pheromone atTick:tick];
                        }
                    }
                    
                    // Recruit Resting Robots
                    if (foundTag && useRecruitment && [resting count] > 0) {
                        NSMutableArray* leavingRobots = [[NSMutableArray alloc] init];
                        for (Robot* r in resting) {
                            if (randomFloat(1.) < team.recruitProbability) {
                                // If siteFidelity, give the newly departing robot the location
                                if (useSiteFidelity) {
                                    [r setTarget:[error perturbTagPosition:[foundTag position] withGridSize:gridSize andGridCenter:nest]];
                                    [r setInformed:ROBOT_INFORMED_MEMORY];
                                    [r setStatus:ROBOT_STATUS_DEPARTING];
                                }
                                // If no sideFidelity, have the newly departing robot forage randomly
                                else {
                                    [r setTarget:edge(gridSize)];
                                    [r setInformed:ROBOT_INFORMED_NONE];
                                    [r setStatus:ROBOT_STATUS_DEPARTING];
                                }
                                [leavingRobots addObject:r];
                            }
                        }
                        for (Robot* leaving in leavingRobots) {
                            [resting removeObjectIdenticalTo:leaving];
                        }
                    }
                    
                    //Set required local variables
                    BOOL decisionFlag = randomFloat(1.) < poissonCDF([[robot discoveredTags] count], [team siteFidelityRate]);
                    NSPoint pheromonePosition = [Pheromone getPheromone:pheromones atTick:tick];
                    
                    if([clusters count]) {
                        int r = randomInt((int)[clusters count]);
                        Cluster* target = [clusters objectAtIndex:r];
                        int x = clip(randomIntRange([target center].x - [target width]/2, [target center].x + [target width]/2), 0, gridSize.width - 1);
                        int y = clip(randomIntRange([target center].y - [target height]/2, [target center].y + [target height]/2), 0, gridSize.height - 1);
                        [robot setTarget:NSMakePoint(x, y)];
                        [robot setInformed:ROBOT_INFORMED_PHEROMONE];
                    }
                    
                    //If a tag was found, decide whether to return to its location
                    else if(foundTag && useSiteFidelity && decisionFlag) {
                        [robot setTarget:[error perturbTargetPosition:[foundTag position] withGridSize:gridSize andGridCenter:nest]];
                        [robot setInformed:ROBOT_INFORMED_MEMORY];
                    }
                    
                    //If no pheromones exist, pheromone will be (-1, -1)
                    else if(!NSEqualPoints(pheromonePosition, NSNullPoint) && usePheromone && !decisionFlag) {
                        [robot setTarget:[error perturbTargetPosition:pheromonePosition withGridSize:gridSize andGridCenter:nest]];
                        [robot setInformed:ROBOT_INFORMED_PHEROMONE];
                    }
                    
                    //If no pheromones and no tag and no partitioning knowledge, go to a random location
                    else {
                        [robot setTarget:edge(gridSize)];
                        [robot setInformed:ROBOT_INFORMED_NONE];
                    }
                    
                    [robot setDiscoveredTags:nil];
                    [robot setSearchTime:0];
                    if (useRecruitment && !foundTag) {
                        [robot setStatus:ROBOT_STATUS_RESTING];
                        [resting addObject:robot];
                    }
                    else {
                        [robot setStatus:ROBOT_STATUS_DEPARTING];
                    }
                }
                break;
            }
        }
    }
    
    return collectedTags;
}

/*
 * Run post evaluations of the average team from the final generation (i.e. generationCount)
 */
-(NSMutableDictionary*) evaluateTeam:(Team*)team onGrid:(vector<vector<Cell*>>)grid{
    NSMutableArray* fitness = [[NSMutableArray alloc] init];
    NSMutableArray* time = [[NSMutableArray alloc] init];
    NSMutableArray* clusters = [[NSMutableArray alloc] init];
    NSMutableArray* teams = [[NSMutableArray alloc] initWithObjects:averageTeam, nil];
    
    for (int i = 0; i < postEvaluations; i++) {
        
        if (i && !(i%100)) {
            printf("%d\n", i);
        }
        
        //Reset
        [averageTeam setFitness:0.];
        [averageTeam setTimeToCompleteCollection:0.];
        
        //Evaluate
        [self evaluateTeams:teams onGrid:grid];
        [fitness addObject:@([averageTeam fitness])];
        [time addObject:@([averageTeam timeToCompleteCollection])];
        [clusters addObject:@([averageTeam predictedClusters])];
    }
    
    return [@{@"fitness":fitness, @"time":time, @"clusters":clusters} mutableCopy];
}

/*
 * Creates a random distribution of tags.
 * Called at the beginning of each evaluation.
 */
-(void) initDistributionForArray:(vector<vector<Cell*>>&)grid intoPiles:(NSMutableArray *)piles {
    
    // Clear piles
    [piles removeAllObjects];
    
    // Clear Tags
    for(vector<Cell*> v : grid) {
        for (Cell* cell : v) {
            [cell setTag:nil];
        }
    }
    
    int pilesOf[tagCount + 1]; //Key is size of pile.  Value is number of piles with this many tags.
    for(int i = 0; i <= tagCount; i++){pilesOf[i]=0;}
    
    //Needs to be adjusted if doing a powerlaw distribution with tagCount != 256.
    pilesOf[1] = roundf(((tagCount / 4) * distributionPowerlaw) + (tagCount * distributionRandom));
    pilesOf[(tagCount / 64)] = roundf((tagCount / 16) * distributionPowerlaw);
    pilesOf[(tagCount / 16)] = roundf((tagCount / 64) * distributionPowerlaw);
    pilesOf[(tagCount / numberOfClusteredPiles)] = roundf(distributionPowerlaw + (numberOfClusteredPiles * distributionClustered));
    
    for(int size = 1; size <= tagCount; size++) { //For each distinct size of pile.
        if(pilesOf[size] == 0) {
            continue;
        }
        
        // No clustering
        if(size < 1) {
            for(int i = 0; i < pilesOf[1]; i++) {
                int tagX, tagY;
                do {
                    tagX = randomInt(gridSize.width);
                    tagY = randomInt(gridSize.height);
                } while([grid[tagY][tagX] tag]);
                
                Tag* tag = [[Tag alloc] initWithX:tagX Y:tagY andCluster:1];
                [grid[tagY][tagX] setTag:tag];
            }
        }
        
        // Clustered Piles: pilesOf[size] == the number of piles
        else {
            //            int cluster = 1;
            Pile* currentPile;
            NSPoint pileLocation;
            //            pileArray = [[NSMutableArray alloc] init];
            
            // Place each pile. +1 to create an empty pile to be the new patch.
            for(int i = 0; i < pilesOf[size]+1; i++) {
                pileLocation = [self findNewPileLocationInPiles:piles];
                currentPile = [[Pile alloc] initAtX:pileLocation.x andY:pileLocation.y withCapacity:size andRadius:pileRadius];
                
                //Place each individual tag in the pile.  Don't place any new tags in the extra pile.
                for(int j = 0; j < size && i < pilesOf[size]; j++) {
                    [currentPile addTagtoGrid:grid ofSize:gridSize];
                }
                [currentPile shuffle];
                [piles addObject:currentPile];
            }
        }
    }
}

-(NSPoint) findNewPileLocationInPiles:(NSMutableArray*)piles {
    int pileX, pileY;
    BOOL overlapping;
    do {
        if ([xPointArray count] > 0 && [yPointArray count] > 0) {
            pileX = [[xPointArray firstObject] intValue];
            pileY = [[yPointArray firstObject] intValue];
            [xPointArray removeObjectAtIndex:0];
            [yPointArray removeObjectAtIndex:0];
        }
        else {
            float theta = randomFloat(2*M_PI);
            pileX = (int)((randomIntRange(1.9, 2.1)*gridSize.width/3.)*cos(theta));
            pileY = (int)((randomIntRange(1.9, 2.1)*gridSize.width/3.)*sin(theta));
//            pileX = randomIntRange(pileRadius, gridSize.width - (pileRadius * 2));
//            pileY = randomIntRange(pileRadius, gridSize.height - (pileRadius * 2));
        }
        
        //Make sure the place we picked isn't close to another pile.  Pretty naive.
        overlapping = NO;
        
        if (pointDistance(pileX, pileY, nest.x, nest.y) < (float)min(gridSize.width, gridSize.height) / 5.0) {
            overlapping = YES;
        }
        else {
            for(int j = 0; j < [piles count]; j++) {
                if([piles[j] containsPointX:pileX andY:pileY]) {
                    overlapping = YES;
                    break;
                }
            }
        }
    } while(overlapping);
    
    return NSMakePoint(pileX, pileY);
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
            [parameterSums setObject:@(val) forKey:key];
        }
    }
    
    for(NSString* key in [parameterSums allKeys]) {
        float val = [[parameterSums objectForKey:key] floatValue] / teamCount;
        [parameterSums setObject:@(val) forKey:key];
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
    return [@{@"teamCount" : @(teamCount),
              @"generationCount" : @(generationCount),
              @"robotCount" : @(robotCount),
              @"tagCount" : @(tagCount),
              @"evaluationCount" : @(evaluationCount),
              @"tickCount" : @(tickCount),
              @"clusteringTagCutoff" : @(clusteringTagCutoff),
              @"volatilityRate" : @(volatilityRate),
              
              @"useTravel" : @(useTravel),
              @"useGiveUp" : @(useGiveUp),
              @"useSiteFidelity" : @(useSiteFidelity),
              @"usePheromone" : @(usePheromone),
              @"useInformedWalk" : @(useInformedWalk),
              @"useRecruitment" : @(useRecruitment),
              
              @"distributionRandom" : @(distributionRandom),
              @"distributionPowerlaw" : @(distributionPowerlaw),
              @"distributionClustered" : @(distributionClustered),
              
              @"pileRadius" : @(pileRadius),
              @"numberOfClusteredPiles": @(numberOfClusteredPiles),
              
              @"crossoverRate" : @(crossoverRate),
              @"mutationRate" : @(mutationRate),
              @"elitism" : @(elitism),
              
              @"gridSize" : NSStringFromSize(gridSize),
              @"nest" : NSStringFromPoint(nest),
              
              @"observedError" : @(observedError)} mutableCopy];
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
    clusteringTagCutoff = [[parameters objectForKey:@"clusteringTagCutoff"] intValue];
    volatilityRate = [[parameters objectForKey:@"volatilityRate"] floatValue];
    
    useTravel = [[parameters objectForKey:@"useTravel"] boolValue];
    useGiveUp = [[parameters objectForKey:@"useGiveUp"] boolValue];
    useSiteFidelity = [[parameters objectForKey:@"useSiteFidelity"] boolValue];
    usePheromone = [[parameters objectForKey:@"usePheromone"] boolValue];
    useInformedWalk = [[parameters objectForKey:@"useInformedWalk"] boolValue];
    useRecruitment = [[parameters objectForKey:@"useRecruitment"] boolValue];
    
    distributionRandom = [[parameters objectForKey:@"distributionRandom"] floatValue];
    distributionPowerlaw = [[parameters objectForKey:@"distributionPowerlaw"] floatValue];
    distributionClustered = [[parameters objectForKey:@"distributionClustered"] floatValue];
    
    pileRadius = [[parameters objectForKey:@"pileRadius"] intValue];
    numberOfClusteredPiles = [[parameters objectForKey:@"numberOfClusteredPiles"] intValue];
    
    crossoverRate = [[parameters objectForKey:@"crossoverRate"] floatValue];
    mutationRate = [[parameters objectForKey:@"mutationRate"] floatValue];
    elitism = [[parameters objectForKey:@"elitism"] boolValue];
    
    gridSize = NSSizeFromString([parameters objectForKey:@"gridSize"]);
    nest = NSPointFromString([parameters objectForKey:@"nest"]);
    
    observedError = [[parameters objectForKey:@"observedError"] boolValue];
}

-(void)writeParametersToFile:(NSString *)file {
    [[self getParameters] writeToFile:file atomically:YES];
}

+(void)writeParameterNamesToFile:(NSString *)file {
    //unused
}

@end