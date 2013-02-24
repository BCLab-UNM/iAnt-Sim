#import <Foundation/Foundation.h>

#define ANT_STATUS_INACTIVE 0
#define ANT_STATUS_DEPARTING 1
#define ANT_STATUS_SEARCHING 2
#define ANT_STATUS_RETURNING 3

#define ANT_INFORMED_NONE 0
#define ANT_INFORMED_MEMORY 1
#define ANT_INFORMED_PHEROMONE 2

@class Tag;

@interface Ant : NSObject {}

-(void) reset;
-(void) move;

@property (nonatomic) int status; //Indicates what state the ant is in (see #define'd above).
@property (nonatomic) int informed; //Indicates what type of information is influencing the ant's behavior (see #define'd above).

//In general, positions of (-1,-1) denote an empty/unused/uninitialized position.
@property (nonatomic) NSPoint position; //Where the ant currently is.
@property (nonatomic) NSPoint previousPosition; //Where the ant was at the previous tick.
@property (nonatomic) NSPoint target;

@property (nonatomic) float direction; //Direction ant is moving (used in random walk).
@property (nonatomic) int searchTime; //Amount of ticks the ant has been performing a random walk.
@property (nonatomic) int lastMoved; //tick at which the ant last moved (used in random walk).
@property (nonatomic) int lastTurned; //tick at which the ant last turned (used in random walk).

@property (nonatomic) Tag* carrying; //Reference to which Tag the ant is carrying, if any.  nil otherwise.
@property (nonatomic) int neighbors; //Yeah this sucks, but the problem is we have to know what the neighbor count of the seed was AT THE TIME THE SEED WAS COLLECTED.  We can't just calculate it when the ant returns to the nest because the state of the grid could be mutated, leading to undesired behavior.  Oh well.

@end
