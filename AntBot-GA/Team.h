#import <Foundation/Foundation.h>
#import "Archivable.h"
#import "Utilities.h"

@interface Team : NSObject <Archivable> {}

-(id) initRandom;
-(id) initWithFile:(NSString*)filePath;

//Behavior parameters:
@property (nonatomic) float travelGiveUpProbability;
@property (nonatomic) float searchGiveUpProbability;
@property (nonatomic) float decompositionAllocProbability;

//Random walk parameters:
@property (nonatomic) float uninformedSearchCorrelation;
@property (nonatomic) float informedSearchCorrelationDecayRate;
@property (nonatomic) float stepSizeVariation;

//Information parameters:
@property (nonatomic) float pheromoneDecayRate;
@property (nonatomic) float pheromoneLayingRate;
@property (nonatomic) float siteFidelityRate;

//////////////POWER STUFF///////////////
@property (nonatomic) float powerReturnShift;
@property (nonatomic) float powerReturnSigma;
@property (nonatomic) float chargeActiveSigma;
//////////////POWER STUFF///////////////

//Non-evolved variables:
@property (nonatomic) float fitness;
@property (nonatomic) BOOL explorePhase; //Flag denoting whether robot team is currently exploring for tags instead of collecting them

@end