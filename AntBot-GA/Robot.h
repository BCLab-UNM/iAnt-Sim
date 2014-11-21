#import <Foundation/Foundation.h>
#import "Team.h"

#define ROBOT_STATUS_INACTIVE 0
#define ROBOT_STATUS_DEPARTING 1
#define ROBOT_STATUS_SEARCHING 2
#define ROBOT_STATUS_RETURNING 3
#define ROBOT_STATUS_WAITING 4
#define ROBOT_STATUS_CHARGING  5

#define ROBOT_INFORMED_NONE 0
#define ROBOT_INFORMED_MEMORY 1
#define ROBOT_INFORMED_PHEROMONE 2

@class Tag;

@interface Robot : NSObject {
    int dischargeStartTick;
}

-(void) reset;
-(void) moveWithin:(NSSize)bounds;
-(void) turnWithParameters:(Team*)params;

@property (nonatomic) int status; //Indicates what state the robot is in (see #define'd above).
@property (nonatomic) int informed; //Indicates what type of information is influencing the robot's behavior (see #define'd above).

//In general, positions of (-1,-1) denote an empty/unused/uninitialized position.
@property (nonatomic) NSPoint position; //Where the robot currently is.
@property (nonatomic) NSPoint target; //Where the robot is going.

@property (nonatomic) float direction; //Direction robot is moving (used in random walk).
@property (nonatomic) int searchTime; //Amount of ticks the robot has been performing a random walk.
@property (nonatomic) int lastMoved; //tick at which the robot last moved (used in random walk).
@property (nonatomic) int lastTurned; //tick at which the robot last turned (used in random walk).
@property (nonatomic) int delay; //Number of ticks the robot is penalized to emulate physical robots (used in random walk).

@property (nonatomic) NSMutableArray* discoveredTags; //Tags discovered by robot while searching

//////////////POWER STUFF///////////////
-(void) chargeBattery:(int) tick;
-(void) dischargeBattery:(int) tick;

@property (nonatomic) float batteryLevel;
@property (nonatomic, readonly) int batteryFull;
@property (nonatomic, readonly) int batteryTime;
@property (nonatomic, readonly) float batteryDeadPercent;
@property (nonatomic) BOOL pheremoneOn;
@property (nonatomic) BOOL atNest;
@property (nonatomic) BOOL isDead;
@property (nonatomic) BOOL needsCharging;
//////////////POWER STUFF///////////////

@end
