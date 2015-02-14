#import <Foundation/Foundation.h>
#import "Archivable.h"
#import "Utilities.h"

@interface Team : NSObject <Archivable> {}

-(id) initRandom;
-(id) initWithFile:(NSString*)filePath;

//Behavior parameters:
@property (nonatomic) float travelGiveUpProbability;
@property (nonatomic) float searchGiveUpProbability;

//Random walk parameters:
@property (nonatomic) float uninformedSearchCorrelation;
@property (nonatomic) float informedSearchCorrelationDecayRate;

//Information parameters:
@property (nonatomic) float pheromoneDecayRate;
@property (nonatomic) float pheromoneLayingRate;
@property (nonatomic) float siteFidelityRate;

//////////////POWER STUFF///////////////
//@property (nonatomic) float powerReturnShift;
//@property (nonatomic) float powerReturnSigma;
//@property (nonatomic) float chargeActiveSigma;
@property (nonatomic) float batteryReturnVal;       // The battery level at which the robot returns to charge
@property (nonatomic) float batteryLeaveVal;        // The battery level at which the robot leaves during charging
@property (nonatomic) float casualties;
//////////////POWER STUFF///////////////

//Non-evolved variables:
@property (nonatomic) float fitness;
@property (nonatomic) int timeToCompleteCollection;

@property (nonatomic) int collisions;

@end