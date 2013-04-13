#import <Foundation/Foundation.h>

@interface Team : NSObject {}

-(id) initRandom;
-(id) initWithSpecificFile:(NSString*)filePath;

-(NSMutableDictionary*) getParameters;
-(void) setParameters:(NSMutableDictionary*)parameters;

//Behavior parameters:
@property (nonatomic) float travelGiveUpProbability;
@property (nonatomic) float searchGiveUpProbability;

//Random walk parameters:
@property (nonatomic) float uninformedSearchCorrelation;
@property (nonatomic) float informedSearchCorrelationDecayRate;
@property (nonatomic) float uninformedStepSizeVariation;
@property (nonatomic) float informedStepSizeVariation;

//Pheromone parameters:
@property (nonatomic) float pheromoneDecayRate;
@property (nonatomic) float pheromoneLayingRate;
@property (nonatomic) float siteFidelityRate;
@property (nonatomic) float pheromoneFollowingRate;

//Non-evolved variables:
@property (nonatomic) float tagsCollected;

@end