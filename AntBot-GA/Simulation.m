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
@synthesize distributionRandom, distributionPowerlaw, distributionClustered, tagCount;
@synthesize averageColony;
@synthesize tickRate;
@synthesize localizationError, tagReadError;
@synthesize delegate, viewDelegate;

/*
 * Starts the simulation run.
 */
-(int) start {
    
    srandomdev();
    colonies = [[NSMutableArray alloc] initWithCapacity:colonyCount];
    for(int i = 0; i < colonyCount; i++){[colonies addObject:[[Colony alloc] init]];}
    int evaluationCount = (viewDelegate != nil) ? 1 : EVALUATION_COUNT;
    
    for(int generation = 0; generation < generationCount; generation++) {
        
        for(Colony* colony in colonies){colony.tagsCollected = 0;}
        
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
        
        NSMutableArray* ants = [[NSMutableArray alloc] initWithCapacity:antCount];
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
                            if(((ant.informed == ANT_INFORMED_PHEROMONE) && (r < colony.pheromoneGiveUpProbability)) ||
                               (!ant.informed && (r < colony.travelGiveUpProbability))) {
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
                            
                            if(randomFloat(1.) < colony.searchGiveUpProbability) {
                                ant.target = NSMakePoint(NEST_X,NEST_Y);
                                ant.status = ANT_STATUS_RETURNING;
                                break;
                            }
                            
                            if(tick - ant.lastTurned >= 3 * SEARCH_DELAY) { //Change direction every 3 iterations.
                                float dTheta;
                                if(ant.searchTime >= 0) {
                                    float informedSearchCorrelation = exponentialDecay(2*M_2PI-colony.uninformedSearchCorrelation, ant.searchTime++, colony.informedSearchCorrelationDecayRate);
                                    dTheta = clip(randomNormal(0, informedSearchCorrelation+colony.uninformedSearchCorrelation),-M_PI,M_PI);
                                }
                                else {
                                    dTheta = clip(randomNormal(0, colony.uninformedSearchCorrelation),-M_PI,M_PI);
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
                                if((randomFloat(1.f) > tagReadError) && (t != 0) && !t.pickedUp) { //Note we use shortcircuiting here.
                                    [t setPickedUp:YES];
                                    ant.carrying = t;
                                    ant.status = ANT_STATUS_RETURNING;
                                    ant.target = NSMakePoint(NEST_X,NEST_Y);
                                    ant.neighbors = 0;
                                    
                                    //Sum up all non-picked-up seeds in the moore neighbor.
                                    for(int dx = -1; dx <= 1; dx++) {
                                        for(int dy = -1; dy <= 1; dy++) {
                                            if((ant.carrying.x+dx>=0 && ant.carrying.x+dx<GRID_WIDTH) && (ant.carrying.y+dy>=0 && ant.carrying.y+dy<GRID_HEIGHT)) {
                                                ant.neighbors += (randomFloat(1.f) > tagReadError) && (tags[ant.carrying.y+dy][ant.carrying.x+dx] != 0) && !(tags[ant.carrying.y+dy][ant.carrying.x+dx].pickedUp);
                                            }
                                        }
                                    }
                                }
                            }
                            
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
                                    
                                    NSPoint perturbedTagLocation = [self perturbPosition:NSMakePoint(ant.carrying.x, ant.carrying.y)];
                                    if(randomFloat(1.) < exponentialCDF(ant.neighbors+1, colony.pheromoneLayingRate)) {
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
                                        pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:colony.pheromoneDecayRate];
                                    }
                                    
                                    //pheromones may now be empty as a result of decay, so we check again here
                                    if(([pheromones count] > 0) && (randomFloat(1.) > exponentialCDF(ant.neighbors+1, colony.pheromoneFollowingRate))) {
                                        ant.target = [self perturbPosition:pheromone];
                                        ant.informed = ANT_INFORMED_PHEROMONE;
                                    }
                                    else if(randomFloat(1.) < exponentialCDF(ant.neighbors+1, colony.siteFidelityRate)) {
                                        ant.target = [self perturbPosition:perturbedTagLocation];
                                        ant.informed = ANT_INFORMED_MEMORY;
                                    }
                                    else {
                                        ant.target = edge(GRID_WIDTH,GRID_HEIGHT);
                                        ant.informed = ANT_INFORMED_NONE;
                                    }
                                    
                                    ant.carrying = nil;
                                }
                                else {
                                    //Calling getPheromone here to force decay before guard check
                                    NSPoint pheromone;
                                    if ([pheromones count] > 0) {
                                        pheromone = [self getPheromone:pheromones atTick:tick withDecayRate:colony.pheromoneDecayRate];
                                    }
                                    
                                    //pheromones may now be empty as a result of decay, so we check again here
                                    if ([pheromones count] > 0) {
                                        ant.target = [self perturbPosition:pheromone];
                                        ant.informed = ANT_INFORMED_PHEROMONE;
                                    }
                                    else {
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
                    if([viewDelegate respondsToSelector:@selector(updateAnts:tags:pheromones:)]) {
                        NSMutableArray* tagsArray = [[NSMutableArray alloc] init];
                        for(int y = 0; y < GRID_HEIGHT; y++) {
                            for(int x = 0; x < GRID_WIDTH; x++) {
                                if(tags[y][x]){[tagsArray addObject:tags[y][x]];}
                            }
                        }
                        [self getPheromone:pheromones atTick:tick withDecayRate:colony.pheromoneDecayRate];
                        [viewDelegate updateAnts:ants tags:tagsArray pheromones:pheromones];
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
    position.x = roundf(clip(randomNormal(position.x, localizationError),0,GRID_WIDTH-1));
    position.y = roundf(clip(randomNormal(position.y, localizationError),0,GRID_HEIGHT-1));
    return position;
}


/*
 * 'Breeds' and mutates colonies.
 * There is a slight tradeoff for readability at the cost of efficiency here,
 * which has to do with the use of (and enumeration over) dictionaries.
 */
-(void) breedColonies {
    @autoreleasepool {
        Colony* children[colonyCount];
        for(int i = 0; i < colonyCount; i++) {
            children[i] = [[Colony alloc] init];
            Colony* child = children[i];
            
            Colony* parent[2];
            for(int j = 0; j < 2; j++) {
                Colony *p1 = [colonies objectAtIndex:randomInt(colonyCount)],
                *p2 = [colonies objectAtIndex:randomInt(colonyCount)];
                while (p1 == p2) {p2 = [colonies objectAtIndex:randomInt(colonyCount)];}
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
        for(int i = 0; i < colonyCount; i++) {
            Colony* colony = [colonies objectAtIndex:i];
            [colony setParameters:[children[i] getParameters]];
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
 * This might work better in Colony.m, as we're passing a lot of Colony related stuff.
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


/*
 * Custom getter for bestColony (lazy evaluation)
 */
-(Colony*) bestColony {
    Colony* _maxColony = [[Colony alloc] init];
    int maxTags = 0;
    
    for(Colony* colony in colonies) {
        if(colony.tagsCollected > maxTags) {
            maxTags = colony.tagsCollected;
            [_maxColony setParameters:[colony getParameters]];
        }
    }
    
    _maxColony.tagsCollected = maxTags / EVALUATION_COUNT;
    
    return _maxColony;
}

@end