#import <Foundation/Foundation.h>

#define ROBOT_STATUS_INACTIVE 0
#define ROBOT_STATUS_DEPARTING 1
#define ROBOT_STATUS_SEARCHING 2
#define ROBOT_STATUS_RETURNING 3

#define ROBOT_INFORMED_NONE 0
#define ROBOT_INFORMED_MEMORY 1
#define ROBOT_INFORMED_PHEROMONE 2

@class Tag;

@interface Robot : NSObject {}

-(void) reset;
-(void) move;

@property (nonatomic) int status; //Indicates what state the robot is in (see #define'd above).
@property (nonatomic) int informed; //Indicates what type of information is influencing the robot's behavior (see #define'd above).

//In general, positions of (-1,-1) denote an empty/unused/uninitialized position.
@property (nonatomic) NSPoint position; //Where the robot currently is.
@property (nonatomic) NSPoint target;

@property (nonatomic) float direction; //Direction robot is moving (used in random walk).
@property (nonatomic) int searchTime; //Amount of ticks the robot has been performing a random walk.
@property (nonatomic) int lastMoved; //tick at which the robot last moved (used in random walk).
@property (nonatomic) int lastTurned; //tick at which the robot last turned (used in random walk).

@property (nonatomic) Tag* carrying; //Reference to which Tag the robot is carrying, if any.  nil otherwise.
@property (nonatomic) int neighbors; //Yeah this sucks, but the problem is we have to know what the neighbor count of the seed was AT THE TIME THE SEED WAS COLLECTED.  We can't just calculate it when the robot returns to the nest because the state of the grid could be mutated, leading to undesired behavior.  Oh well.

@end
