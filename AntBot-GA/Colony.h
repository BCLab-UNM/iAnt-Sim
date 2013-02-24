#import <Foundation/Foundation.h>

@interface Colony : NSObject {}

-(NSMutableDictionary*) getParameters;
-(void) setParameters:(NSMutableDictionary*)parameters;

//Behavior parameters:
@property (nonatomic) float trailDropRate;
@property (nonatomic) float walkDropRate;
@property (nonatomic) float searchGiveupRate;

//Random walk parameters:
@property (nonatomic) float dirDevConst;
@property (nonatomic) float dirDevCoeff;
@property (nonatomic) float dirTimePow;

//Pheromone parameters:
@property (nonatomic) float decayRate;
@property (nonatomic) float densityThreshold;
@property (nonatomic) float densityConstant;
@property (nonatomic) float densityPatchThreshold;
@property (nonatomic) float densityPatchConstant;
@property (nonatomic) float densityInfluenceThreshold;
@property (nonatomic) float densityInfluenceConstant;

//Non-evolved variables:
@property (nonatomic) float tagsCollected;

@end