#import <Foundation/Foundation.h>

@interface Team : NSObject {}

-(id) initRandom;
-(id) initWithFile:(NSString*)filePath;

-(NSMutableDictionary*) getParameters;
-(void) setParameters:(NSMutableDictionary*)parameters;

//Behavior parameters:
@property (nonatomic) float travelGiveUpProbability;
@property (nonatomic) float searchGiveUpProbability;

//Random walk parameters:
@property (nonatomic) float uninformedSearchCorrelation;
@property (nonatomic) float informedSearchCorrelationDecayRate;
@property (nonatomic) float stepSizeVariation;

//Pheromone parameters:
@property (nonatomic) float pheromoneDecayRate;
@property (nonatomic) float pheromoneLayingRate;
@property (nonatomic) float siteFidelityRate;
@property (nonatomic) float pheromoneFollowingRate;

//Non-evolved variables:
@property (nonatomic) float tagsCollected;
@property (nonatomic) BOOL explorePhase; //Flag denoting whether robot team is currently exploring for tags instead of collecting them

@end