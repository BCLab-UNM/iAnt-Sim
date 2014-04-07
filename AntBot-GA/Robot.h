#import <Foundation/Foundation.h>
#import "Team.h"

#define ROBOT_STATUS_INACTIVE 0
#define ROBOT_STATUS_DEPARTING 1
#define ROBOT_STATUS_SEARCHING 2
#define ROBOT_STATUS_RETURNING 3
#define ROBOT_STATUS_EXPLORING 4
#define ROBOT_STATUS_WAITING 5
#define ROBOT_STATUS_CHARGING  6

#define ROBOT_INFORMED_NONE 0
#define ROBOT_INFORMED_MEMORY 1
#define ROBOT_INFORMED_PHEROMONE 2
#define ROBOT_INFORMED_DECOMPOSITION 3



@class Tag;

@interface Robot : NSObject {
    int dischargeStartTick;
}

-(void) reset;
-(void) moveWithin:(NSSize)bounds;
-(void) turn:(BOOL)uniformDirection withParameters:(Team*)params;
-(void) broadcastPheromone:(NSPoint)location toRobots:(NSMutableArray*)robots atRange:(int)distance;

@property (nonatomic) int status; //Indicates what state the robot is in (see #define'd above).
@property (nonatomic) int informed; //Indicates what type of information is influencing the robot's behavior (see #define'd above).

//In general, positions of (-1,-1) denote an empty/unused/uninitialized position.
@property (nonatomic) NSPoint position; //Where the robot currently is.
@property (nonatomic) NSPoint target; //Where the robot is going.
@property (nonatomic) NSPoint recruitmentTarget; //Where the robot is recruiting other robots to via local pheromones

@property (nonatomic) float direction; //Direction robot is moving (used in random walk).
@property (nonatomic) int searchTime; //Amount of ticks the robot has been performing a random walk.
@property (nonatomic) int lastMoved; //tick at which the robot last moved (used in random walk).
@property (nonatomic) int lastTurned; //tick at which the robot last turned (used in random walk).
@property (nonatomic) int delay; //Number of ticks the robot is penalized to emulate physical robots (used in random walk).
@property (nonatomic) int stepSize; //Number of grid cells robot moves before turning

@property (nonatomic) NSMutableArray* discoveredTags; //Tags discovered by robot while searching

@property (nonatomic) NSPoint localPheromone; //Buffer to store latest pheromone location received from neighboring robots


//////////////POWER STUFF///////////////
-(void) chargeBattery:(int) tick;
-(void) dischargeBattery:(int) tick;

@property (nonatomic) float batteryLevel;
@property (nonatomic, readonly) float batteryDischargeTime;
@property (nonatomic, readonly) float batteryChargeTime;
@property (nonatomic, readonly) float batteryDeadPercent;
@property (nonatomic) BOOL pheremoneOn;
@property (nonatomic) BOOL atNest;
@property (nonatomic) BOOL isDead;
@property (nonatomic) BOOL needsCharging;
//////////////POWER STUFF///////////////


@end
