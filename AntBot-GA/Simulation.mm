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
@synthesize useTravel, useGiveUp, useSiteFidelity, usePheromone, useInformedWalk;
@synthesize distributionRandom, distributionPowerlaw, distributionClustered;
@synthesize averageTeam, bestTeam;
@synthesize pileRadius, numberOfClusteredPiles;
@synthesize crossoverRate, mutationRate, selectionOperator, crossoverOperator, mutationOperator, elitism;
@synthesize gridSize, nest;
@synthesize parameterFile;
@synthesize error, observedError;
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
        postEvaluations = 1000;
        tickCount = 7200;
        clusteringTagCutoff = -1;
        
        useTravel =
        useGiveUp =
        useSiteFidelity =
        usePheromone =
        useInformedWalk = YES;
        
        distributionClustered = 1.;
        distributionPowerlaw = 0.;
        distributionRandom = 0.;
        
        pileRadius = 2;
        numberOfClusteredPiles = 4;
        
        crossoverRate = 1.0;
        mutationRate = 0.1;
        selectionOperator  = TournamentSelectionId;
        crossoverOperator = UniformPointCrossId;
        mutationOperator = FixedVarMutId;
        elitism = YES;
        
        gridSize = NSMakeSize(125, 125);
        nest = NSMakePoint(62, 62);
        
        parameterFile = nil;
        
        observedError = YES;
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
-(void) evaluateTeams:(NSMutableArray*)teams onGrid:(vector<vector<Cell*>>)grid{
    [self initDistributionForArray:grid];
    
    NSMutableArray* robots = [[NSMutableArray alloc] initWithCapacity:robotCount];
    NSMutableArray* pheromones = [[NSMutableArray alloc] init];
    NSMutableArray* clusters = [[NSMutableArray alloc] init];
    NSMutableArray* totalCollectedTags = [[NSMutableArray alloc] init];
    for(int i = 0; i < robotCount; i++){[robots addObject:[[Robot alloc] init]];}
    
    for(Team* team in teams) {
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
        
        [pheromones removeAllObjects];
        [totalCollectedTags removeAllObjects];
        BOOL clustered = NO;
        
        for(int tick = 0; tickCount >= 0 ? tick < tickCount : YES; tick++) {
            
            NSMutableArray* collectedTags = [self stateTransition:robots inTeam:team atTick:tick onGrid:grid withPheromones:pheromones andClusters:clusters];
            
            [team setFitness:[team fitness] + [collectedTags count]];
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
            
            if ((evaluationCount == 1) && ([team fitness] == [self tagCount])) {
                [team setTimeToCompleteCollection:tick];
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
        }
    }
}

/*
 * State transition case statement for robots using central-place foraging algorithm
 */
-(NSMutableArray*) stateTransition:(NSMutableArray*)robots inTeam:(Team*)team atTick:(int)tick onGrid:(vector<vector<Cell*>>&)grid
                    withPheromones:(NSMutableArray*)pheromones andClusters:(NSMutableArray*)clusters {
    
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
                        [foundTag setPickedUp:YES];
                        
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
                    [robot setStatus:ROBOT_STATUS_DEPARTING];
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
-(void) initDistributionForArray:(vector<vector<Cell*>>&)grid {
    
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
    
    int pileCount = 0;
    NSPoint pilePoints[tagCount + 1];
    
    for(int size = 1; size <= tagCount; size++) { //For each distinct size of pile.
        if(pilesOf[size] == 0) {
            continue;
        }
        
        if(size == 1) {
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
        else {
            int cluster = 1;
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
                    } while([grid[tagY][tagX] tag]);
                    
                    Tag* tag = [[Tag alloc] initWithX:tagX Y:tagY andCluster:cluster];
                    [grid[tagY][tagX] setTag:tag];
                    if ((j+1) % (tagCount / numberOfClusteredPiles) == 0) {
                        cluster++;
                    }
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
              
              @"useTravel" : @(useTravel),
              @"useGiveUp" : @(useGiveUp),
              @"useSiteFidelity" : @(useSiteFidelity),
              @"usePheromone" : @(usePheromone),
              @"useInformedWalk" : @(useInformedWalk),
              
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
 
    useTravel = [[parameters objectForKey:@"useTravel"] boolValue];
    useGiveUp = [[parameters objectForKey:@"useGiveUp"] boolValue];
    useSiteFidelity = [[parameters objectForKey:@"useSiteFidelity"] boolValue];
    usePheromone = [[parameters objectForKey:@"usePheromone"] boolValue];
    useInformedWalk = [[parameters objectForKey:@"useInformedWalk"] boolValue];
    
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