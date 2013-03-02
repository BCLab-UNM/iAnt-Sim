#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import "Simulation.h"
#import "Colony.h"
#import "Ant.h"
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

@synthesize colonyCount, generationCount, antCount;
@synthesize distributionRandom, distributionPowerlaw, distributionClustered, numberOfTags;
@synthesize averageColony;
@synthesize tickRate;
@synthesize viewDelegate;

/*
 * Starts the simulation run.
 */
-(int) start {

    srandomdev();
    colonies = [[NSMutableArray alloc] init];
    for(int i = 0; i < colonyCount; i++){[colonies addObject:[[Colony alloc] init]];}

    for(int generation = 0; generation < generationCount; generation++) {
        NSLog(@"Starting Generation %d", generation);
        
        for(Colony* colony in colonies){colony.tagsCollected = 0;}
        
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_apply(EVALUATION_COUNT, queue, ^(size_t idx) {
            @autoreleasepool {
                [self runEvaluation];
            }
        });
        
        [self breedColonies];
    }
  
    return 0;
}


/*
 * Runs a single evaluation
 */
-(void) runEvaluation {
    Tag* tags[GRID_HEIGHT][GRID_WIDTH];
    [self initDistributionForArray:tags];

    NSMutableArray* ants = [[NSMutableArray alloc] init];
    NSMutableArray* pheromones = [[NSMutableArray alloc] init];
    for(int i = 0; i < antCount; i++){[ants addObject:[[Ant alloc] init]];}

    for(Colony* colony in colonies) {
        for(int i = 0; i < GRID_HEIGHT; i++) {
            for(int j = 0; j < GRID_WIDTH; j++) {
                if(tags[i][j]){[tags[i][j] setPickedUp:NO];}
            }
        }
        for(int i = 0; i < antCount; i++){[[ants objectAtIndex:i] reset];}
        [pheromones removeAllObjects];
        
        for(int tick = 0; tick < STEP_COUNT; tick++){
            for(Ant* ant in ants) {
                
                switch(ant.status) {
                        
                    /*
                     * The ant hasn't been initialized yet.
                     * Give it some basic starting values and then fall-through to the next state.
                     */
                    case ANT_STATUS_INACTIVE:
                        ant.status = ANT_STATUS_DEPARTING;
                        ant.position = NSMakePoint(NEST_X,NEST_Y);
                        ant.target = edge(GRID_WIDTH,GRID_HEIGHT);
                    //Fallthrough to ANT_STATUS_DEPARTING.
                        
                    /*
                     * The ant is either:
                     *  -Moving in a random direction away from the nest (not site-fidelity-ing or pheromone-ing).
                     *  -Moving towards a specific point where a tag was last found (site-fidelity-ing).
                     *  -Moving towards a specific point due to pheromones.
                     *
                     * For each of the cases, we have to ultimately decide on a direction for the ant to travel in,
                     * then decide which 'cell' best accomplishes traveling in this direction.  We then move the ant,
                     * and may change the ant/world state based on certain criteria (i.e. it reaches its destination).
                     */
                    case ANT_STATUS_DEPARTING:;
                        float r = randomFloat(1.);
                        if(((ant.informed == ANT_INFORMED_PHEROMONE) && (r < colony.trailDropRate)) || (!ant.informed && (r < colony.walkDropRate))) {
                            ant.status = ANT_STATUS_SEARCHING;
                            ant.informed = ANT_INFORMED_NONE;
                            ant.searchTime = -1; //Don't do an informed random walk if we drop off a trail.
                            break;
                        }
                        
                        [ant move];
                        
                        //Change state if we've reached our destination.
                        if(NSEqualPoints(ant.position, ant.target)) {
                            ant.status = ANT_STATUS_SEARCHING;
                            ant.informed = ANT_INFORMED_NONE;
                        }
                    break;
                        
                    /*
                     * The ant is performing a random walk.
                     * In this state, the ant only exhibits behavior once every SEARCH_DELAY ticks.
                     * It will randomly change its direction based on how long it has been searching and move in this direction.
                     * If it finds a tag, its state changes to ANT_STATUS_RETURNING (it brings the tag back to the nest.
                     * All site fidelity and pheromone work, however, is taken care of once the ant actually arrives at the nest.
                     */
                    case ANT_STATUS_SEARCHING:
                        if(tick - ant.lastMoved < SEARCH_DELAY){break;}
                        
                        if(randomFloat(1.) < colony.searchGiveupRate) {
                            ant.target = NSMakePoint(NEST_X,NEST_Y);
                            ant.status = ANT_STATUS_RETURNING;
                            break;
                        }
                        
                        if(tick - ant.lastTurned >= 3) { //Change direction every 3 iterations.
                            float dTheta;
                            if(ant.searchTime >= 0) {
                                dTheta = randomNormal(0, (colony.dirDevCoeff/pow((ant.searchTime),colony.dirTimePow))+colony.dirDevConst);
                            }
                            else {
                                dTheta = randomNormal(0, colony.dirDevConst);
                            }
                            ant.direction = pmod(ant.direction+dTheta,M_2PI);
                            ant.lastTurned = tick;
                        }
                        
                        //If our current direction takes us outside the world, frantically spin around until this isn't the case.
                        ant.target = NSMakePoint(roundf(ant.position.x+cos(ant.direction)),roundf(ant.position.y+sin(ant.direction)));
                        while(ant.target.x < 0 || ant.target.y < 0 || ant.target.x >= GRID_WIDTH || ant.target.y >= GRID_HEIGHT) {
                            ant.direction = randomFloat(M_2PI);
                            ant.target = NSMakePoint(roundf(ant.position.x+cos(ant.direction)),roundf(ant.position.y+sin(ant.direction)));
                        }
                        
                        [ant move];
                        
                        //After we've moved 1 square ahead, check one square ahead for a tag.
                        //Reusing ant.target here (without consequence, it just gets overwritten when moving).
                        ant.target = NSMakePoint(roundf(ant.position.x+cos(ant.direction)),roundf(ant.position.y+sin(ant.direction)));
                        if(ant.target.x >= 0 && ant.target.y >= 0 && ant.target.x < GRID_WIDTH && ant.target.y < GRID_HEIGHT) {
                            Tag* t = tags[(int)ant.target.y][(int)ant.target.x];
                            if((randomFloat(1.f) < READ_RATE) && (t != 0) && !t.pickedUp) { //Note we use shortcircuiting here.
                                [t setPickedUp:YES];
                                ant.carrying = t;
                                ant.status = ANT_STATUS_RETURNING;
                                ant.target = NSMakePoint(NEST_X,NEST_Y);
                                ant.neighbors = 0;
                                
                                //Sum up all non-picked-up seeds in the moore neighbor.
                                for(int dx = -1; dx <= 1; dx++) {
                                    for(int dy = -1; dy <= 1; dy++) {
                                        if((ant.carrying.x+dx>=0 && ant.carrying.x+dx<GRID_WIDTH) && (ant.carrying.y+dy>=0 && ant.carrying.y+dy<GRID_HEIGHT)) {
                                            ant.neighbors += (tags[ant.carrying.y+dy][ant.carrying.x+dx] != 0) && !(tags[ant.carrying.y+dy][ant.carrying.x+dx].pickedUp);
                                        }
                                    }
                                }
                            }
                        }
                
                        if(ant.searchTime >= 0){ant.searchTime += 1;}
                        ant.lastMoved = tick;
                    break;
                        
                    /*
                     * The ant is on its way back to the nest.
                     * It is either carrying food, or it gave up on its search and is returning to base for further instruction.
                     * Stuff like laying/assigning of pheromones is handled here.
                     */
                    case ANT_STATUS_RETURNING:
                        [ant move];
                        
                        //Lots of repeated code in here.
                        if(NSEqualPoints(ant.position,ant.target)) {
                            if(ant.carrying != nil) {
                                [colony setTagsCollected:colony.tagsCollected+1];
                                
                                if(randomFloat(1.) < (ant.neighbors/colony.densityThreshold) + colony.densityConstant) {
                                    Pheromone* p = [[Pheromone alloc] init];
                                    p.x = ant.carrying.x;
                                    p.y = ant.carrying.y;
                                    p.n = 1.;
                                    p.updated = tick;
                                    [pheromones addObject:p];
                                }
                                
                                if(([pheromones count] > 0) && (randomFloat(1.) > (ant.neighbors/colony.densityInfluenceThreshold) + colony.densityInfluenceConstant)) {
                                    ant.target = [self perturbPosition:[self getPheromone:pheromones atTick:tick withDecayRate:colony.decayRate]];
                                    ant.informed = ANT_INFORMED_PHEROMONE;
                                }
                                else if(randomFloat(1.) < (ant.neighbors/colony.densityPatchThreshold) + colony.densityPatchConstant) {
                                    ant.target = [self perturbPosition:NSMakePoint(ant.carrying.x,ant.carrying.y)];
                                    ant.informed = ANT_INFORMED_MEMORY;
                                }
                                else {
                                    ant.target = edge(GRID_WIDTH,GRID_HEIGHT);
                                    ant.informed = ANT_INFORMED_NONE;
                                }
                                
                                ant.carrying = nil;
                            }
                            else {
                                if([pheromones count] > 0){
                                    ant.target = [self perturbPosition:[self getPheromone:pheromones atTick:tick withDecayRate:colony.decayRate]];
                                    ant.informed = ANT_INFORMED_PHEROMONE;
                                }
                                else{
                                    ant.target = edge(GRID_WIDTH,GRID_HEIGHT);
                                    ant.informed = ANT_INFORMED_NONE;
                                }
                            }
                            
                            //The old GA used a searchTime value of >= 0 to indicated we're doing an INFORMED random walk.
                            if(ant.informed == ANT_INFORMED_NONE){ant.searchTime = -1;}
                            else{ant.searchTime = 0;}
                            
                            ant.status = ANT_STATUS_DEPARTING;
                        }
                    break;
                }
            }
            
            if(tickRate != 0.f){[NSThread sleepForTimeInterval:tickRate];}
            if(viewDelegate != nil) {
                if([viewDelegate respondsToSelector:@selector(updateAnts:)]) {
                    [viewDelegate updateAnts:ants];
                }
            }
        }
    }
}


