#import <Foundation/Foundation.h>

@interface Colony : NSObject {}

-(id) initRandom;
-(id) initWithSpecificFile:(NSString*)filePath;

-(NSMutableDictionary*) getParameters;
-(void) setParameters:(NSMutableDictionary*)parameters;

//Behavior parameters:
@property (nonatomic) float pheromoneGiveUpProbability;
@property (nonatomic) float travelGiveUpProbability;
@property (nonatomic) float searchGiveUpProbability;

//Random walk parameters:
@property (nonatomic) float uninformedSearchCorrelation;
@property (nonatomic) float informedSearchCorrelationDecayRate;

//Pheromone parameters:
@property (nonatomic) float pheromoneDecayRate;
@property (nonatomic) float pheromoneLayingRate;
@property (nonatomic) float siteFidelityRate;
@property (nonatomic) float pheromoneFollowingRate;

//Non-evolved variables:
@property (nonatomic) float tagsCollected;

@end