/*
 * Introduces error into the given position.
 */
-(NSPoint) perturbPosition:(NSPoint)position {
    return position;
}


/*
 * 'Breeds' and mutates colonies.
 * There is a slight tradeoff for readability at the cost of efficiency here,
 * which has to do with the use of (and enumeration over) dictionaries.
 */
-(void) breedColonies {
    Colony* children[colonyCount];
    for(int i = 0; i < colonyCount; i++) {
        children[i] = [[Colony alloc] init];
        Colony* child = children[i];
        
        Colony* parent[2];
        for(int j = 0; j < 2; j++) {
            Colony *p1 = [colonies objectAtIndex:randomInt(colonyCount)],
            *p2 = [colonies objectAtIndex:randomInt(colonyCount)];
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
                
                //Parameters have slightly different mutation criteria.
                if((key == @"decayRate") || (key == @"walkDropRate") || (key == @"searchGiveupRate") || (key == @"trailDropRate")){
                    val += randomNormal(0,sig);
                    [parameters setObject:[NSNumber numberWithFloat:clip(val,0,1)] forKey:key];
                }
                else {
                    val += randomNormal(0,sig+.001);
                    
                    if((key == @"dirDevConst") || (key == @"dirDevCoeff") || (key == @"dirTimePow")) {
                        [parameters setObject:[NSNumber numberWithFloat:clip(val,0,INT_MAX)] forKey:key];
                    }
                    else {
                        [parameters setObject:[NSNumber numberWithFloat:val] forKey:key];
                    }
                }
            }
        }
        
        [children[i] setParameters:parameters];
    }
    
    //Set the children to be the new set of colonies for the next generation.
    for(int i = 0; i < colonyCount; i++) {
        Colony* colony = [colonies objectAtIndex:i];
        [colony setParameters:[children[i] getParameters]];
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
    
    int pilesOf[numberOfTags]; //Key is size of pile.  Value is number of piles with this many tags.
    for(int i = 0; i < numberOfTags; i++){pilesOf[i]=0;}

    //Needs to be adjusted if doing a powerlaw distribution with numberOfTags != 256.
    pilesOf[1] = roundf(((numberOfTags / 4) * distributionPowerlaw) + (numberOfTags * distributionRandom));
    pilesOf[(numberOfTags / 64)] = roundf((numberOfTags / 16) * distributionPowerlaw);
    pilesOf[(numberOfTags / 16)] = roundf((numberOfTags / 64) * distributionPowerlaw);
    pilesOf[(numberOfTags / 4)] = roundf(distributionPowerlaw + (4 * distributionClustered));
    
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
                
                tags[tagY][tagX] = [[Tag alloc] initWithX:tagX andY:tagY];;
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
                        if(pointDistance(pilePoints[j].x,pilePoints[j].y,pileX,pileY) < PILE_RADIUS){overlapping = 1;}
                    }
                }
                
                pilePoints[pileCount++] = NSMakePoint(pileX,pileY);
                
                //Place each individual tag in the pile.
                for(int j = 0; j < i; j++) {
                    float maxRadius = PILE_RADIUS;
                    int tagX,tagY;
                    do {
                        float rad = randomFloat(maxRadius);
                        float dir = randomFloat(M_2PI);
                        
                        tagX = clip(roundf(pileX + (rad * cos(dir))),0,GRID_WIDTH-1);
                        tagY = clip(roundf(pileY + (rad * sin(dir))),0,GRID_HEIGHT-1);
                        
                        maxRadius += 1;
                    } while(tags[tagY][tagX]);

                    tags[tagY][tagX] = [[Tag alloc] initWithX:tagX andY:tagY];;
                }
            }
        }
    }
}


/*
 * Picks a pheromone out of the passed list based on a random number weighted on the pheromone strengths.
 * This might work better in Colony.m, as we're passing a lot of Colony related stuff.
 */
-(NSPoint) getPheromone:(NSMutableArray*)pheromones atTick:(int)tick withDecayRate:(float)decayRate {
    float nSum = 0.f;
    for(Pheromone* pheromone in pheromones) {
        pheromone.n *= powf(1.f - decayRate, (tick - pheromone.updated));
        pheromone.updated = tick;
        nSum += pheromone.n;
    }
    
    float r = randomFloat(nSum);
    for(Pheromone* pheromone in pheromones) {
        if(r < pheromone.n){return NSMakePoint(pheromone.x,pheromone.y);}
        r -= pheromone.n;
    }
    
    return NSMakePoint(-1,-1); //Should never happen.
}


/*
 * Custom getter for bestColony (lazy evaluation)
 */
-(Colony*) averageColony {
    Colony* _averageColony = [[Colony alloc] init];
    NSMutableDictionary* parameterSums = [[NSMutableDictionary alloc] initWithCapacity:13];
    float tagSum = 0.f;
    
    for(Colony* colony in colonies) {
        NSMutableDictionary* parameters = [colony getParameters];
        tagSum += colony.tagsCollected;
        for(NSString* key in parameters) {
            float val = [[parameterSums objectForKey:key] floatValue] + [[parameters objectForKey:key] floatValue];
            [parameterSums setObject:[NSNumber numberWithFloat:val] forKey:key];
        }
    }
    
    for(NSString* key in [parameterSums allKeys]) {
        float val = [[parameterSums objectForKey:key] floatValue] / colonyCount;
        [parameterSums setObject:[NSNumber numberWithFloat:val] forKey:key];
    }
    
    _averageColony.tagsCollected = (tagSum / colonyCount) / EVALUATION_COUNT;
    [_averageColony setParameters:parameterSums];
    
    return _averageColony;
}

@end